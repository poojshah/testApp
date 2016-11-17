#!/bin/bash

instance_id=$(AWS_PROFILE=pshah-dev aws ec2 run-instances --image-id ami-b73b63a0 --security-group-ids sg-9b47fde6 --count 1 --instance-type t2.micro --key-name devlogupload --subnet-id subnet-22fd636b --user-data ~/Downloads/common.sh --block-device-mappings file://mapping.json --query 'Instances[0].InstanceId');

echo $instance_id

AWS_PROFILE=pshah-dev aws ec2 create-tags --resources $instance_id --tags Key=Name,Value=LogUploadWebServer Key=Owner,Value=pshah Key=Use,Value=UploadLogs Key=apache,Value=24 Key=php,Value=56; 

#instance_id=i-e4678a7c

