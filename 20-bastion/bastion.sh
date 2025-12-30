#!/bin/bash

set -e  # Exit on any error

# Expand root and home volumes (as in original)
growpart /dev/nvme0n1 4
lvextend -L +20G /dev/RootVG/rootVol
lvextend -L +10G /dev/RootVG/homeVol
xfs_growfs /
xfs_growfs /home

terraform import aws_iam_role.bastion_role TerraformAdmin

# Install Docker
dnf -y install dnf-plugins-core
dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user


# Run everything as root (user_data already does this)

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install --update
rm -rf awscliv2.zip aws

# Install eksctl
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin/eksctl
rm eksctl_$PLATFORM.tar.gz

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Install Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
sudo HELM_INSTALL_DIR=/usr/local/bin ./get_helm.sh   # Important: install to /usr/local/bin
rm get_helm.sh

# Ensure /usr/local/bin is in PATH for ec2-user
echo 'export PATH=$PATH:/usr/local/bin' >> /home/ec2-user/.bashrc

# Optional: Add a welcome message so you know it's ready
echo "kubectl, helm, eksctl, and aws CLI installed!" >> /home/ec2-user/.bashrc
echo "Run: source ~/.bashrc  or reconnect to refresh commands" >> /home/ec2-user/.motd

# Fix ownership
chown ec2-user:ec2-user /home/ec2-user/.bashrc



# Add Bitnami Helm repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Create namespace if not exists
kubectl create namespace roboshop --dry-run=client -o yaml | kubectl apply -f -

# Deploy MongoDB
helm upgrade --install mongodb bitnami/mongodb \
  --namespace roboshop \
  --set auth.enabled=false \
  --set persistence.size=10Gi \
  --wait

# Deploy Redis
helm upgrade --install redis bitnami/redis \
  --namespace roboshop \
  --set auth.enabled=false \
  --set architecture=standalone \
  --set master.persistence.size=10Gi \
  --wait

# Deploy MySQL
helm upgrade --install mysql bitnami/mysql \
  --namespace roboshop \
  --set auth.rootPassword=roboshop123 \
  --set auth.database=roboshop \
  --set primary.persistence.size=10Gi \
  --wait

# Deploy RabbitMQ
helm upgrade --install rabbitmq bitnami/rabbitmq \
  --namespace roboshop \
  --set auth.username=roboshop \
  --set auth.password=roboshop123 \
  --set persistence.size=10Gi \
  --wait

echo "All databases deployed successfully in roboshop namespace!"

# Optional: kubectx/kubens for context switching
git clone https://github.com/ahmetb/kubectx /opt/kubectx
ln -s /opt/kubectx/kubens /usr/local/bin/kubens

