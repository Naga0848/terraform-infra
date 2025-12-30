#!/bin/bash
set -e  # Fail fast on any error

# === Disk expansion (keep if you need it) ===
growpart /dev/nvme0n1 4 || true
lvextend -L +20G /dev/RootVG/rootVol || true
lvextend -L +10G /dev/RootVG/homeVol || true
xfs_growfs / || true
xfs_growfs /home || true

# === Install Docker ===
dnf -y install dnf-plugins-core
dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# === Install AWS CLI v2 ===
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install --update
rm -rf awscliv2.zip aws

# === Install eksctl ===
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp
mv /tmp/eksctl /usr/local/bin/eksctl
chmod +x /usr/local/bin/eksctl
rm eksctl_$PLATFORM.tar.gz

# === Install kubectl ===
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# === Install Helm (direct binary — most reliable) ===
HELM_VERSION=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -LO "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz"
tar -zxvf helm-${HELM_VERSION}-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/bin/helm
chmod +x /usr/local/bin/helm
rm -rf helm-${HELM_VERSION}-linux-amd64.tar.gz linux-amd64

# === Ensure /usr/local/bin is in PATH for ec2-user ===
echo 'export PATH=$PATH:/usr/local/bin' >> /home/ec2-user/.bashrc
echo 'echo "Tools installed: aws, docker, eksctl, kubectl, helm"' >> /home/ec2-user/.bashrc
echo 'echo "Run: newgrp docker  (or reconnect) for docker access without sudo"' >> /home/ec2-user/.bashrc
chown ec2-user:ec2-user /home/ec2-user/.bashrc

# === Deploy RoboShop databases via Helm ===
# Add Bitnami repo
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Create namespace idempotently
kubectl create namespace roboshop --dry-run=client -o yaml | kubectl apply -f -

# MongoDB
helm upgrade --install mongodb bitnami/mongodb \
  --namespace roboshop \
  --set auth.enabled=false \
  --set persistence.size=10Gi \
  --wait

# Redis
helm upgrade --install redis bitnami/redis \
  --namespace roboshop \
  --set auth.enabled=false \
  --set architecture=standalone \
  --set master.persistence.size=10Gi \
  --wait

# MySQL
helm upgrade --install mysql bitnami/mysql \
  --namespace roboshop \
  --set auth.rootPassword=roboshop123 \
  --set auth.database=roboshop \
  --set primary.persistence.size=10Gi \
  --wait

# RabbitMQ
helm upgrade --install rabbitmq bitnami/rabbitmq \
  --namespace roboshop \
  --set auth.username=roboshop \
  --set auth.password=roboshop123 \
  --set persistence.size=10Gi \
  --wait

echo "RoboShop databases (mongodb, redis, mysql, rabbitmq) deployed successfully in namespace 'roboshop'!"