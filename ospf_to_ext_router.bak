# AUTHOR(s): Chris Tung <yitung@cisco.com>

resource "mso_schema_template_l3out" "l3out" {
  for_each = var.l3outs
  schema_id = mso_schema.schema.id
  template_name = mso_schema.schema.template_name
  l3out_name = each.value.l3out_name
  display_name = each.value.l3out_name
  vrf_name = mso_schema_template_vrf.vrfs[each.value.vrf_name].name
}

resource "mso_schema_template_external_epg" "ext_epg" {
  for_each = var.ext_epg
  schema_id = mso_schema.schema.id
  template_name = mso_schema.schema.template_name
  external_epg_name = format( "%s%s", each.value.name,"-extepg")
  display_name = format ("%s%s", each.value.name, "-extepg")
  vrf_name = mso_schema_template_l3out.l3out[each.value.l3out_name].vrf_name
  l3out_name = mso_schema_template_l3out.l3out[each.value.l3out_name].l3out_name
}

locals {
    ext_epg_subnets = flatten ([
    for ext_epg_name, ext_epg in var.ext_epg : [
      for subnet, scope in ext_epg.subnets : {
        ext_epg_name = ext_epg_name
        ext_epg_subnet = subnet
        subnet_scope = scope
      }
    ]
  ])
}

resource "mso_schema_template_external_epg_subnet" "ext_subnet" {
  for_each = {
    for subnet in local.ext_epg_subnets : "${subnet.ext_epg_name}.${subnet.ext_epg_subnet}" => subnet
  }
  schema_id = mso_schema.schema.id
  template_name = mso_schema.schema.template_name
  external_epg_name = mso_schema_template_external_epg.ext_epg[each.value.ext_epg_name].external_epg_name
  ip = each.value.ext_epg_subnet
  scope = each.value.subnet_scope
}


resource "mso_schema_site_bd" "site_bds" {
  for_each = var.l3outs
  schema_id = mso_schema.schema.id
  template_name = mso_schema.schema.template_name
  site_id = mso_schema_site.schema_site1.id
  bd_name = mso_schema_template_bd.bds[each.value.bds.name].name
}

resource "mso_schema_site_bd_l3out" "bd_l3out" {
  for_each = var.l3outs
  schema_id = mso_schema.schema.id
  template_name = mso_schema.schema.template_name
  site_id = mso_schema_site.schema_site1.id
  l3out_name = mso_schema_template_l3out.l3out[each.value.l3out_name].l3out_name
  bd_name = mso_schema_site_bd.site_bds[each.value.l3out_name].bd_name
}


resource "mso_schema_template_deploy" "ospf" {
  schema_id = mso_schema.schema.id
  template_name = mso_schema.schema.template_name
  site_id = mso_schema_site.schema_site1.site_id
  depends_on = [
    mso_schema_site_bd_l3out.bd_l3out,
  ]
}


resource "aci_l3_domain_profile" "l3dom" {
  for_each = var.l3domain
  name = each.value.name
}

resource "aci_attachable_access_entity_profile" "l3domain_aaep" {
  for_each = var.l3domain
  name = each.value.aaep_name
  relation_infra_rs_dom_p = [ aci_l3_domain_profile.l3dom[each.value.name].id ]
}


data "aci_l3_outside" "l3out" {
  for_each = var.l3outs
  tenant_dn = data.aci_tenant.this.id
  name = each.value.l3out_name
  depends_on = [
    mso_schema_template_deploy.ospf,
  ]
}


resource "aci_l3_outside" "l3out" {
  for_each = var.l3outs
  tenant_dn = data.aci_tenant.this.id
  name = each.value.l3out_name
  relation_l3ext_rs_l3_dom_att = aci_l3_domain_profile.l3dom[each.value.l3_domain].id
  depends_on = [
    data.aci_l3_outside.l3out,
  ]
}

resource "aci_l3out_ospf_external_policy" "ospf" {
  for_each = var.l3outs
  l3_outside_dn = aci_l3_outside.l3out[each.value.l3out_name].id
  area_cost = each.value.ospf_area.area_cost
  area_id = each.value.ospf_area.area_id
  area_type = each.value.ospf_area.area_type
} 


resource "aci_logical_node_profile" "lnode" {
  for_each = var.l3outs
  l3_outside_dn = aci_l3_outside.l3out[each.value.l3out_name].id
  name = each.value.l3out_name
}

resource "aci_logical_node_to_fabric_node" "rtrid" {
  for_each = var.l3outs
  logical_node_profile_dn = aci_logical_node_profile.lnode[each.value.l3out_name].id
  tdn = "topology/${each.value.lnodes.pod_name}/node-${each.value.lnodes.leaf_block}"
  rtr_id = each.value.lnodes.rtr_id
  rtr_id_loop_back = "yes"
}

resource "aci_logical_interface_profile" "l_intf_prof" {
  for_each = var.l3outs
  logical_node_profile_dn = aci_logical_node_profile.lnode[each.value.l3out_name].id
  name = replace("${each.value.lnodes.pod_name}-node-${each.value.lnodes.leaf_block}-${each.value.lnodes.interface}", "/", "-")
}

resource "aci_l3out_path_attachment" "l_intf_prof_port" {
  for_each = var.l3outs
  logical_interface_profile_dn = "${aci_logical_interface_profile.l_intf_prof[each.value.l3out_name].id}"
  target_dn = "topology/${each.value.lnodes.pod_name}/paths-${each.value.lnodes.leaf_block}/pathep-[${each.value.lnodes.interface}]"
  if_inst_t = each.value.lnodes.ifInstT
  addr = each.value.lnodes.addr
  encap = try (each.value.lnodes.encap, "unknown")
  mac = each.value.lnodes.mac
}

resource "aci_l3out_ospf_interface_profile" "ospf_if_prof" {
  for_each = var.l3outs
  logical_interface_profile_dn = "${aci_logical_interface_profile.l_intf_prof[each.value.l3out_name].id}"
  auth_key = try ("${each.value.ospf_interface_profile.auth_key}", "1")
}
