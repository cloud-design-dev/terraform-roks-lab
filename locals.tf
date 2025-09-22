locals {
  prefix = random_string.prefix.result
  zones  = min(2, length(data.ibm_is_zones.regional.zones))
  vpc_zones = {
    for zone in range(local.zones) : zone => {
      zone = "${var.region}-${zone + 1}"
    }
  }

  tags = [
    "project:${local.prefix}",
    "workspace:${terraform.workspace}",
    var.owner_tag,
  ]
}
