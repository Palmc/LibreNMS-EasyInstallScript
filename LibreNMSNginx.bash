#!/bin/bash
#Script to install LibreNMS with NGINX
#Supported OS: Ubuntu 16.04, Debian 9
#
#Based on https://docs.librenms.org/#Installation/Installation-Ubuntu-1604-Nginx/
# Author Pablo De la Morena

if [ "$(id -u)" != '0' ]; then
	echo 'Error: this script can only be executed by root'
	exit 1
fi
echo "############################################"
echo "######  BEGIN CONFIGURATION FILE    ########"
echo "############################################"
echo " "
echo " "
echo "¿Change hostname? y/n"
read -e respuesta
if [ "$respuesta" == y ] ; then
	echo "New hostname"
	read -e newhostname
	hostnamectl set-hostname $newhostname
fi

echo " "
echo " "
echo "Enter the password that the LibreNMS database will have, remember that it is not seen when writing"
read -s db_pass
echo "Type password again"
read -s db_pass2

while [ "$db_pass" != "$db_pass2" ] ; do
	echo "The passwords dont match, try again"
	read -s db_pass2
done

echo " "
echo " "
echo "SNMP community name"
read -e comunidad
#
#echo "mariadb-server mariadb-server/root_password password $db_pass2" | sudo debconf-set-selections
#echo "mariadb-server mariadb-server/root_password_again password $db_pass2" | sudo debconf-set-selections

apt update && apt install -y composer fping git graphviz imagemagick mariadb-client mariadb-server mtr-tiny nginx-full nmap php7.0-cli php7.0-curl php7.0-fpm php7.0-gd php7.0-mcrypt php7.0-mysql php7.0-snmp php7.0-xml php7.0-zip python-memcache python-mysqldb rrdtool snmp snmpd whois

useradd librenms -d /opt/librenms -M -r
usermod -a -G librenms www-data

cd /opt
git clone https://github.com/librenms/librenms.git librenms

systemctl restart mysql

setupdb="CREATE DATABASE librenms CHARACTER SET utf8 COLLATE utf8_unicode_ci;CREATE USER 'librenms'@'localhost' IDENTIFIED BY '$db_pass2';GRANT ALL PRIVILEGES ON librenms.* TO 'librenms'@'localhost';FLUSH PRIVILEGES;"
mysql -uroot -p$db_pass2 -e"$setupdb"

sed -i '/\[mysqld]/a \
\
## Added for the LibreNMS configuration \
innodb_file_per_table=1 \
sql-mode="" \
lower_case_table_names=0 \
## \
' /etc/mysql/mariadb.conf.d/50-server.cnf

systemctl restart mysql

sed -i 's|;date.timezone =|date.timezone = Etc/UTC|g' /etc/php/7.0/fpm/php.ini
sed -i 's|;date.timezone =|date.timezone = Etc/UTC|g' /etc/php/7.0/cli/php.ini

phpenmod mcrypt
systemctl restart php7.0-fpm

echo 'server {
 listen      80;
 server_name librenms.example.com;
 root        /opt/librenms/html;
 index       index.php;

 charset utf-8;
 gzip on;
 gzip_types text/css application/javascript text/javascript application/x-javascript image/svg+xml text/plain text/xsd text/xsl text/xml image/x-icon;
 location / {
  try_files $uri $uri/ /index.php?$query_string;
 }
 location /api/v0 {
  try_files $uri $uri/ /api_v0.php?$query_string;
 }
 location ~ \.php {
  include fastcgi.conf;
  fastcgi_split_path_info ^(.+\.php)(/.+)$;
  fastcgi_pass unix:/var/run/php/php7.0-fpm.sock;
 }
 location ~ /\.ht {
  deny all;
 }
}' > /etc/nginx/conf.d/librenms.conf

rm /etc/nginx/sites-enabled/default
systemctl restart nginx

cp /opt/librenms/snmpd.conf.example /etc/snmp/snmpd.conf

sed -i "s|RANDOMSTRINGGOESHERE|$comunidad|g" /etc/snmp/snmpd.conf

curl -o /usr/bin/distro https://raw.githubusercontent.com/librenms/librenms-agent/master/snmp/distro
chmod +x /usr/bin/distro
systemctl restart snmpd

cp /opt/librenms/librenms.nonroot.cron /etc/cron.d/librenms

cp /opt/librenms/misc/librenms.logrotate /etc/logrotate.d/librenms

chown -R librenms:librenms /opt/librenms
setfacl -d -m g::rwx /opt/librenms/rrd /opt/librenms/logs
setfacl -R -m g::rwx /opt/librenms/rrd /opt/librenms/logs

ip=$(hostname -I|cut -f1 -d ' ')
sleep 1
echo "############################################"
echo "###############  FINISHED  #################"
echo "############################################"
echo " "
echo "Now you must continue here: http://$ip/install.php"
echo "Remenber that these are your credentials: "
echo " "
echo " DB User: librenms "
echo " DB Password: $db_pass  "
echo " "
echo " Remember to change in the file config.php $config['base_url'] = "http://librenms.company.com"; by $config['base_url']        = "/";"
