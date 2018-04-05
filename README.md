# [LibreNMS](https://librenms.org)-EasyInstallScript

Scripts to make life easier

InstallLibreNMS.bash is a script that automates the installation of LibreNMS with Apache, tested on Ubuntu 16.04 and Debian 9
LibreNMSNginx.bash automates the installation of LibreNMS with NGINX, tested on Ubuntu 16.04 and Debian 9

**Install instructions**
```
wget -O LibreNMSNginx.bash https://raw.github.com/Palmc/LibreNMS-EasyInstallScript/master/LibreNMSNginx.bash
```
Run
```
chmod +x LibreNMSNginx.bash
./LibreNMSNginx.bash
```
**NOTE**

The default timezone in **/etc/php/7.0/fpm/php.ini** and **/etc/php/7.0/cli/php.ini** is Etc/UTC, you must change the timezone to adjust it to your location, the list of supported timezones is here: http://php.net/manual/en/timezones.php

All credits for the LibreNMS project https://www.librenms.org/
