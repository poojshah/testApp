#!/bin/bash
#
#	web_server_basic.sh {ApacheVersion} {PHPVersion}
#       ApacheVersion   Use: 22 or 24
#       PHPVersion      Use: 56, 55, or 54
#
# This script configures a machine as a generic Apache 2.2 web server. It installs Apache and
# PHP with APC support.
#
# Output is sent to 2 files (/var/log/syslog & /var/log/user-data.log) and the console.
#

#	This script is stored in Perforce:
#		$File: //depot/Operations/IT/Scripts/ActiveDirectory/EmployeeSync.ps1 $
#		$Revision: #9 $


# Redirect all output.
#exec > >(tee --append /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1


nApacheVersion=0
nPhpVersion=0


# Set to 22 for Apache 2.2 and PHP 5.3. Set to 24 for Apache 2.4 and PHP 5.4.
# First check for Apache version as first parameter to this script; then check for the nApacheVersion variable; then defaults to 22.
if ! [ -z ${1} ] ; then nApacheVersion=${1} ; fi
if ! [ -z ${2} ] ; then nPhpVersion=${2} ; fi
    

# Install everything.
echo -e "\n-----------------------------------------------------------------------------------------------------"
if [ $nApacheVersion -eq 0 ] ; then
  echo "Not installing Apache"
else
  echo -n "Installing packages for "

  if [ $nApacheVersion -ge 24 ] ; then
    # Apache 2.4
    echo "Apache 2.4"
    yum -y install httpd24
  else
    # Apache 2.2
    echo "default version of Apache"
    yum -y install httpd
  fi
fi

echo -e "\n-----------------------------------------------------------------------------------------------------"
if [ $nPhpVersion -eq 0 ] ; then
  echo "Not installing PHP"
else
  let nMajor=nPhpVersion/10
  let nMinor=nPhpVersion%10
  echo "Installing packages for PHP ${nMajor}.${nMinor}"
  sPhpModules="php${nPhpVersion} php${nPhpVersion}-gd php${nPhpVersion}-mbstring php${nPhpVersion}-opcache"
  if [ $nPhpVersion -ge 56 ] ; then
    sPhpModules="$sPhpModules php${nPhpVersion}-mysqlnd"
  else
    sPhpModules="$sPhpModules php${nPhpVersion}-mysql"
  fi
  yum -y install $sPhpModules
fi

if [ $nApacheVersion -gt 0 ] ; then
# Configure Apache
echo -e "\n-----------------------------------------------------------------------------------------------------"
echo "Configuring Apache"

cd /etc/httpd
mkdir sites                                 # Create folder where we store our site conf files.
cd conf
/bin/cp -f httpd.conf httpd.conf.ORIGINAL   # Copy original conf file as backup.

# Edit the default conf file to our specs.

# Apache all versions
sed --in-place 's/LogFormat "%h/LogFormat "%{X-Forwarded-For}i/g' httpd.conf 
sed --in-place 's/Options FollowSymLinks/Options SymLinksIfOwnerMatch/' httpd.conf
sed --in-place 's/Options Indexes FollowSymLinks/Options FollowSymLinks/g' httpd.conf
sed --in-place 's/Options Indexes/Options -Indexes/g' httpd.conf
sed --in-place "s/#ServerName www.example.com/ServerName $(hostname)/" httpd.conf

if [ $nApacheVersion -ge 24 ] ; then
# Apache 2.4 and later

# Turn on spell checking module by removing comment character.
sed --in-place 's/#\(LoadModule speling_module\)/\1/' ../conf.modules.d/00-base.conf

echo '
# Turn on Keep-Alive extension
KeepAlive On

# prefork MPM
StartServers              8
MinSpareServers           5
MaxSpareServers          20
ServerLimit             256
MaxRequestWorkers       256
MaxConnectionsPerChild 2000

# This should be the first virtual host, so it is the default if no other one matches.
<VirtualHost *:80>
    ServerName bogus.bogus
    DocumentRoot /var/www/html
</VirtualHost>

# Status pages
ExtendedStatus On
<Location /server-status>
    SetHandler server-status
    Require all denied
    Require ip 192.168.0.0/21 172.31.33.60 172.30.252.187
</Location>
<Location /server-info>
    SetHandler server-info
    Require all denied
    Require ip 192.168.0.0/21 172.31.33.60 172.30.252.187
</Location>

# Include our site definitions.
IncludeOptional sites/*.conf
' >> httpd.conf

else
# Apache < v2.4

sed --in-place 's/MaxRequestsPerChild  4000/MaxRequestsPerChild  2000/' httpd.conf
sed --in-place 's/#NameVirtualHost/NameVirtualHost/' httpd.conf
sed --in-place 's/KeepAlive Off/KeepAlive On/' httpd.conf
sed --in-place 's/#ExtendedStatus On/ExtendedStatus On/' httpd.conf
sed --in-place '/Location \/server-status/ i\
<Location /server-status>\
    SetHandler server-status\
    Order deny,allow\
    Deny from all\
    Allow from 192.168.0.0/21\
    Allow from 172.31.33.60\
    Allow from 172.30.252.187\
<\/Location>' httpd.conf
sed --in-place '/Location \/server-info/ i\
<Location /server-info>\
    SetHandler server-info\
    Order deny,allow\
    Deny from all\
    Allow from 192.168.0.0/21\
    Allow from 172.31.33.60\
    Allow from 172.30.252.187\
</Location>' httpd.conf
sed --in-place '/\/VirtualHost/ a\
\
# This should be the first virtual host, so it is the default if no other one matches.\
<VirtualHost *:80>\
    ServerName bogus.bogus\
    DocumentRoot /var/www/html\
</VirtualHost>' httpd.conf

echo -e '\n# Include our site definitions.\nInclude sites/*.conf\n' >> httpd.conf

fi

# Add ec2-user to apache group.
usermod -a -G apache ec2-user

echo "Done."

echo -e "\n-----------------------------------------------------------------------------------------------------"
echo "Setup APC"
/bin/cp -f /usr/share/doc/php*-pecl-apc-*/apc.php /var/www/html
sed --in-place "s/'ADMIN_PASSWORD','password'/'ADMIN_PASSWORD','fAll2splash'/" /var/www/html/apc.php

# Start Apache
echo -e "\n-----------------------------------------------------------------------------------------------------"
echo "Starting Apache"
chkconfig httpd on
service httpd start

fi