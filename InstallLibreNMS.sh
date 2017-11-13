#!/bin/bash

#Cambiamos hostname del servidor
echo "############################################"
echo "######EMPEZANDO CON LA CONFIGURACIÓN########"
echo "############################################"
echo " "
echo " "
echo "¿Quieres cambiar el hostname al servidor? y/n"
read -e respuesta
if [ "$respuesta" == y ] ; then
	echo "Introduce el nuevo hostname"
	read -e newhostname
	hostnamectl set-hostname $newhostname
fi
#Seteamos la contraseña que tendrá la base de datos
echo " "
echo " "
echo "Introduce la contraseña que tendrá la base de datos de LibreNMS, recuerda que no se ve al escribir"
read -s db_pass
echo "Vuelve a introducir la contraseña"
read -s db_pass2

while [ "$db_pass" != "$db_pass2" ] ; do
	echo "Las contraseñas no coinciden, vuelve a intentarlo"
	read -s db_pass2
done

echo " "
echo " "
echo "Introduce comunidad de SNMP"
read -e comunidad

echo "mariadb-server mariadb-server/root_password password $db_pass2" | sudo debconf-set-selections
echo "mariadb-server mariadb-server/root_password_again password $db_pass2" | sudo debconf-set-selections

#Instalamos prerequisitos
apt update && apt install -y apache2 composer fping git graphviz imagemagick libapache2-mod-php7.0 mariadb-client mariadb-server mtr-tiny nmap php7.0-cli php7.0-curl php7.0-gd php7.0-json php7.0-mcrypt php7.0-mysql php7.0-snmp php7.0-xml php7.0-zip python-memcache python-mysqldb rrdtool snmp snmpd whois

#Creamos el usuario librenms y o añadimos al grupo www-data
useradd librenms -d /opt/librenms -M -r
usermod -a -G librenms www-data

#Nos bajamos el proyecto librenms de su repositorio de git
cd /opt
git clone https://github.com/librenms/librenms.git librenms


###Servidor de bases de datos

#Configuramos mysql
systemctl restart mysql
#mysql -uroot -p
#CREATE DATABASE librenms CHARACTER SET utf8 COLLATE utf8_unicode_ci;
#CREATE USER 'librenms'@'localhost' IDENTIFIED BY 'password';
#GRANT ALL PRIVILEGES ON librenms.* TO 'librenms'@'localhost';
#FLUSH PRIVILEGES;
#exit

setupdb="CREATE DATABASE librenms CHARACTER SET utf8 COLLATE utf8_unicode_ci;CREATE USER 'librenms'@'localhost' IDENTIFIED BY '$db_pass';GRANT ALL PRIVILEGES ON librenms.* TO 'librenms'@'localhost';FLUSH PRIVILEGES;"
mysql -u root -p$db_pass -e "$setupdb"

#Añadimos configuración al archivo /etc/mysql/mariadb.conf.d/50-server.cnf

sed -i '/\[mysqld]/a \
\
## Añadido para la configuración de LibreNMS \
innodb_file_per_table=1 \
sql-mode="" \
lower_case_table_names=0 \
## \
' /etc/mysql/mariadb.conf.d/50-server.cnf

#Reiniciar servicio mysql
systemctl restart mysql

###Servidor Web

#Añadir franja horaria Europe/Madrid

#vi /etc/php/7.0/apache2/php.ini
#vi /etc/php/7.0/cli/php.ini

sed -i 's|;date.timezone =|date.timezone = Europe/Madrid|g' /etc/php/7.0/apache2/php.ini

sed -i 's|;date.timezone =|date.timezone = Europe/Madrid|g' /etc/php/7.0/cli/php.ini

#Habilitar módulos de php en apache
a2enmod php7.0
a2dismod mpm_event
a2enmod mpm_prefork
phpenmod mcrypt

#Configurar apache

cat > /etc/apache2/sites-available/librenms.conf <<EOF
<VirtualHost *:80>
  DocumentRoot /opt/librenms/html/
  ServerName  $HOSTNAME.local

  AllowEncodedSlashes NoDecode
  <Directory "/opt/librenms/html/">
    Require all granted
    AllowOverride All
    Options FollowSymLinks MultiViews
  </Directory>
</VirtualHost>
EOF

#Terminamos de perfilar la configuración de apache
a2dissite 000-default
a2ensite librenms.conf
a2enmod rewrite
systemctl restart apache2

#Configuramos snmp
cp /opt/librenms/snmpd.conf.example /etc/snmp/snmpd.conf


#vi /etc/snmp/snmpd.conf #Cambiar dentro de este archivo RANDOMSTRINGGOESHERE por el nombre de nuestra comunidad de snmp
sed -i "s|RANDOMSTRINGGOESHERE|$comunidad|g" /etc/snmp/snmpd.conf

curl -o /usr/bin/distro https://raw.githubusercontent.com/librenms/librenms-agent/master/snmp/distro
chmod +x /usr/bin/distro
systemctl restart snmpd

#Tareas cron
cp /opt/librenms/librenms.nonroot.cron /etc/cron.d/librenms

#Logrotate logs
cp /opt/librenms/misc/librenms.logrotate /etc/logrotate.d/librenms

#Permisos
chown -R librenms:librenms /opt/librenms
setfacl -d -m g::rwx /opt/librenms/rrd /opt/librenms/logs
setfacl -R -m g::rwx /opt/librenms/rrd /opt/librenms/logs

#Y YA ESTÁ ESTA PARTE
ip=$(hostname -I|cut -f1 -d ' ')
sleep 1
echo "#################TERMINADO###########################"
echo " "
echo "Ahora puedes seguir con la configuración aquí: http://$ip/install.php"
echo "Recuerda que estas son tus credenciales: "
echo " "
echo " DB User: librenms "
echo " DB Password: $db_pass  "
