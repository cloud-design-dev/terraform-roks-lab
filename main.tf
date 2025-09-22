module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.3.0"
  existing_resource_group_name = var.existing_resource_group
}

# Generate a random string for the project resources
resource "random_string" "prefix" {
  length  = 4
  special = false
  upper   = false
  numeric = false
}

resource "ibm_is_vpc" "lab" {
  name                        = "${local.prefix}-vpc"
  resource_group              = module.resource_group.resource_group_id
  address_prefix_management   = var.vpc_address_prefix
  default_network_acl_name    = "${local.prefix}-default-vpc-nacl"
  default_security_group_name = "${local.prefix}-default-vpc-sg"
  default_routing_table_name  = "${local.prefix}-default-vpc-rt"
  tags                        = local.tags

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "ibm_is_public_gateway" "zones" {
  count          = length(local.vpc_zones)
  name           = "pgw-${local.vpc_zones[count.index].zone}"
  vpc            = ibm_is_vpc.lab.id
  zone           = local.vpc_zones[count.index].zone
  resource_group = module.resource_group.resource_group_id
  tags           = local.tags
}

resource "ibm_is_subnet" "cluster" {
  count                    = length(local.vpc_zones)
  name                     = "clsuter-subnet-${local.vpc_zones[count.index].zone}"
  vpc                      = ibm_is_vpc.lab.id
  zone                     = local.vpc_zones[count.index].zone
  total_ipv4_address_count = 64
  resource_group           = module.resource_group.resource_group_id
  public_gateway           = ibm_is_public_gateway.zones[count.index].id
  tags                     = local.tags
}

module "cos_module" {
  source            = "terraform-ibm-modules/cos/ibm"
  version           = "10.2.21"
  resource_group_id = module.resource_group.resource_group_id
  region            = var.region
  cos_instance_name = "${local.prefix}-cos"
  create_cos_bucket = false
}

resource "ibm_container_vpc_cluster" "cluster" {
  name                                = "${local.prefix}-roks"
  vpc_id                              = ibm_is_vpc.lab.id
  kube_version                        = "4.18.21_openshift"
  flavor                              = "bx2.4x16"
  worker_count                        = "1"
  entitlement                         = "cloud_pak"
  cos_instance_crn                    = module.cos_module.cos_instance_crn
  resource_group_id                   = module.resource_group.resource_group_id
  disable_outbound_traffic_protection = true

  zones {
    subnet_id = ibm_is_subnet.cluster[0].id
    name      = local.vpc_zones[0].zone
  }

  zones {
    subnet_id = ibm_is_subnet.cluster[1].id
    name      = local.vpc_zones[1].zone
  }

  tags = local.tags
}