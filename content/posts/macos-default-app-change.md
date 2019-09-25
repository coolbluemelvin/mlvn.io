---
title: "macOS Change default application for UTI"
date: 2019-09-25T10:59:08+02:00
draft: true
---

```bash
#!/bin/bash

############################
##### Script Variables #####
############################
# $currentuser = Get the current logged in user
# $default_app = Application used as default
# $types = Uniform Type Identifer of the file type that needs to be adjusted

currentuser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
default_app='"com.google.chrome"'
declare -a types=('"com.microsoft.word.doc"'
                  '"org.openxmlformats.wordprocessingml.document"'
                  '"com.microsoft.powerpoint.ppt"'
                  '"org.openxmlformats.presentationml.presentation"'
                  '"com.microsoft.excel.xls"'
                  '"org.openxmlformats.spreadsheetml.sheet"')

for type in "${types[@]}"; do
  sudo -u $currentuser python -c 'from LaunchServices import LSSetDefaultRoleHandlerForContentType; LSSetDefaultRoleHandlerForContentType('$type', 0x00000002, '$default_app')'
  echo "Set $default_app as default application for $type"
done
```
