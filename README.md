## Terraform Integrate ACI and MSO Configuration

By leveraging the advantage of Terraform IaC characteristic (https://developer.cisco.com/iac/), it can be easily and consistently build and rebuild the ACI/MSO VMM integration and other features PoC. It also integrates both controllers config into a single configuration file (.tfvars). It is much more human readable and easily to make the changes.

The repository is to demonstrate how to use Terraform to provision underlay resources, VMM Integration from APIC and overlay resources from MSO in one single config file so that you can easily and consistently build and rebuild a ACI demo everytime. You just need to create different config file for different customers while using the same main.tf. And the config file is structural json format and human readable. You don't even need modify the main.tf if they consume same resources.

Another purpose of this repository is to learn a very consistent way to build your own main.tf. How to handle json type configuration in terraform for network resources. Learn how to manupilate different data structure type which usually used in network environment.

## Use Case Description

Update 20210607: Add One-arm-firewall using Service Graph and PBR including physical port configuration.

In this repository, it shows more than 40 ACI/MSO resources:

1. Underlay resources include Vlan pool, aaep, vmm, interface policy, leaf accessport policy group, leaf interface profile, leaf access port selector, access port block, leaf profile, leaf selector and node block.
2. VMM Integration using VMWare including vmm domain, vmm credential and vmm_controller.
3. Overlay resources include mso_tenant, schema, schema_site, vrf, brdige domain, bridge domain subnets, application profile, epg, filter entry, contract, l3out.

Case 1:

A company call "General Company" wants a VMM integration and build a simple two tier application while two EPG are allowed all traffic pass thru.

Use "terraform.tfvars.usercase1" and replace "terraform.tfvars". Then, execute the terraform apply

![image](https://user-images.githubusercontent.com/21293832/120370018-ab0fd280-c346-11eb-91b9-aac9fadbfc5d.png)

Case 2:

A company call "ABC Company" wants a VMM integration and build a three tier application while Web to App allow tcp port 55555 and App to Database allow port 3306 only.

Use "terraform.tfvars.usercase2" and replace "terraform.tfvars". Then, execute the terraform apply

![image](https://user-images.githubusercontent.com/21293832/120368766-0e990080-c345-11eb-97bc-3eab7a727a49.png)


## Installation

To build the lab:
1. Copy terraform.tfvars.usercase1 to terraform.tfvars. Or you can modify it directly for your own case
2. Modify username/password and IP address for APIC / MSO / VCenter
3. terraform init
4. terraform plan
5. terraform apply --auto-approve --parallelism=1
6. Open MSO, click Schema, click template, click "Deploy to Sites" in order to deploy the overlay config to APIC and associate the underlay

To destroy the lab:

7. Open MSO, click Schema, there are "..." under the site, click "Undeploy template" in order to deprovision the overlay config from APIC
8. "terraform destroy --auto-approve --parallelism=1" to destroy the both config from APIC and MSO

## Configuration

- Copy terraform.tfvars.usercase1 or terraform.tfvars.usercase2 to terraform.tfvars. 
- Build you own Use case by modifying terraform.tfvars

## Usage

1. Modify username/password and URL

        mso_user = {
            username = "admin"
            password = "<password>"  // for office lab
            url = "https://<mso ip>"

        }

        aci_user = {
            username = "admin"
            password = "<password>"
            url = "https://<apic ip>"
        }

        vcenter_user = {
            username = "administrator@vsphere.local"
            password = "<password>"
            url = "<vcenter ip>"   
        }

2. Be minded that in vmm_vmware section, need to enter the vcenter info:

            vmm_vmware = {
                gen_com_vswitch = {
                    provider_profile_dn = "uni/vmmp-VMware"
                    name = "gen_com_vswitch"
                    vlan_pool = "gen_com_vlan_pool_1"
                    vcenter_host_or_ip = "<vcenter ip>"
                    vcenter_datacenter_name = "ACI-Datacenter"
                    dvs_version = "6.6"
                    vcenter_usr = "administrator@vsphere.local"
                    vcenter_pwd = "<password>"
                    aaep_name = "aaep_gen_com_vswitch" 
                }
            }

### Learn how to manipulate the data structures which commonly used in network environment

1. Map in the Map
   In .tfvars
   
        cdp = {
            cdp-enable = {
                name = "gen_com_cdp_enable"
                admin_st = "enabled"
            }
            cdp-disable = {
                name = "gen_com_cdp_disable"
                admin_st = "disabled"
            }
        }

  Single Resource with for_each
  In main.tf

        resource "aci_cdp_interface_policy" "cdp" {
          for_each = var.cdp
          name = each.value.name
          admin_st = each.value.admin_st
        }

2. List in the Map
   In .tfvars

        bds = {
            GENERAL_BD1 = {
                name = "GENERAL_BD1"
                display_name = "GENERAL_BD1"
                vrf_name = "GENERAL_VRF"
                subnets = [ "192.168.100.254/24", "10.207.40.251/24", "10.207.40.252/24" ]
            }
        }

  Flatten it and use for_each
  In main.tf

          bd_subnets = flatten ([
            for bd_key, bd in var.bds : [
              for subnet in bd.subnets : {
                bd_name = bd_key
                bd_subnet = subnet

              }
            ]
          ])

        resource "mso_schema_template_bd_subnet" "bd_subnets" {
          for_each = {
            for subnet in local.bd_subnets: "${subnet.bd_name}.${subnet.bd_subnet}" => subnet
          }
          schema_id = mso_schema.schema.id
          template_name = var.template_name
          bd_name = each.value.bd_name
          ip = each.value.bd_subnet
          scope = "public"
          shared = true
          depends_on = [
            mso_schema_template_bd.bds
          ]
        }

## How to test

1. You need to have ACI, MSO and UCS with VMware/Vcenter installed

## How to destroy the resources

1. Open MSO, click Schema, there are "..." under the site, choose Undeploy Template. Otherwise you can't destroy the resouces correctly
2. terraform destroy --auto-approve --parallelism=1
    
## Known issues:

1. terraform apply need to use "parallelism=1" due to MSO limitation
2. After successfully applied, you need to manually map the upnlink into the vmnic 
3. When destroy the resource, remember to "Undeploy template" first
4. There are still missing a lot of advance features like lacp, vpc, pbr, service graph, etc. You can try to build your own and share it out.
    
## Getting help

Instruct users how to get help with this code; this might include links to an issues list, wiki, mailing list, etc.

----

## Credits and references

1. [Cisco Infrastructure As Code](https://developer.cisco.com/iac/)
2. [ACI provider Terraform](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs)
3. [MSO provider Terraform](https://registry.terraform.io/providers/CiscoDevNet/mso/latest/docs)
4. [Automation Terraform](https://developer.cisco.com/automation-terraform/)
