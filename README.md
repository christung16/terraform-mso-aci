## Terraform Config for ACI and MSO

Imagine you need to build ACI/MSO for different customers, unavoidably you need to config both underlay and overlay. Normally, we need to do the configuration on two controllers, APIC for underlay and MSO for overlay. It usually gives confusion to customer. And also, it takes time to rebuild the PoC for different customers.

The repository is to demonstrate how to use Terraform to provision underlay resources, VMM Integration from APIC and overlay resources from MSO in one single config file so that you can easily and consistently build and rebuild a ACI demo everytime. You just need to create different config file for different customers while using the same main.tf. And the config file is structural json format and human readable. You don't even need modify the main.tf if they consume same resources.

Another purpose of this repository is to learn a very consistent way to build your own main.tf. How to handle json type configuration in terraform for network resources.

## Use Case Description

In this repository, it shows more than 40 ACI/MSO resources:

1. Underlay resources include Vlan pool, aaep, vmm, interface policy, leaf accessport policy group, leaf interface profile, leaf access port selector, access port block, leaf profile, leaf selector and node block.
2. VMM Integration using VMWare including vmm domain, vmm credential and vmm_controller.
3. Overlay resources include mso_tenant, schema, schema_site, vrf, brdige domain, bridge domain subnets, application profile, epg, filter entry, contract, l3out.

Case 1:

A company call "General Company" wants a VMM integration and build a simple two tier application while two EPG are allowed all traffic pass thru.

Use "terraform.tfvars.usercase1" and replace "terraform.tfvars". Then, execute the terraform apply

Case 2:

A company call "ABC Company" wants a VMM integration and build a three tier application while Web to App allow tcp port 55555 and App to Database allow port 3306 only.

Use "terraform.tfvars.usercase2" and replace "terraform.tfvars". Then, execute the terraform apply

## Installation

1. Copy terraform.tfvars.usercase1 to terraform.tfvars. Or you can modify it directly for your own case
2. Modify username/password and IP address for APIC / MSO / VCenter
3. terraform init
4. terraform plan
5. terraform apply --auto-approve --parallelism=1

## Configuration

- Copy terraform.tfvars.usercase1 terraform.tfvars.usercase2 or to terraform.tfvars. 
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

Be minded that in vmm_vmware section, need to enter the vcenter info:

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

## How to test

1. You need to have ACI and UCS with VMware/Vcenter installed

## Known issues:

1. terraform apply need to use "parallelism=1" since MSO has a lot of dependancy
2. In the key-value pair, key's name has to be same as "name = "

For example:
epgs = {
    WEB_EPG = {         // <<== The "key" same as the "name" below
        name = "WEB_EPG"
        display_name = "WEB_EPG"
        anp_name = "ABC_AP" 
        bd_name = "ABC_BD1"
        vrf_name = "ABC_VRF"
        dn = "abc_com_vswitch"
    }

3. After successfully applied, you need to manually map the upnlink into the vmnic 

## Getting help

Instruct users how to get help with this code; this might include links to an issues list, wiki, mailing list, etc.

----

## Licensing info

A license is required for others to be able to use your code. An open source license is more than just a usage license, it is license to contribute and collaborate on code. Open sourcing code and contributing it to [Code Exchange](https://developer.cisco.com/codeexchange/) or [Automation Exchange](https://developer.cisco.com/automation-exchange/) requires a commitment to maintain the code and help the community use and contribute to the code. 

Choosing a license can be difficult and depend on your goals for your code, other licensed code on which your code depends, your business objectives, etc.   This template does not intend to provide legal advise. You should seek legal counsel for that. However, in general, less restrictive licenses make your code easier for others to use.

> Cisco employees can find licensing options and guidance [here](https://wwwin-github.cisco.com/eckelcu/DevNet-Code-Exchange/blob/master/GitHubUsage.md#licensing-guidance).

Once you have determined which license is appropriate, GitHub provides functionality that makes it easy to add a LICENSE file to a GitHub repo, either when creating a new repo or by adding to an existing repo.

When creating a repo through the GitHub UI, you can click on *Add a license* and select from a set of [OSI approved open source licenses](https://opensource.org/licenses). See [detailed instructions](https://help.github.com/articles/licensing-a-repository/#applying-a-license-to-a-repository-with-an-existing-license).

Once a repo has been created, you can easily add a LICENSE file through the GitHub UI at any time. Simply select *Create New File*, type *LICENSE* into the filename box, and you will be given the option to select from a set of common open source licenses. See [detailed instructions](https://help.github.com/articles/adding-a-license-to-a-repository/).

Once you have created the LICENSE file, be sure to update/replace any templated fields with appropriate information, including the Copyright. For example, the [3-Clause BSD license template](https://opensource.org/licenses/BSD-3-Clause) has the following copyright notice:

`Copyright (c) <YEAR>, <COPYRIGHT HOLDER>`

See the [LICENSE](./LICENSE) for this template repo as an example.

Once your LICENSE file exists, you can delete this section of the README, or replace the instructions in this section with a statement of which license you selected and a link to your license file, e.g.

This code is licensed under the BSD 3-Clause License. See [LICENSE](./LICENSE) for details.

Some licenses, such as Apache 2.0 and GPL v3, do not include a copyright notice in the [LICENSE](./LICENSE) itself. In such cases, a NOTICE file is a common place to include a copyright notice. For a very simple example, see [NOTICE](./NOTICE). 

In the event you make use of 3rd party code, it is required by some licenses, and a good practice in all cases, to provide attribution for all such 3rd party code in your NOTICE file. For a great example, see [https://github.com/cisco/ChezScheme/blob/master/NOTICE](https://github.com/cisco/ChezScheme/blob/master/NOTICE).   

----

## Credits and references

1. Projects that inspired you
2. Related projects
3. Books, papers, talks, or other sources that have meaningful impact or influence on this code
