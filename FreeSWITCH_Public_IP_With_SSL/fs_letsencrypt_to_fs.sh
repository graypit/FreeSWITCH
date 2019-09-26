#!/usr/bin/env bash
#===============================================================================
#
#          FILE:  fs_letsencrypt_to_fs.sh
#
#         USAGE:  fs_letsencrypt_to_fs.sh domain_name (Without www // e.g ./fs_letsencrypt_to_fs.sh call.pronet.az)
#
#   DESCRIPTION:  Deploy LetsEncrypt Certificates to FreeSWITCH
#        AUTHOR:  Habib Quliyev (), graypit@gmail.com
#       VERSION:  1.0
#       CREATED:  10/07/2019 10:23:01 AM +04
#      REVISION:  ---
#===============================================================================

if [ "$#" -ne 1 ]
then
   echo "Usage: ./$(basename $0) example.com"
   exit 155
fi

# Set Global Variables
domain=$1
email='graypit@gmail.com'
LePath="/etc/letsencrypt/live/$domain*"
FSPath='/etc/freeswitch/tls'

# Install Certboot for NGINX

if [ -z $(which certbot) ]
then
   apt install python-certbot-nginx -t stretch-backports -y
else
   echo 'Certboot already installed ! Skip...' && sleep 0.3
fi

echo -e "$email\n2\n" | certbot --nginx -d $domain | grep 'Congratulations!'
if [ "$?" = '0' ]
then
   echo "LetsEncrypt Certificates has been generated"
   systemctl restart nginx
else
   echo "LetsEncrypt Certificates generating failed..."
   exit 101
fi
# Set Arrays
declare -A LeCerts=([1]='cert.pem' [2]='chain.pem' [3]='fullchain.pem' [4]='privkey.pem')
declare -A FSCerts=([1]='agent.pem' [2]='tls.pem' [3]='wss.pem' [4]='dtls-srtp.pem')
# Clean Certs folder (FreeSWITCH)
rm -rf $FSPath/*
# Create Main Cert for FreeSWITCH
cat $LePath/fullchain.pem > $FSPath/all.pem
cat $LePath/privkey.pem >> $FSPath/all.pem

# Function for Deploying all certificates to FreeSWITCH
DeployCerts() {
for i in `seq 4`
do
   cp $LePath/${LeCerts[$i]} $FSPath/${LeCerts[$i]}
done

for i in `seq 4`
do
   ln -s $FSPath/all.pem $FSPath/${FSCerts[$i]}
done
}
DeployCerts

# Change Owner to FreeSWITCH and restart
chown -R freeswitch:freeswitch $FSPath/
systemctl restart freeswitch

if [ "$?" = '0' ]
then
   echo "LetsEncrypt Certificates Successfully Installed to FreeSWITCH"
else
   echo "Intallation failed !"
fi