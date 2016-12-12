#!/bin/sh

mkdir ~/efs-mount-point  
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 us-east-1c.fs-53cf131a.efs.us-east-1.amazonaws.com:/ ~/efs-mount-point 
