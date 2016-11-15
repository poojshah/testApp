#!/bin/bash

#Install MYSQL Database
yum localinstall https://dev.mysql.com/get/mysql57-community-release-el7-8.noarch.rpm
yum install mysql-community-server
systemctl start mysqld.service
systemctl status mysqld.service

yum groupinstall -y "MySQL Database" "PHP Support"
yum install -y php-mysql
