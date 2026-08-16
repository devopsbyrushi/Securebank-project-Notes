#!/bin/bash
# Destination servers

#!/bin/bash

set -e

apt-get update -y
apt-get install -y openssh-server

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

mkdir -p /home/ansible/.ssh
touch /home/ansible/.ssh/authorized_keys

chmod 700 /home/ansible/.ssh
chmod 600 /home/ansible/.ssh/authorized_keys

chown -R ansible:ansible /home/ansible/.ssh

systemctl enable ssh
systemctl restart ssh
