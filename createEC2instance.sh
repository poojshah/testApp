#!/bin/bash
instance_id=$(AWS_PROFILE=pshah-dev aws ec2 run-instances --image-id ami-d62870c1 --security-group-ids sg-2278a25f --count 1 --instance-type t2.micro --key-name wordpresscli-key --subnet-id subnet-22fd636b --query 'Instances[0].InstanceId')

echo $instance_id
