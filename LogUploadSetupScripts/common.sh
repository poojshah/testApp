#!/bin/bash
#
#	common.sh
#
# This script should be run on all Amazon Linux instances. It does basic setup stuff that
# should be done on all instances and can optionally setup Apache and PHP. This is what it does:
#
#   1. Installs all updates.
#   2. Sets the hostname by querying the "fqdn" AWS tag (which you must set before launch).
#   3. Sets the system timezone to Eastern.
#   4. Installs and configures SNMP for remote monitoring.
#   5. Configures Sendmail to route all e-mail to our smart host (mx.vectorworks.net).
#   6. Configures system to automatically install security updates. (Will not reboot even if update requires it.)
#   7. Optionally install Apache and PHP via sub-script. Uses "apache" and "php" AWS tags (which you must set before launch).
#
# IMPORTANT NOTES:
#   - YOU NEED TO REBOOT when this script is done.
#   - Your instance must have an AWS tag named "fqdn" and it must be set to the instance's FQDN.
#   - If you want this script to also install Apache and PHP, then you must have an AWS tag named "apache" and "php"
#     (see http://infosystems.nemetschek.net/articles.php?action=view&article_id=467).
#
# Output is sent to the console and 2 files (/var/log/syslog & /var/log/user-data.log).
#

#	This script is stored in Perforce:
#		$File: //depot/Operations/IT/Scripts/ActiveDirectory/EmployeeSync.ps1 $
#		$Revision: #9 $


# Redirect all output.
exec > >(tee --append /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# This is the URL to the folder that contains all the data files needed by the script.
#sScriptURL=http://mis.nemetschek.net/EC2/SetupScripts
sScriptURL=.
sDataURL=${sScriptURL}/data

# Locations of configuration files.
sConfSNMPD=/etc/snmp/snmpd.conf
sConfYum=/etc/yum/yum-cron.conf
sConfSSHD=/etc/ssh/sshd_config

# Install all updates
echo "-----------------------------------------------------------------------------------------------------"
echo "Installing all updates"
yum -y upgrade

# Install the packages we use. They will be configured later in the scipt.
echo -e "\n-----------------------------------------------------------------------------------------------------"
echo "Installing extra packages"
yum -y install mailx net-snmp yum-cron htop iotop

# Initialize some script variables.
# Must use full path to AWS tools becuase path is not correct when this script runs.
echo -e "\n-----------------------------------------------------------------------------------------------------"
echo "Setting local variables"

# EC2_HOME and JAVA_HOME are probably not yet set and we need them to be.
[ -z "$EC2_HOME" ] && EC2_HOME="/opt/aws/apitools/ec2" && export EC2_HOME
[ -z "$JAVA_HOME" ] && JAVA_HOME="/usr/lib/jvm/jre" && export JAVA_HOME

# Location of the file with the AWS credentials that we need.
sCredentialsFileRemote=${sDataURL}/credentials
sCredentialsFileLocal=~/credentials.txt

# Get AWS credentials from file.
wget --no-verbose --output-document ${sCredentialsFileLocal} ${sCredentialsFileRemote}
awsAccessKey=$(head -n 1 ${sCredentialsFileLocal} | cut -f1)
awsSecretKey=$(head -n 1 ${sCredentialsFileLocal} | cut -f2)
rm -f ${sCredentialsFileLocal}
echo "Using access key ${awsAccessKey}"

# Get instance ID
instanceID=$(/opt/aws/bin/ec2-metadata --instance-id | cut -d ' ' -f2)
echo "This is instance ${instanceID}"

# Get FQDN for the host
fqdn=$(/opt/aws/bin/ec2-describe-tags --aws-access-key "${awsAccessKey}" --aws-secret-key "${awsSecretKey}" \
        --filter "resource-type=instance" --filter "resource-id=${instanceID}" \
        --filter "key=fqdn" \
    | cut -f5)
if [ -z $fqdn ] ; then
  echo "Failed to get FQDN"
  fqdn=localhost
fi
echo "Hostname will be ${fqdn}"

# Get Apache version
nApacheVersion=$(/opt/aws/bin/ec2-describe-tags --aws-access-key "${awsAccessKey}" --aws-secret-key "${awsSecretKey}" \
        --filter "resource-type=instance" --filter "resource-id=${instanceID}" \
        --filter "key=apache" \
    | cut -f5)
if [ -z $nApacheVersion ] ; then
  nApacheVersion=0
  echo "Will not install Apache"
elif [ $nApacheVersion -eq 22 ] || [ $nApacheVersion -eq 24 ] ; then
  let nMajor=nApacheVersion/10
  let nMinor=nApacheVersion%10
  echo "Will install Apache v${nMajor}.${nMinor}"
else
  echo "Unsupported version of Apache requested: ${nApacheVersion}"
fi

# Get PHP version
nPhpVersion=$(/opt/aws/bin/ec2-describe-tags --aws-access-key "${awsAccessKey}" --aws-secret-key "${awsSecretKey}" \
        --filter "resource-type=instance" --filter "resource-id=${instanceID}" \
        --filter "key=php" \
    | cut -f5)
if [ -z $nPhpVersion ] ; then
  nPhpVersion=0
  echo "Will not install PHP"
elif [ $nPhpVersion -ge 53 ] ; then
  let nMajor=nPhpVersion/10
  let nMinor=nPhpVersion%10
  echo "Will install PHP v${nMajor}.${nMinor}"
else
  echo "Unsupported version of PHP requested: ${nPhpVersion}"
fi

# Set the hostname
echo -e "\n-----------------------------------------------------------------------------------------------------"
echo "Setting hostname to ${fqdn}"
cd /etc/sysconfig
/bin/cp -f network network.ORIGINAL.$(date +%Y-%m-%d)
sed --in-place "s/localhost.localdomain/${fqdn}/" network
hostname $fqdn

# Time stuff
# Our time servers appear to be added via DHCP.
echo -e "\n-----------------------------------------------------------------------------------------------------"
echo "Setting timezone and disabling AWS time servers"
sed --in-place '/ZONE/c \ZONE="America\/New_York"' /etc/sysconfig/clock
/bin/cp -sf /usr/share/zoneinfo/America/New_York /etc/localtime
sed --in-place 's/^server \(.*\).amazon/#server \1.amazon/' /etc/ntp.conf
service ntpd restart

# SNMP
echo -e "\n-----------------------------------------------------------------------------------------------------"
echo "Configuring SNMP"
mv -f ${sConfSNMPD} ${sConfSNMPD}.ORIGINAL.$(date +%Y%m%d)
cd $(dirname $sConfSNMPD)
wget ${sDataURL}/$(basename $sConfSNMPD)
chkconfig snmpd on
service snmpd start

# Sendmail
echo -e "\n-----------------------------------------------------------------------------------------------------"
echo "Setting up sendmail to forward to our smart host"
cd /etc/mail
/bin/cp -f sendmail.mc sendmail.mc.ORIGINAL.$(date +%Y%m%d)
# Make the change.
sed --in-place "s/dnl define(\`SMART_HOST', \`smtp.your.provider')/define(\`SMART_HOST', \`smtp.nemetschek.net')/" sendmail.mc
# Compile the change.
echo "Installing Sendmail compiler..."
yum -y install sendmail-cf
echo "Compiling new configuration..."
/etc/mail/make
echo "Removing compiler..."
yum -y autoremove sendmail-cf
# Apply the change.
service sendmail restart

# Automatic Security Updates
echo -e "\n-----------------------------------------------------------------------------------------------------"
echo "Configure automatic security updates by editing ${sConfYum}"
/bin/cp -f ${sConfYum} ${sConfYum}.ORIGINAL.$(date +%Y%m%d)
sed --in-place 's/update_cmd = default/update_cmd = security/' ${sConfYum}
sed --in-place 's/apply_updates = no/apply_updates = yes/' ${sConfYum}
sed --in-place 's/emit_via = stdio/emit_via = email/' ${sConfYum}
sed --in-place "s/email_from = root@localhost/email_from = root@${fqdn}/" ${sConfYum}
sed --in-place 's/email_to = root/email_to = AWSEC2Notice@vectorworks.net/' ${sConfYum}
sed --in-place 's/email_host = localhost/email_host = smtp.nemetschek.net/' ${sConfYum}
chkconfig yum-cron on
service yum-cron start

# SSH
echo -e "\n-----------------------------------------------------------------------------------------------------"
echo "Configure sshd by editing ${sConfSSHD}"
/bin/cp -f ${sConfSSHD} ${sConfSSHD}.ORIGINAL.$(date +%Y%m%d)
sed --in-place '/#TCPKeepAlive/a TCPKeepAlive yes' ${sConfSSHD}
sed --in-place '/#LoginGraceTime/a LoginGraceTime 30s' ${sConfSSHD}
sed --in-place '/#ClientAliveInterval/a ClientAliveInterval 60' ${sConfSSHD}
sed --in-place '/#ClientAliveCountMax/a ClientAliveCountMax 4' ${sConfSSHD}
echo "Done"

# Optional web server setup
if [ $nApacheVersion -ne 0 ] || [ $nPhpVersion -ne 0 ] ; then
  echo -e "\n-----------------------------------------------------------------------------------------------------"
  echo "Installing Apache and PHP"
  
  echo "Getting subscript..."
  sApacheScriptRemote=${sScriptURL}/web_server_basic.sh
  sApacheScriptLocal=~/web_server_basic.sh
  wget --no-verbose --output-document ${sApacheScriptLocal} ${sApacheScriptRemote}

  echo "Calling subscript..."
  source ${sApacheScriptLocal} ${nApacheVersion} ${nPhpVersion}
  /bin/rm -f ${sApacheScriptLocal}
fi
