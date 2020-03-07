# Packer build for Ubuntu 18.04

_Notes, in progress:_

1. Create a file in the root directory called variables.json
2. Add the following line, modified for your environment

```
{
  "ssh_pass": 		"SSH_PASSWORD",
  "ssh_user":		"SSH_USERNAME",
  "vcenter_server":	"VCENTER_SERVER",
  "vcenter_user":	"VCENTER_USER",
  "vcenter_password":   "VCENTER_PASSWORD",
  "vcenter_datacenter":	"DATACENTER",
  "vcenter_host":	"ESX_HOST_NAME",
  "vcenter_datastore":	"DATASTORE_NAME",
}
```
