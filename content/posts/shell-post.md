---
title: "Rename machine script"
date: 2019-02-28T19:53:04+01:00
toc: false
images:
tags:
  - bash
  - scripts
  - jamf
---

This post is to test the PrismJS syntax highlighting.

```bash
#!/bin/bash

#####################
##### Variables #####
#####################
# $API_USER (jamf parameter 4)
# $API_PASSWORD (jamf parameter 5)

CURRENTHOSTNAME=$(hostname)
API_URL=$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url)
API_USER=$4
API_PASSWORD=$5
SERIALNUMBER=$(system_profiler SPHardwareDataType | grep 'Serial Number (system)' | awk '{print $NF}')

# Get Mac data from jamf (using serialnumber, requesting ONLY the extensionattributes subset)
curl -s -u $API_USER:$API_PASSWORD "$API_URL"JSSResource/computers/serialnumber/$SERIALNUMBER/subset/General\&extension_attributes -X GET -H "Accept: application/xml" > /tmp/remediation-hostname.xml

# Extract the initial hostname from Jamf data (this is the hostname our mac should already have)
JAMFHOSTNAME=$(xmllint --xpath '/computer/extension_attributes/extension_attribute[name="coolblue-initial-hostname"]/value/text()' /tmp/remediation-hostname.xml)

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
      if [[ ! $CURRENTHOSTNAME == "$JAMFHOSTNAME" ]]; then
        echo "Mac is renamed! remediation starting..."
        /usr/sbin/scutil --set ComputerName "$JAMFHOSTNAME"
        /usr/sbin/scutil --set LocalHostName "$JAMFHOSTNAME"
        /usr/sbin/scutil --set HostName "$JAMFHOSTNAME"
        echo "Mac was renamed from $CURRENTHOSTNAME back to $JAMFHOSTNAME"
      else
    		echo "Mac name is compliant, nothing to do.."
      fi
    break
    fi
done
# Removing evidence ;)
rm -f /tmp/remediation-hostname.xml

exit 0
```
