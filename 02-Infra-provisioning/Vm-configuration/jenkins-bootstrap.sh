#!/bin/bash
#ANSIBLE JENKINS

set -e

apt-get update -y
apt-get install -y software-properties-common openssh-server

add-apt-repository --yes --update ppa:ansible/ansible

apt-get update -y
apt-get install -y ansible

# Create ansible user
if ! id ansible >/dev/null 2>&1; then
    useradd -m -s /bin/bash ansible
fi

# Set password
echo "ansible:ansible" | chpasswd

# Passwordless sudo
echo "ansible ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ansible
chmod 440 /etc/sudoers.d/ansible

# SSH Configuration
sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#*KbdInteractiveAuthentication.*/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config

# Generate SSH Keys
sudo -u ansible mkdir -p /home/ansible/.ssh

if [ ! -f /home/ansible/.ssh/id_rsa ]; then
    sudo -u ansible ssh-keygen -t rsa -b 4096 -N "" \
    -f /home/ansible/.ssh/id_rsa
fi

chmod 700 /home/ansible/.ssh
chown -R ansible:ansible /home/ansible/.ssh

# Ansible Inventory
cat > /etc/ansible/hosts <<EOF
[docker]
REPLACE_DOCKER_IP ansible_user=ansible

[monitoring]
REPLACE_MONITORING_IP ansible_user=ansible

[sonarqube]
REPLACE_SONARQUBE_IP ansible_user=ansible

[jenkins]
localhost ansible_connection=local
EOF

systemctl enable ssh
systemctl restart ssh
