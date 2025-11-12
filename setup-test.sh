#!/bin/bash
set -e
#apt update && apt upgrade -y
apt update
apt-get install -y apache2 openssl

# Enable required Apache modules
a2enmod proxy
a2enmod proxy_connect
a2enmod ssl

# Create directory for SSL certs
mkdir -p /etc/apache2/ssl

# Generate a self-signed SSL certificate
openssl req -x509 -nodes -days 365 \
  -subj "/C=US/ST=None/L=None/O=TEST/CN=test" \
  -newkey rsa:2048 \
  -keyout /etc/apache2/ssl/proxy.key \
  -out /etc/apache2/ssl/proxy.crt

# Create Apache configuration for HTTPS tunnel proxy
cat > /etc/apache2/sites-available/https-tunnel.conf <<EOF
<IfModule mod_ssl.c>
<VirtualHost *:443>
    ServerName test

    SSLEngine on
    SSLCertificateFile /etc/apache2/ssl/proxy.crt
    SSLCertificateKeyFile /etc/apache2/ssl/proxy.key

    # Enable CONNECT method for HTTPS tunneling
    LoadModule proxy_connect_module modules/mod_proxy_connect.so 
	  ProxyRequests On 
	  AllowCONNECT 22 
	  <Proxy *>
		  Require all denied
	  </Proxy>
	 # See the article's comments below, you may have to allow for the 'ServerName' here, instead of 127.0.0.1 
  	<Proxy 127.0.0.1:22> 
  		# Enable proxying to our localhost:22
		Require all granted 
	  </Proxy>
    
</VirtualHost>
</IfModule>
EOF

# Disable default Apache site and enable tunnel config
a2dissite 000-default.conf
a2ensite https-tunnel.conf

# Restart Apache to apply configuration
systemctl restart apache2
systemctl enable apache2

#Allow SSH Forward
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
sed -i 's/^#*AllowTcpForwarding.*/AllowTcpForwarding yes/' /etc/ssh/sshd_config
systemctl restart sshd
