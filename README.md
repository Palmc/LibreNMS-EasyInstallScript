# [LibreNMS](https://librenms.org)-EasyInstallScript

Scripts to make life easier

InstallLibreNMS.bash is a script that automates the installation of LibreNMS with Apache, tested on Ubuntu 16.04 and Debian 9
LibreNMSNginx.bash automates the installation of LibreNMS with NGINX, tested on Ubuntu 16.04 and Debian 9

**Install instructions**
```
wget -O InstallLibreNMS.sh https://raw.github.com/Palmc/LibreNMS-EasyInstallScript/master/InstallLibreNMS.bash
```
Run
```
chmod +x InstallLibreNMS.sh
./InstallLibreNMS.sh
```
**NOTE**

The default timezone is Etc/UTC, you must change the timezone to adjust it to your location, the list of supported timezones is here: http://php.net/manual/en/timezones.php

All credits for the LibreNMS project https://www.librenms.org/
