---
title: "Rename machine script"
date: 2019-02-28T19:53:04+01:00
toc: false
draft: true
images:
tags:
-   Bash
-   Scripts
-   Jamf
---

This post is to test the PrismJS syntax highlighting.

```bash
#!/usr/bin/env bash

############################
##### Script Variables #####
############################
# $API_USER (jamf parameter 4)
# $API_PASSWORD (jamf parameter 5)

CURRENTHOSTNAME=$(/usr/sbin/scutil --get ComputerName)
CURRENTCOMPUTERNAME=$(/usr/sbin/scutil --get LocalHostName)
CURRENTLOCALHOSTNAME=$(/usr/sbin/scutil --get HostName)
API_URL=$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url)
API_USER=$4
API_PASSWORD=$5
SLACKTOKEN=$6
SERIALNUMBER=$(system_profiler SPHardwareDataType | grep 'Serial Number (system)' | awk '{print $NF}')

# Get Mac data from jamf (using serialnumber, requesting ONLY the extensionattributes subset)
curl -s -u $API_USER:$API_PASSWORD "$API_URL"JSSResource/computers/serialnumber/$SERIALNUMBER/subset/General\&extension_attributes -X GET -H "Accept: application/xml" > /tmp/remediation-hostname.xml

# Extract the initial hostname from Jamf data (this is the hostname our mac should already have)
JAMFHOSTNAME=$(xmllint --xpath '/computer/extension_attributes/extension_attribute[name="coolblue-initial-hostname"]/value/text()' /tmp/remediation-hostname.xml)

slackmessage_remediation() {
  curl --silent --location --request POST 'https://slack.com/api/chat.postMessage' \
  --header 'Authorization: Bearer '$SLACKTOKEN'' \
  --form 'channel=#ohhahh-notifications-private' \
  --form 'title=Jamf Script [Remediation - Rename machine]' \
  --form 'blocks=[
      {
        "type": "section",
        "text": {
          "type": "mrkdwn",
          "text": "[INFO] A device has been renamed by the remediation script:"
        }
      },
      {
        "type": "section",
        "text": {
          "type": "mrkdwn",
          "text": "• JamfHostname:'$JAMFHOSTNAME' \n\n • Hostname:'$CURRENTHOSTNAME' \n • LocalHostname:'$CURRENTLOCALHOSTNAME' \n • ComputerName:'$CURRENTCOMPUTERNAME'"
        }
      }
  ]'
}

slackmessage_ok() {
  curl --silent --location --request POST 'https://slack.com/api/chat.postMessage' \
  --header 'Authorization: Bearer '$SLACKTOKEN'' \
  --form 'channel=#ohhahh-notifications-private' \
  --form 'title=Jamf Script [Remediation - Rename machine]' \
  --form 'blocks=[
      {
        "type": "section",
        "text": {
          "type": "mrkdwn",
          "text": "[SUCCESS] :success-kid: '$(hostname)' is compliant, nothing to do:"
        }
      },
      {
        "type": "section",
        "text": {
          "type": "mrkdwn",
          "text": "Initial hostname is '$JAMFHOSTNAME'."
        }
      }
  ]'
}

renamemachine() {
while true
do
  MDM_SERIAL=$(xmllint --xpath '/computer/general/serial_number/text()' /tmp/remediation-hostname.xml)
    if [[ ! $MDM_SERIAL == "$SERIALNUMBER" ]]; then
      echo "[ERROR] Data incorrect"
      echo "[ERROR] The MDM serial number ($MDM_SERIAL) does not correspond with the local serial number ($SERIALNUMBER)"
      curl -s -u $API_USER:$API_PASSWORD "$API_URL"JSSResource/computers/serialnumber/$SERIALNUMBER/subset/General\&extension_attributes -X GET -H "Accept: application/xml" > /tmp/remediation-hostname.xml
      sleep 10
    else
      # Test if LocalHostName is the same as the wanted hostname.
      if [[ ! "$CURRENTHOSTNAME" == "$JAMFHOSTNAME" ]] || [[ ! "$CURRENTLOCALHOSTNAME" == "$JAMFHOSTNAME" ]] || [[ ! "$CURRENTCOMPUTERNAME" == "$JAMFHOSTNAME" ]]; then
        echo "Mac is renamed! remediation starting..."
        /usr/sbin/scutil --set ComputerName "$JAMFHOSTNAME"
        /usr/sbin/scutil --set LocalHostName "$JAMFHOSTNAME"
        /usr/sbin/scutil --set HostName "$JAMFHOSTNAME"
        echo "Mac was renamed from Hostname:$CURRENTHOSTNAME, LocalHostname:$CURRENTLOCALHOSTNAME, ComputerName:$CURRENTCOMPUTERNAME back to $JAMFHOSTNAME"
        slackmessage_remediation
        #curl -X POST --data-urlencode 'payload={"channel": "#ohhahh-notifications-private", "text": "[SUCCESS] Device was renamed from Hostname:'$CURRENTHOSTNAME', LocalHostname:'$CURRENTLOCALHOSTNAME', ComputerName:'$CURRENTCOMPUTERNAME' back to '$JAMFHOSTNAME'"}' https://hooks.slack.com/services/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
      else
    		echo "Mac name [$(hostname)] is compliant, nothing to do.."
     		echo "Initial hostname is [$JAMFHOSTNAME]."
            slackmessage_ok
      fi
    break
    fi
done
# Removing evidence ;)
rm -f /tmp/remediation-hostname.xml
}

renamemachine

exit 0

```
