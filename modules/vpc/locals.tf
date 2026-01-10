locals {
  # Get list of AZ names in my account - only 3 regions
  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  subnet_types = ["public", "private", "db" ]

  subnet_config = flatten([
    for az_index, az_name in local.azs : [
      for type_index, type_name in local.subnet_types : {
        az_name = az_name
        netnum_offset = (az_index * length(local.subnet_types)) + type_index
        type = type_name
        name_suffix = "${type_name}-${az_index + 1}"
      }
    ]
  ])
}

