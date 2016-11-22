#!/bin/bash

#Show every line before execution
#set -x

#Stop and show if  error occurs
#set -e

userdata=http://mis.nemetschek.net/EC2/SetupScripts/common.sh

#Create instance
# TO DO : Add Jenkins aws profile here
# TO DO : Add mapping.json to S3 or repo
instance_id=$(AWS_PROFILE=pshah-deployment aws ec2 run-instances --image-id ami-b73b63a0 --security-group-ids sg-653a4b00 sg-4a8fdc2f --count 1 --instance-type t2.micro --key-name generic_kp --subnet-id subnet-4ceade64 --user-data $userdata --block-device-mappings file://~/mapping.json --query 'Instances[0].InstanceId');

echo $instance_id

instance0=$(echo $instance_id | sed 's/^"\(.*\)"/\1/')

#creating tags
AWS_PROFILE=pshah-deployment aws ec2 create-tags --resources $instance0 --tags Key=Name,Value=LogUploadWebServer Key=Owner,Value=pshah Key=Use,Value=UploadLogs Key=apache,Value=24 Key=php,Value=56 Key=fqdn,Value=LogUploadWebServer;

#rebooting instances
AWS_PROFILE=pshah-deployment aws ec2 reboot-instances --instance-ids $instance0
