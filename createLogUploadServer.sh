#!/bin/bash

#Show every line before execution
#set -x

#Stop and show if  error occurs
#set -e

#Create instance
instance_id=$(AWS_PROFILE=pshah-dev aws ec2 run-instances --image-id ami-b73b63a0 --security-group-ids sg-9b47fde6 --count 1 --instance-type t2.micro --key-name devlogupload --subnet-id subnet-22fd636b --user-data file://LogUploadSetupScripts/common.sh --block-device-mappings file://LogUploadSetupScripts/mapping.json --query 'Instances[0].InstanceId');

echo $instance_id

instance0=$(echo $instance_id | sed 's/^"\(.*\)"/\1/')

#creating tags
AWS_PROFILE=pshah-dev aws ec2 create-tags --resources $instance0 --tags Key=Name,Value=LogUploadWebServer Key=Owner,Value=pshah Key=Use,Value=UploadLogs Key=apache,Value=24 Key=php,Value=56; 

#rebooting instances
AWS_PROFILE=pshah-dev aws ec2 reboot-instances --instance-ids $instance0
