---
title: "Jamf to Splunk"
date: 2019-03-01T14:32:10+01:00
toc: false
images:
tags:
  - Splunk
  - Jamf
  - powershell
  - api
---

### Jamf metrics to SplunkEnterprise

Since we would like to have insights in our enrollments we were looking for a solution that could update as close to realtime as possible. We ended up using Splunk and a intermediate script server. The script server is performing the API call and providing data to the file that's being monitored by a SplunkForwarder.

The script that's performing the API call is the following.

```powershell
#gather all enrolled computers
function Jamf_API_call {
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Accept", 'application/json;version=24')
$headers.Add("Authorization", 'Basic $jamf_api_auth')

$data = Invoke-RestMethod "https://$jamf_url/JSSResource/computers" -Headers $headers -OutFile jamf.json
$data = get-content jamf.json | convertfrom-json

$script:macOS_jamf = $data.computers.id
}

#grep General, Hardware, Location and extensionattributes data per computer and add to the log
function Jamf_DATA {
Foreach ($id in $macOS_jamf)
{
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Accept", 'application/json;version=24')
$headers.Add("Authorization", 'Basic $jamf_api_auth')
$mac_data = Invoke-RestMethod "https://$jamf_url/JSSResource/computers/id/$id/subset/General&Hardware&Location&extensionattributes" -Headers $headers -OutFile jamf-out.json
$mac_data_new = get-content jamf-out.json
$date = Get-Date
"$date $mac_data_new" | Out-File -Append /var/log/jamf/jamf-monitor
}
}

Jamf_API_call
Jamf_DATA
```

This script is creating the ```/var/log/jamf/jamf-monitor``` file which is being monitored by the SplunkForwarder using this input.conf.

```
[monitor:///var/log/jamf/jamf-monitor]
index=production_jamf
sourcetype=jamf
disabled = false
```

Eventually we're pushing the data to an index in our Splunkcloud environment. Due to the fact we're pushing JSON through our SplunkForwarder we needed to adjust the props.conf. The actual changes made are the following:

```
Indexed Extractions   none
SEDCMD-strip_prefix   s/^[^{]+//g
KV_MODE               json
```

This results in the following dashboard 🧐.

{{< figure src="/images/jamf-to-splunk.png" alt="Jamf <3 Splunk" position="center" style="border-radius: 8px;" >}}
