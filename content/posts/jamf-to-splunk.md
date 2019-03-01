---
title: "Jamf meets Splunk"
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

First we are gathering all enrolled machines using ```$data = Invoke-RestMethod "https://$jamf_url/JSSResource/computers" -Headers $headers -OutFile jamf.json```. That returns a file looking like:

```json
{"computers":[{"id":148,"name":"nldm-l5e4"},{"id":151,"name":"nldm-5vht"},{"id":152,"name":"nldm-1f61"},{"id":153,"name":"nldm-n86u"},{"id":154,"name":"nldm-bmga"},{"id":165,"name":"nldm-8vjj"},{"id":166,"name":"nldm-9el8"},{"id":168,"name":"nldm-cme4"},{"id":169,"name":"nllm-slr7"},{"id":170,"name":"nldm-o9wm"},{"id":171,"name":"nllm-83em"},{"id":172,"name":"nldm-da30"},{"id":173,"name":"nldm-a9p2"},{"id":174,"name":"nllm-pviq"},{"id":181,"name":"nldm-4o5x"},{"id":184,"name":"nldm-iwn9"},{"id":185,"name":"nldm-yr93"},{"id":205,"name":"nllm-el3h"},{"id":210,"name":"nllm-a4ri"},{"id":211,"name":"nldm-hrzi (2)"},{"id":212,"name":"nllm-8vxm"},{"id":221,"name":"nldm-3xsd"},{"id":222,"name":"nldm-2i3l"},{"id":224,"name":"nldm-9139"},{"id":225,"name":"nldm-4g1t"},{"id":226,"name":"nldm-z97e"}]}
```

Then we convert that from json using ```$data = get-content jamf.json | convertfrom-json``` to put it into a variable with the computers ID per line. When we have that file we use it in the Jamf_DATA function and eventually end up with a log file containg the computers data as following (anonymised):

```json
03/01/2019 15:29:08 {"computer":{"general":{"id":226,"name":"nldm-z97e","mac_address":"xxx","alt_mac_address":"xxx","ip_address":"xxx","last_reported_ip":"xxx","serial_number":"xxx","udid":"xxx","jamf_version":"10.9.0-t1544463445","platform":"Mac","barcode_1":"","barcode_2":"","asset_tag":"","remote_management":{"managed":true,"management_username":"macadmin","management_password_sha256":"xxx"},"mdm_capable":true,"mdm_capable_users":{"mdm_capable_user":"xxx"},"management_status":{"enrolled_via_dep":true,"user_approved_enrollment":true,"user_approved_mdm":true},"report_date":"2019-03-01 09:49:19","report_date_epoch":1551433759204,"report_date_utc":"2019-03-01T09:49:19.204+0000","last_contact_time":"2019-03-01 14:10:28","last_contact_time_epoch":1551449428195,"last_contact_time_utc":"2019-03-01T14:10:28.195+0000","initial_entry_date":"2019-03-01","initial_entry_date_epoch":1551429401260,"initial_entry_date_utc":"2019-03-01T08:36:41.260+0000","last_cloud_backup_date_epoch":0,"last_cloud_backup_date_utc":"","last_enrolled_date_epoch":1551429428657,"last_enrolled_date_utc":"2019-03-01T08:37:08.657+0000","distribution_point":"","sus":"","netboot_server":"","site":{"id":-1,"name":"None"},"itunes_store_account_is_active":false},"location":{"username":"erol.simsir","realname":"Erol Simsir","real_name":"Erol Simsir","email_address":"erol.simsir@coolblue.nl","position":"Developer","phone":"","phone_number":"","department":"","building":"xxx","room":""},"hardware":{"make":"Apple","model":"13-inch MacBook Pro (Early 2015)","model_identifier":"MacBookPro12,1","os_name":"Mac OS X","os_version":"10.14.3","os_build":"18D42","master_password_set":false,"active_directory_status":"xxx","service_pack":"","processor_type":"Intel Core i7","processor_architecture":"x86_64","processor_speed":0,"processor_speed_mhz":0,"number_processors":1,"number_cores":2,"total_ram":16384,"total_ram_mb":16384,"boot_rom":"180.0.0.0.0","bus_speed":0,"bus_speed_mhz":0,"battery_capacity":96,"cache_size":4096,"cache_size_kb":4096,"available_ram_slots":0,"optical_drive":"","nic_speed":"10/100/1000","smc_version":"2.28f7","ble_capable":true,"sip_status":"Enabled","gatekeeper_status":"App Store and identified developers","xprotect_version":"2101","institutional_recovery_key":"Not Present","disk_encryption_configuration":"","filevault2_users":[],"storage":[{"disk":"disk0","model":"APPLE SSD SM0512G","revision":"BXZ13A0Q","serial_number":"xxx","size":0,"drive_capacity_mb":0,"connection_type":"NO","smart_status":"Verified","partition":{"name":"Macintosh HD (Boot Partition)","size":476902,"type":"boot","partition_capacity_mb":476902,"percentage_full":3,"filevault_status":"Not Encrypted","filevault_percent":0,"filevault2_status":"Not Encrypted","filevault2_percent":0,"boot_drive_available_mb":0,"lvgUUID":"","lvUUID":"","pvUUID":""}},{"disk":"disk2","model":"","revision":"","serial_number":"","size":0,"drive_capacity_mb":0,"connection_type":"","smart_status":"","partition":{"name":"Google Chrome","size":195,"type":"other","partition_capacity_mb":195,"percentage_full":100,"filevault_status":"Not Encrypted","filevault_percent":0,"filevault2_status":"Not Encrypted","filevault2_percent":0}}],"mapped_printers":[{"name":"xxx @ xxx","uri":"ipp://xxx%20%40%20Lisa%E2%80%99s%20MacBook%20Pro._ipp._tcp.local./cups","type":"Xerox WorkCentre 6605DN","location":"Weena Copyroom 8A"}]},"extension_attributes":[{"id":1,"name":"coolblue-enrolled","type":"String","value":"3"},{"id":7,"name":"coolblue-filevault","type":"String","value":"FileVault is Off."},{"id":4,"name":"coolblue-initial-hostname","type":"String","value":"nldm-z97e"},{"id":5,"name":"Host name","type":"String","value":"nldm-z97e"},{"id":2,"name":"Last User","type":"String","value":""},{"id":3,"name":"R","type":"String","value":"Not Installed"},{"id":6,"name":"Uptime","type":"String","value":"10:49  up  1:06, 1 user, load averages: 2.13 1.67 1.48"}]}}
```

This script is creating the ```/var/log/jamf/jamf-monitor``` file which is being monitored by the SplunkForwarder using this inputs.conf.

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
