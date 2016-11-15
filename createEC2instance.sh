#!/bin/bash

echo $1

#Wordpress Instance
if [ "$1" == "wordpress" ];then
echo "wordpress"
instance_id=$(AWS_PROFILE=pshah-dev aws ec2 run-instances --image-id ami-d62870c1 --security-group-ids sg-2278a25f --count 1 --instance-type t2.micro --key-name wordpresscli-key --subnet-id subnet-22fd636b --query 'Instances[0].InstanceId');
fi

#Ubuntu 16.04
if [ "$1" == "ubuntu" ];then
echo "ubuntu"
instance_id=$(AWS_PROFILE=pshah-dev aws ec2 run-instances --image-id ami-40d28157 --security-group-ids sg-2278a25f --count 1 --instance-type t2.micro --key-name wordpresscli-key --subnet-id subnet-22fd636b --iam-instance-profile Name=CodeDeployDemo-EC2-Instance-Profile --query 'Instances[0].InstanceId')
#Adding a tag to the ubuntu image
AWS_PROFILE=pshah-dev aws ec2 create-tags --resources $instance_id --tags Key=Name,Value=codeDeployGit;
fi

#RHEL 7.3
if [ "$1" == "redhat" ];then
echo "redhat"
instance_id=$(AWS_PROFILE=pshah-dev aws ec2 run-instances --image-id ami-b63769a1 --security-group-ids sg-2278a25f --count 1 --instance-type t2.micro --key-name wordpresscli-key --subnet-id subnet-22fd636b --iam-instance-profile Name=CodeDeployDemo-EC2-Instance-Profile --query 'Instances[0].InstanceId')
#Adding a tag to the ubuntu image
AWS_PROFILE=pshah-dev aws ec2 create-tags --resources $instance_id --tags Key=Name,Value=codeDeployGit;
fi


echo $instance_id
