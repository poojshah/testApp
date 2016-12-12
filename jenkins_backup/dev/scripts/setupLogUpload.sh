#!/bin/sh
#echo "LoadModule speling_module     modules/mod_speling.so" >> /etc/httpd/conf/httpd.conf
sudo sed --in-place 's/#\(LoadModule speling_module\)/\1/' /etc/httpd/conf.modules.d/00-optional.conf
sudo service httpd restart

sudo mkdir -p /var/www/installer.nemetschek.net/Release
sudo mkdir -p /var/www/installer.nemetschek.net/logfiles
sudo cp ~/LogUpload.php /var/www/installer.nemetschek.net/Release/
sudo touch /var/www/installer.nemetschek.net/logfiles/log_upload_debug.txt
sudo touch /var/www/installer.nemetschek.net/logfiles/log_upload_log.txt
sudo chmod -R 777 /var/www/installer.nemetschek.net/

sudo cp ~/httpd-site.conf /etc/httpd/sites/1-installer.nemetschek.net.conf 
sudo chmod 777 /etc/httpd/sites/1-installer.nemetschek.net.conf 
