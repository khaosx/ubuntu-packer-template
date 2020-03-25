# Packer build for Ubuntu 18.04
This is a packer build that will create four VM's on a vSphere server, which can be used as templates for further refinement. 

## General Info
All builds have disk layouts that conform to the best practices put forth in CIS benchmarks (as of 01/03/2020, v2.0.1). See the preseed files for more detail. The builds themselves have the following specs:

| VM Name | CPU | RAM | Disk Size |
| :--- | :---: | :---: | :---: |
| Ubuntu_18.04_Template_Small | 1 | 2048 | 18432 |
| Ubuntu_18.04_Template_Medium | 2 | 4096 | 26624 |
| Ubuntu_18.04_Template_Large | 4 | 8192 | 36864 |
| Ubuntu_18.04_Template_Control | 4 | 8192 | 36864 |

Additionally, there is customization that takes place after the initial build. Each build has a user named jarvis that handles all the "service account" functions. You MUST change the password in the preseed file. This can be done with the following command (you must have the `whois` package installed) 

`mkpasswd -s -m md5`

The output of that command can be placed in the preseed files at line 61, as shown below:

`d-i passwd/user-password-crypted password $1$Czgk1Y0D$83mF.IrQiARkbWFCfPl110`

The fourth VM ("control") is designed to be your master Ansible node. 

## Usage

1. Install [HashiCorp Packer](https://packer.io/)
2. `git clone https://github.com/khaosx/ubuntu-packer-template.git`
3. Create the variables file if you don't already have one (modify all variables!)

```
   cat >> variables.json << 'EOF'
   {
     "ssh_pass":			"SSH_PASSWORD",
     "ssh_user":			"SSH_USERNAME",
     "vcenter_server":		"VCENTER_SERVER",
     "vcenter_user":		"VCENTER_USER",
     "vcenter_password":	"VCENTER_PASSWORD",
     "vcenter_datacenter":	"DATACENTER",
     "vcenter_host":		"ESX_HOST_NAME",
     "vcenter_datastore":	"DATASTORE_NAME",
   }
EOF
```
4. Build vSphere VM with `packer build -var-file=variables.json ubuntu_1804_vm.json`

## Notes
* I have an issue building all four VM's in parallel. If you encounter this issue, try the following:
`packer build -parallel-builds=2 -var-file=variables.json ubuntu_1804_vm.json`


## References:
[CIS Benchmark v2.0.1](https://www.cisecurity.org/benchmark/ubuntu_linux/)
[Swap Size](https://itsfoss.com/swap-size/)