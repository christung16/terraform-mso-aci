terraform {
  required_providers {
    mso = {
      source = "CiscoDevNet/mso"
      version = "0.1.5"
    }
    aci = {
      source = "CiscoDevNet/aci"
      version = "0.7.0"
    }
    vsphere = {
      source = "hashicorp/vsphere"
      version = "1.26.0"
    }
  }
}

provider "mso" {
  username = var.mso_user.username
  password = var.mso_user.password
  url      = var.mso_user.url
  insecure = true
}

provider "aci" {
  username = var.aci_user.username
  password = var.aci_user.password
  url = var.aci_user.url
  insecure = true
}

provider "vsphere" {
  user = var.vcenter_user.username
  password = var.vcenter_user.password
  vsphere_server = var.vcenter_user.url
  allow_unverified_ssl = true
}


resource "aci_vlan_pool" "vlan_pool" {
  for_each = var.vlan_pool
  name = each.value.name
  alloc_mode = each.value.alloc_mode
}

resource "aci_ranges" "vlan_range" {
  for_each = var.vlan_pool
  vlan_pool_dn = aci_vlan_pool.vlan_pool[each.value.name].id
  from = each.value.from
  to = each.value.to
}

resource "aci_attachable_access_entity_profile" "vmm_vmware_aaep" {
  for_each = var.vmm_vmware
  name = each.value.aaep_name
#  relation_infra_rs_dom_p = [format ( "%s%s%s", each.value.provider_profile_dn,"/dom-",each.value.name )]
  relation_infra_rs_dom_p = [ aci_vmm_domain.vmm_domain[each.value.name].id ]
#  depends_on = [
#    aci_vmm_domain.vmm_domain,
#  ]
}

resource "aci_vmm_domain" "vmm_domain" {
  for_each = var.vmm_vmware
  provider_profile_dn = each.value.provider_profile_dn
  name = each.value.name
#  relation_infra_rs_vlan_ns = format( "%s%s%s", "uni/infra/vlanns-[", each.value.vlan_pool,"]-dynamic")
  relation_infra_rs_vlan_ns = aci_vlan_pool.vlan_pool[each.value.vlan_pool].id
}

resource "aci_vmm_credential" "vmm_cred" {
  for_each = var.vmm_vmware
  vmm_domain_dn = aci_vmm_domain.vmm_domain[each.value.name].id
  name = format( "%s%s", each.value.name,"-credential")
  annotation = "orchestrator:terraform"
  pwd = each.value.vcenter_pwd
  usr = each.value.vcenter_usr
}

resource "aci_vmm_controller" "gen_com_ctrl" {
  for_each = var.vmm_vmware
  vmm_domain_dn = aci_vmm_domain.vmm_domain[each.value.name].id
  name = format( "%s%s", each.value.name,"-controller")
  host_or_ip = each.value.vcenter_host_or_ip
  root_cont_name = each.value.vcenter_datacenter_name
  dvs_version = each.value.dvs_version
#  relation_vmm_rs_acc = format ( "%s%s%s%s%s", "uni/vmmp-VMware/dom-",each.value.name,"/usracc-",each.value.name,"-credential")
  relation_vmm_rs_acc = aci_vmm_credential.vmm_cred[each.value.name].id
}

resource "aci_cdp_interface_policy" "cdp" {
  for_each = var.cdp
  name = each.value.name
  admin_st = each.value.admin_st
}

resource "aci_lldp_interface_policy" "lldp" {
  for_each = var.lldp
  name = each.value.name
  description = each.value.description
  admin_tx_st = each.value.admin_tx_st
  admin_rx_st = each.value.admin_rx_st
}

module "accessportgroup" {
  source = "./modules/accessportgroup"
  for_each = var.access_port_group_policy
  name = each.value.name
  lldp_status = each.value.lldp_status
  cdp_status  = each.value.cdp_status
  aaep_name = each.value.aaep_name
  leaf_profile = each.value.leaf_profile
  leaf_block = each.value.leaf_block
  from_card = each.value.from_card
  from_port = each.value.from_port
  to_card = each.value.to_card
  to_port = each.value.to_port
  depends_on = [
    aci_cdp_interface_policy.cdp,
    aci_lldp_interface_policy.lldp,
#    aci_lacp_policy.lacp,
    aci_attachable_access_entity_profile.vmm_vmware_aaep
  ]
}


data "mso_site" "site1" {
  name = var.mso_site
}

locals {
  bd_subnets = flatten ([
    for bd_key, bd in var.bds : [
      for subnet in bd.subnets : {
        bd_name = bd_key
        bd_subnet = subnet
        
      }
    ]
  ])
  l3out_subnets = flatten ([
    for l3out_key, l3out in var.l3outs : [
      for subnet, scope in l3out.subnets : {
        l3out_name = l3out_key
        l3out_subnet = subnet
        l3out_scope = scope
      }
    ]
  ])
}

/*
output "flatten_bd" {
  value = local.bd_subnets
}

output "flatten_l3out" {
  value = local.l3out_subnets
}
*/

resource "mso_tenant" "tn" {
    name = var.tenant.name
    display_name = var.tenant.name
    description = var.tenant.description
    site_associations {
      site_id = data.mso_site.site1.id
    }
}

resource "mso_schema" "schema" {
  name = var.schema_name
  template_name = var.template_name
  tenant_id = mso_tenant.tn.id
  depends_on = [
#    mso_tenant.tn,
    aci_vmm_domain.vmm_domain,
  ]
}

resource "mso_schema_site" "schema_site1" {
  schema_id = mso_schema.schema.id
  site_id = data.mso_site.site1.id
  template_name = var.template_name
#  depends_on = [
#    mso_schema.schema,
#  ]
}

resource "mso_schema_template_vrf" "vrfs" {
  for_each = var.vrfs
  name = each.value.name
  schema_id = mso_schema.schema.id
  template = var.template_name
  display_name = each.value.display_name
  layer3_multicast = false
  vzany = false
#  depends_on = [
#    mso_schema.schema
#  ]
}


resource "mso_schema_template_bd" "bds" {
  for_each = var.bds
  schema_id = mso_schema.schema.id
  template_name = var.template_name
  name = each.value.name
  display_name = each.value.display_name
  vrf_name = each.value.vrf_name
  layer2_unknown_unicast = "proxy"
  layer2_stretch = true
  depends_on = [
    mso_schema_template_vrf.vrfs,
  ]
}

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

resource "mso_schema_template_anp" "anps" {
  for_each = var.anps
  schema_id = mso_schema.schema.id
  template = var.template_name
  name = each.value.name
  display_name = each.value.display_name
#  depends_on = [
#    mso_schema.schema
#  ]
}

resource "mso_schema_template_anp_epg" "epgs" {
  for_each = var.epgs
  schema_id = mso_schema.schema.id
  template_name = var.template_name
  name = each.value.name
  display_name = each.value.display_name
  anp_name = each.value.anp_name
  bd_name = each.value.bd_name
  vrf_name = each.value.vrf_name
  depends_on = [
#    mso_schema.schema,
    mso_schema_template_anp.anps,
    mso_schema_template_bd.bds,
    mso_schema_template_vrf.vrfs,
  ] 
}

resource "mso_schema_site_anp_epg_domain" "epgs_domain" {
  for_each = var.epgs
  schema_id = mso_schema.schema.id
  site_id = mso_schema_site.schema_site1.id
  template_name = var.template_name
  anp_name = each.value.anp_name
  epg_name = each.value.name
  dn = each.value.dn
  deploy_immediacy = try (each.value.deploy_immediacy, "immediate")
  domain_type = try (each.value.domain_type, "vmmDomain")
  resolution_immediacy = try (each.value.resolution_immediacy, "immediate")
  depends_on = [
#    mso_schema.schema,
#    mso_schema_site.schema_site1,
    mso_schema_template_anp.anps,
#    mso_schema_template_bd.bds,
#    mso_schema_template_vrf.vrfs,
    mso_schema_template_anp_epg.epgs,
    aci_vmm_domain.vmm_domain,
  ] 
}

resource "mso_schema_template_filter_entry" "filter_entry" {
  for_each = var.filters
  schema_id = mso_schema.schema.id
  template_name = var.template_name
  name = each.value.name
  display_name = each.value.display_name
  entry_name = each.value.entry_name
  entry_display_name = each.value.entry_display_name
  ether_type = each.value.ether_type
  ip_protocol = each.value.ip_protocol
  stateful = each.value.stateful
#  depends_on = [
#    mso_schema.schema
#  ]
}

resource "mso_schema_template_contract" "template_contract" {
  for_each = var.contracts
  schema_id = mso_schema.schema.id
  template_name = var.template_name
  contract_name = each.value.contract_name
  display_name = each.value.display_name
  filter_type = each.value.filter_type
  scope = each.value.scope
  filter_relationships = each.value.filter_relationships
  directives = each.value.directives
  depends_on = [
#    mso_schema.schema,
    mso_schema_template_filter_entry.filter_entry
  ]
}

resource "mso_schema_template_anp_epg_contract" "anp_epg_contract_provider" {
  for_each = var.contracts
  schema_id = mso_schema.schema.id
  template_name = var.template_name
  anp_name = each.value.anp_epg_provider.anp_name
  epg_name = each.value.anp_epg_provider.epg_name
  contract_name = each.value.contract_name
  relationship_type = "provider"
  depends_on = [
#    mso_schema.schema,
    mso_schema_template_contract.template_contract,
    mso_schema_template_anp_epg.epgs,
    mso_schema_template_anp.anps
  ]
}

resource "mso_schema_template_anp_epg_contract" "anp_epg_contract_consumer" {
  for_each = var.contracts
  schema_id = mso_schema.schema.id
  template_name = var.template_name
  anp_name = each.value.anp_epg_consumer.anp_name
  epg_name = each.value.anp_epg_consumer.epg_name
  contract_name = each.value.contract_name
  relationship_type = "consumer"
  depends_on = [
#    mso_schema.schema,
    mso_schema_template_contract.template_contract,
    mso_schema_template_anp_epg.epgs,
    mso_schema_template_anp.anps,
    mso_schema_template_anp_epg_contract.anp_epg_contract_provider
  ]
}

resource "mso_schema_template_l3out" "l3out" {
  for_each = var.l3outs
  schema_id = mso_schema.schema.id
  template_name = var.template_name
  l3out_name = each.value.name
  display_name = each.value.name
  vrf_name = each.value.vrf_name
  depends_on = [
#    mso_schema.schema,
    mso_schema_template_vrf.vrfs,
  ]
}


resource "mso_schema_template_external_epg" "ext_epg" {
  for_each = var.l3outs
  schema_id = mso_schema.schema.id
  template_name = var.template_name
  external_epg_name = format( "%s%s", each.value.name,"-extepg")
  display_name = format ("%s%s", each.value.name, "-extepg")
  vrf_name = each.value.vrf_name
  l3out_name = each.value.name
  depends_on = [
#    mso_schema.schema,
    mso_schema_template_vrf.vrfs,
    mso_schema_template_l3out.l3out,
  ]
}

/*
resource "mso_schema_template_external_epg_subnet" "ext_subnet" {
  for_each = {
    for subnet in local.l3out_subnets : "${subnet.l3out_name}.${subnet.l3out_subnet}" => subnet
  }
  schema_id = mso_schema.schema.id
  template_name = var.template_name
  external_epg_name = format( "%s%s", each.value.l3out_name,"-extepg")
  ip = each.value.l3out_subnet
  scope = each.value.l3out_scope
  depends_on = [
    mso_schema.schema,
    mso_schema_template_vrf.vrfs,
    mso_schema_template_l3out.l3out,
    mso_schema_template_external_epg.ext_epg,
  ]
}
*/

/*
module "dvsuplink" {
  source = "./modules/dvsuplink"
  for_each = var.vmm_vmware
  name = each.value.name
  vcenter_datacenter_name = each.value.vcenter_datacenter_name
  esxi_hosts = each.value.esxi_hosts
  esxi_network_interfaces = each.value.esxi_network_interfaces
}
*/

