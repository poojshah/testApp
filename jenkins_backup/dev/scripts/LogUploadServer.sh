#!/bin/sh
userdata=https://s3.amazonaws.com/codedeploydemobucketvectorworks/LogUploadSetupScripts/common.sh
mapping=https://s3.amazonaws.com/codedeploydemobucketvectorworks/LogUploadSetupScripts/mapping.json

#Create instance
# TO DO : Add Jenkins aws profile here
# TO DO : Add mapping.json to S3 or repo
instance_id=$(aws ec2 run-instances --image-id ami-b73b63a0 --security-group-ids sg-9fb419e2  --count 1 --instance-type t2.micro --key-name devlogupload --subnet-id subnet-22fd636b --user-data $userdata --block-device-mappings $mapping --query 'Instances[0].InstanceId');
echo $instance_id

instance0=$(echo $instance_id | sed 's/^"\(.*\)"/\1/')
echo $instance0

#creating tags
aws ec2 create-tags --resources $instance0 --tags Key=Name,Value=LogUploadWebServer Key=Owner,Value=pshah Key=Use,Value=UploadLogs Key=apache,Value=24 Key=php,Value=56 Key=fqdn,Value=LogUploadWebServer;

#rebooting instances
aws ec2 reboot-instances --instance-ids $instance0

#Fetch IP Address
ip_address=$(aws ec2 describe-instances --instance-ids $instance0 --output text --query 'Reservations[*].Instances[*].PrivateIpAddress')
echo ip_address=$ip_address

#Wait while the instance comes up
while [ $(echo $(aws ec2 describe-instance-status --instance-ids $instance0 --query 'InstanceStatuses[0].InstanceStatus.Status')| sed 's/^"\(.*\)"/\1/') != "ok" ];
do
   echo "Waiting..."
   sleep 30
done


#Create Mount point

cat ~/scripts/efs_mount.sh | ssh -T -i ~/keys/devlogupload.pem ec2-user@"$ip_address" -o StrictHostKeyChecking=no 

#<< EOF
#mkdir ~/efs-mount-point  
#sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 us-east-1c.fs-53cf131a.efs.us-east-1.amazonaws.com:/ ~/efs-mount-point 
#EOF

#Deploy Code
scp -o StrictHostKeyChecking=no -i ~/keys/devlogupload.pem ~/code/httpd-site.conf ec2-user@"$ip_address":~
scp -o StrictHostKeyChecking=no -i ~/keys/devlogupload.pem ~/code/LogUpload.php ec2-user@"$ip_address":~


