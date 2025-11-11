#!/bin/bash
set -e
#apt update && apt upgrade -y
apt update
apt -y install apache2
systemctl start apache2
systemctl enable apache2
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
sed -i 's/^#*AllowTcpForwarding.*/AllowTcpForwarding yes/' /etc/ssh/sshd_config
systemctl restart sshd
