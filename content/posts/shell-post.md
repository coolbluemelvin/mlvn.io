---
title: "Rename machine script"
date: 2019-02-28T19:53:04+01:00
toc: false
images:
tags:
-   bash
-   scripts
-   jamf
---

This post is to test the PrismJS syntax highlighting.

```bash
#!/bin/bash

#####################
##### Variables #####
#####################
# $LDAP_HOST = ldap host (jamf parameter 4)
# $LDAP_PASSWORD = ldap password (jamf parameter 5)
# $LDAP_USER = ldap user (jamf parameter 6)
# $OU (jamf parameter 7)
# $API_USER (jamf parameter 8)
# $API_PASSWORD (jamf parameter 9)

############################
##### Script Variables #####
############################
# $EXISTING_RECORDS = an LDAP query to get all existing records.
# $DEVELOPERS = an API query to check if the current user ($3), is a developer. (checks if a user is member of DLG-APP-JAMF-Clients-Developers).
# $UUID = A 4 digit random generated alphanumeric string.
# $PREFIX = the Hostname prefix we put before the random generated alphanumeric string.
# $NEW_HOSTNAME = putting the prefix and Unique alphanumeric string together resulting the new unique hostname.
# $BAD_WORDS_LIST = dowloads a list with unauthorized words from the Office Automation repository (Github RAW).

# bash generate random 4 character alphanumeric string (upper and lowercase) and set variable
UUID=$(cat /dev/random | LC_CTYPE=C tr -dc 'a-z0-9' | fold -w 4 | head -n 1)

# populate ldap specific variables and credentials
LDAP_HOST=$4 # $LDAP_HOST = ldap host (jamf parameter 4)
LDAP_PASSWORD=$5 # $LDAP_PASSWORD = ldap password (jamf parameter 5)
LDAP_USER=$6 # $LDAP_USER = ldap user (jamf parameter 6)
OU=$7 # $OU (jamf parameter 7)
API_URL=$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url)
API_USER=$8 #(jamf parameter 10)
API_PASSWORD=$9 #(jamf parameter 11)
EXISTING_RECORDS=$(ldapsearch -h "$LDAP_HOST" -p 389 -x -D "$LDAP_USER" -w "$LDAP_PASSWORD" -b "$OU" | grep name: | sed 's/name: //')
DEVELOPERS=$(curl -s -u $API_USER:$API_PASSWORD -H "Accept: application/json" -X GET "$API_URL"JSSResource/ldapservers/name/$LDAP_HOST/group/DLG-APP-JAMF-Clients-Developers/user/$3 | sed -e 's/^.*"is_member":"\([^"]*\)".*$/\1/')
BAD_WORDS_LIST=$(curl -H 'Authorization: token $git_token' -H 'Accept: application/vnd.github.v4.raw' -L https://api.github.com/repos/coolblue-development/office-automation/contents/macOS/bad_words)
SERIALNUMBER=$(system_profiler SPHardwareDataType | grep 'Serial Number (system)' | awk '{print $NF}')

#####################
##### Functions #####
#####################

### generate new hostname based on prefix and randomized UUID
generate_hostname() {
    if [[ $DEVELOPERS == "Yes" ]]; then
        PREFIX=nldm-
    else
        PREFIX=nllm-
    fi

    NEW_HOSTNAME=$PREFIX$UUID

while true
do
    if [[ $EXISTING_RECORDS =~ $NEW_HOSTNAME || $BAD_WORDS_LIST =~ $UUID ]]; then
        sleep 1
    else
        /usr/sbin/scutil --set ComputerName "$NEW_HOSTNAME"
        /usr/sbin/scutil --set LocalHostName "$NEW_HOSTNAME"
        /usr/sbin/scutil --set HostName "$NEW_HOSTNAME"
        break
    fi
done
}
# Set the hostname in EA

coolblue-initial-hostname() {
  # Create a XML payload for the Jamf API.
cat << EOF > /private/tmp/coolblue-initial-hostname.xml
<computer>
<extension_attributes>
    <extension_attribute>
        <name>coolblue-initial-hostname</name>
        <value>$NEW_HOSTNAME</value>
    </extension_attribute>
</extension_attributes>
</computer>
EOF

# Send payload to Jamf API.
curl -s -u $API_USER:$API_PASSWORD "$API_URL"JSSResource/computers/serialnumber/$SERIALNUMBER/subset/extensionattributes -T "/private/tmp/coolblue-initial-hostname.xml" -X PUT
# Remove Payload from machine.
rm -f /private/tmp/coolblue-initial-hostname.xml
# Done!
}


##################
##### Script #####
##################

generate_hostname
coolblue-initial-hostname

```
