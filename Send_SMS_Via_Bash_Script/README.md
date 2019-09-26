## In this README I'll show you how to send SMS Using **Yeastar TG400 HTTP SMS API** via **Bash Script**

- `FreeSwitch` **XML Dialplan** example:
```xml
<action application="system" data="*path_to_script*/sms.sh ${caller_id_number} ${destination_number} "/>
```
- Here is **Bash Script**:
```bash
#!/usr/bin/env bash
#===============================================================================
#          FILE:  sms.sh
#         USAGE:  ./sms.sh ${caller_id_number} ${destination_number}
#   DESCRIPTION:  Create and Send SMS about Missed Calls from the FreeSWITCH
#        AUTHOR:  Habib Quliyev , graypit@gmail.com , https://www.graypit.com
#       CREATED:  09/27/2019 11:30:23 AM +04
#===============================================================================

# GSM Gateway Info :
gsm_gw_ip='192.168.1.23'
username='apiuser'
pass='StR0nGP@sS'
port='1'

# Array type: SIP Number and Firstname/Lastname
declare -A employee=(
[100]='Habib+Quliyev'
[101]='Foo+Bar'
)

# Array type: SIP Number and Mobile Number
declare -A mobile=(
[100]='0777415001'
[101]='0777415001' # I don't have secondary number :)
)

Find_Who_Is_and_Send_SMS() {
# Find Called_ID Info
for cid in "${!employee[@]}"
do
  if [ "$1" = "$cid"  ]
  then
     srcname=${employee[$cid]}
     srcmob=${mobile[$cid]}
  fi
done
# Find Destination_ID Info
for did in "${!employee[@]}"
do
  if [ "$2" = "$did" ]
  then
     dstname=${employee[$did]}
     dstmob=${mobile[$did]}
     dstnum=$2
  fi
done
# Content Preparation
sms="Hi+$dstname!+You+have+a+missed+call+from:+$srcname.+Time:+`date +'%H:%M:%S'`+.His+cell+phone:$srcmob.Internal+SIP:$srcnum+By+GPT"
# Sending the SMS
curl -POST "http://$gsm_gw_ip/cgi/WebCGI?1500101=account=$username&password=$pass&port=$port&destination=$dstmob&content=$sms"
}

Find_Who_Is_and_Send_SMS $1 $2
```