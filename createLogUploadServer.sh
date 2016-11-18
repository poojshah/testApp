#!/bin/bash

#set -x
#set -e

userdata=https://s3.amazonaws.com/codedeploydemobucketvectorworks/LogUploadSetupScripts/common.sh
mapping=https://s3.amazonaws.com/codedeploydemobucketvectorworks/LogUploadSetupScripts/mapping.json

#Create instance
instance_id=$(AWS_PROFILE=pshah-dev aws ec2 run-instances --image-id ami-b73b63a0 --security-group-ids sg-9b47fde6 --count 1 --instance-type t2.micro --key-name devlogupload --subnet-id subnet-22fd636b --user-data $userdata --block-device-mappings $mapping --query 'Instances[0].InstanceId');

echo $instance_id

instance0=$(echo $instance_id | sed 's/^"\(.*\)"/\1/')

#creating tags
AWS_PROFILE=pshah-dev aws ec2 create-tags --resources $instance0 --tags Key=Name,Value=LogUploadWebServer Key=Owner,Value=pshah Key=Use,Value=UploadLogs Key=apache,Value=24 Key=php,Value=56 Key=fqdn,Value=LogUploadWebServer; 

#rebooting instances
AWS_PROFILE=pshah-dev aws ec2 reboot-instances --instance-ids $instance0
