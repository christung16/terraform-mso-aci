variable "user" {
  description = "Login Information"
  type = map(any)
}

variable "aci_user" {
  type = map(any)
}

variable "vcenter_user" {
  type = map(any)
}

variable "template_name" {
  type = string
}

variable "tenant" {
  type = map(any)
}

variable "schema_name" {
  type = string
}

variable "cdp" {
  type = map(any)
}

variable "lldp" {
  type = map(any)
}

variable "anps" {
  type = map(any)
}

variable "vrfs" {
  type = map(any)
}

variable "bds" {
  type = map(any)
}

variable "epgs" {
  type = map(any)
}

variable "filters" {
  type = map(any)
}

variable "contracts" {
  type = map(any)
}

variable "l3outs" {
  type = map(any)
}

variable "vlan_pool" {
  type = map(any)
}

variable "vmm_vmware" {
  type = map(any)
}

variable "access_port_group_policy" {
  type = map(any)
}

variable "sg" {
  type = map(any)
}
