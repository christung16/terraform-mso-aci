# AUTHOR(s): Chris Tung <yitung@cisco.com>

mso_user = {
    username = "admin"
    password = "CIsco1234%67890"  // for office lab
    url = "https://10.74.202.79"

}

aci_user = {
    username = "admin"
    password = "C1sc0123"
    url = "https://10.74.202.71"
}

vcenter_user = {
    username = "administrator@vsphere.local"
    password = "C1sc0123"
    url = "10.74.202.163"   
}

// Caveat: No "." in the name // Underlay config in APIC

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

lldp = {
    lldp-enable = {
        name = "gen_com_lldp_enable"
        description = "gen_com_lldp_enable"
        admin_tx_st = "enabled"
        admin_rx_st = "enabled"
    }
    lldp-disable = {
        name = "gen_com_lldp_disable"
        description = "gen_com_lldp_disable"
        admin_tx_st = "disabled"
        admin_rx_st = "disabled"
    }
}

vlan_pool = {
    gen_com_vlan_pool_1 = {
        name = "gen_com_vlan_pool_1"
        alloc_mode = "dynamic"
        from = "vlan-2001"
        to = "vlan-3000"
    }
    gen_com_vlan_pool_2 = {
        name = "gen_com_vlan_pool_2"
        alloc_mode = "dynamic"
        from = "vlan-3001"
        to = "vlan-3900"
    }
    asa_phy_vlan_pool = {
        name = "asa_phy_vlan_pool"
        alloc_mode = "static"
        from = "vlan-2501"
        to = "vlan-2501"
    }
    ucs_vlan_pool = {
        name = "asa_phy_vlan_pool"
        alloc_mode = "static"
        from = "vlan-478"
        to = "vlan-478"
    }
}

vmm_vmware = {
    gen_com_vswitch = {
        provider_profile_dn = "uni/vmmp-VMware"
        name = "gen_com_vswitch"
        vlan_pool = "gen_com_vlan_pool_1"
        vcenter_host_or_ip = "10.74.202.163"
        vcenter_datacenter_name = "ACI-Datacenter"
        dvs_version = "6.6"
        vcenter_usr = "administrator@vsphere.local"
        vcenter_pwd = "C1sc0123"
        aaep_name = "aaep_gen_com_vswitch" 
        esxi_hosts = [ "10.74.202.122" ]

    }
}

phydomain = {
    asa_fw_phydomain = {
        name = "asa_fw_phydomain"
        vlan_pool = "asa_phy_vlan_pool"
        aaep_name = "aaep_asa_phydomain"
    }
    ucs_phydomain = {
        name = "ucs_phydomain"
        vlan_pool = "ucs_vlan_pool"
        aaep_name = "aaep_ucs_phydomain"
    }
}

l3domain = {
}

access_port_group_policy = {
    leaf_access_port_101_1_12_vmm_vcenter = {
        name = "leaf_access_port_101_1_12_vmm_vcenter"
        lldp_status = "gen_com_lldp_disable"
        cdp_status = "gen_com_cdp_enable"
        aaep_name = "aaep_gen_com_vswitch"
        leaf_profile = "leaf-101-Chris-profile"
        leaf_block = [101]
        ports = [
            {
                from_card = 1
                from_port = 12
                to_card = 1
                to_port = 12
            }
        ]
    }

    leaf_access_port_101_1_22_24_ucs_phydomain = {
        name = "leaf_access_port_101_1_22_24_ucs_phydomain"
        lldp_status = "gen_com_lldp_disable"
        cdp_status = "gen_com_cdp_enable"
        aaep_name = "aaep_ucs_phydomain"
        leaf_profile = "leaf-101-104-Chris-profile"
        leaf_block = [101, 104]
        ports = [
            {
                from_card = 1
                from_port = 22
                to_card = 1
                to_port = 24
            }
        ]
    }

    leaf_access_port_101_1_20_phydomain = {
        name = "leaf_access_port_101_1_20_phydomain"
        lldp_status = "gen_com_lldp_disable"
        cdp_status = "gen_com_cdp_enable"
        aaep_name = "aaep_asa_phydomain"
        leaf_profile = "leaf-101-Chris-profile"
        leaf_block = [101]
        ports = [
            {
                from_card = 1
                from_port = 20
                to_card = 1
                to_port = 20
            },
            {
                from_card = 1
                from_port = 25
                to_card = 1
                to_port = 25
            }
        ]
    }
}


sg = {
    two-arm-fw = {
        name = "two-arm-fw"
        service_node_type = "firewall"
        description = "two-arm-fw"
        devtype = "PHYSICAL"    // capital letters
        phydomain_name = "asa_fw_phydomain"
        inside_vlan = "vlan-2501"
        outside_vlan = "vlan-2502"
        inside_leaf_block = 101
        inside_card = 1
        inside_port = 20
        outside_leaf_block = 101
        outside_card = 1
        outside_port = 20

        site_nodes = [{
            site_name = "aci_site1"
            tenant_name = "General_Company_Tenant"
            node_name = "two-arm-fw"
            }
        ]
        contract_name = "Con_web_epg_to_app_epg"
        inside_bd_name = "fw_inside_bd"
        outside_bd_name = "fw_outside_bd"
        pbr_name = "pbr-two-arm-fw"

    }

}

pbr = {
    pbr-two-arm-fw = {
        ipsla_name = "ipsla_icmp"
        rh_grp_name = "rh_grp"
        name = "pbr-two-arm-fw"
        ip = "192.168.100.253"
        mac = "00:50:56:9a:b4:68"
    }
}


// Overlay config in MSO

template_name = "General_Company_Template"
schema_name = "General_Company_Schema"
mso_site = "aci-site1"


tenant = {
    name = "General_Company_Tenant"
    description = "Tenant Created by Terraform"
}

anps = {
    general_ap = {
        name = "general_ap"
        display_name = "general_ap"
    }
}

vrfs = {
    general_vrf = {
        name = "general_vrf"
        display_name = "general_vrf"
    }
}

bds = {
    web_bd = {
        name = "web_bd"
        display_name = "web_bd"
        vrf_name = "general_vrf"
        subnets = [ "192.168.100.254/24", "10.207.40.251/24", "10.207.40.252/24" ]
    }
    app_bd = {
        name = "app_bd"
        display_name = "app_bd"
        vrf_name = "general_vrf"
        subnets = [ "192.168.200.254/24" ]
    }
    database_bd = {
        name = "database_bd"
        display_name = "database_bd"
        vrf_name = "general_vrf"
        subnets = [ "192.168.201.254/24" ]
    }
    fw_inside_bd = {
        name = "fw_inside_bd"
        display_name = "fw_inside_bd"
        vrf_name = "general_vrf"
        subnets = [ "11.11.11.1/24" ]
    }
    fw_outside_bd = {
        name = "fw_outside_bd"
        display_name = "fw_outside_bd"
        vrf_name = "general_vrf"
        subnets = [ "22.22.22.1/24" ]
    }

}

epgs = {
    web_epg = {
        name = "web_epg"
        display_name = "web_epg"
        anp_name = "general_ap" 
        bd_name = "web_bd"
        vrf_name = "general_vrf"
        dn = "gen_com_vswitch"
    }
    database_epg = {
        name = "database_epg"
        display_name = "database_epg"
        anp_name = "general_ap" 
        bd_name = "database_bd"
        vrf_name = "general_vrf"
        dn = "gen_com_vswitch"
    }
    app_epg = {
        name = "app_epg"
        display_name = "app_epg"
        anp_name = "general_ap" 
        bd_name = "app_bd"
        vrf_name = "general_vrf"
        dn = "gen_com_vswitch"
    }
}

filters = {
    filter_all = {
        name = "filter_all"
        display_name = "filter_all_display_name"
        entry_name = "filter_all_entry_name"
        entry_display_name = "filter_all_entry_display_name"
        ether_type = "unspecified"
        ip_protocol = "unspecified"
        destination_from = "unspecified"
        destination_to = "unspecified"
        stateful = false
    }
    tcp_40000 = {
        name = "tcp_40000"
        ether_type = "ip"
        ip_protocol = "tcp"
        destination_from = "40000"
        destination_to = "40000"
        stateful=true
    }
    icmp = {
        name = "icmp"
        ether_type = "ip"
        ip_protocol = "icmp"
        stateful=false
    }
    tcp_22 = {
        name = "tcp_22"
        ether_type = "ip"
        ip_protocol = "tcp"
        destination_from = "ssh"
        destination_to = "ssh"
        stateful=true
    }
    tcp_3306 = {
        name = "tcp_3306"
        ether_type = "ip"
        ip_protocol = "tcp"
        destination_from = "3306"
        destination_to = "3306"
        stateful=true
    }
}

contracts = {
    Con_web_epg_to_app_epg = {
        contract_name = "Con_web_epg_to_app_epg"
        display_name = "Con_web_epg_to_app_epg"
        filter_type = "bothWay"
        scope = "tenant"
        filter_relationships = {
            filter_name = "tcp_40000"
        }
        filter_list = [ "tcp_22" ]
        directives = [ "none" ]
        anp_epg_consumer = {
            anp_name = "general_ap"
            epg_name = "web_epg"
        }
        anp_epg_provider = {
            anp_name = "general_ap"
            epg_name = "app_epg"
        }
    }
    Con_app_epg_to_database_epg = {
        contract_name = "Con_app_epg_to_database_epg"
        display_name = "Con_app_epg_to_database_epg"
        filter_type = "bothWay"
        scope = "tenant"
        filter_relationships = {
            filter_name = "tcp_40000"
        }
        filter_list = [ "icmp", "tcp_3306" ]
        directives = [ "none" ]
        anp_epg_consumer = {
            anp_name = "general_ap"
            epg_name = "app_epg"
        }
        anp_epg_provider = {
            anp_name = "general_ap"
            epg_name = "database_epg"
        }
    }
}

l3outs = {
}

ext_epg = {
}