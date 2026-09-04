locals {
  fullstory_default_cidr_ip4 = var.fullstory_data_center == "EU1" ? "34.89.210.80/29" : "8.35.195.0/29"
  fullstory_cidr_ipv4        = var.fullstory_cidr_ipv4 != "" ? var.fullstory_cidr_ipv4 : local.fullstory_default_cidr_ip4
  fullstory_cidr_ipv4s       = length(var.fullstory_cidr_ipv4s) > 0 ? var.fullstory_cidr_ipv4s : [local.fullstory_cidr_ipv4]

  suffix = upper(var.suffix)

  storage_integration_name = coalesce(var.stage_name, "FULLSTORY_STAGE_${local.suffix}")
  role_name                = coalesce(var.role_name, "FULLSTORY_WAREHOUSE_SETUP_${local.suffix}")
  user_name                = "FULLSTORY_WAREHOUSE_SETUP_${local.suffix}"
}

provider "snowflake" {
  alias = "account_admin"
}

provider "snowflake" {
  alias = "security_admin"
}

provider "snowflake" {
  alias = "sys_admin"
}

resource "snowflake_account_role" "main" {
  provider = snowflake.security_admin
  name     = local.role_name
}

resource "snowflake_grant_privileges_to_account_role" "database" {
  provider          = snowflake.security_admin
  all_privileges    = true
  account_role_name = snowflake_account_role.main.name
  on_account_object {
    object_type = "DATABASE"
    object_name = var.database_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "warehouse" {
  provider          = snowflake.security_admin
  account_role_name = snowflake_account_role.main.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = var.warehouse_name
  }
}

resource "random_password" "main" {
  count            = var.manage_password ? 1 : 0
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "snowflake_user" "main" {
  provider                       = snowflake.security_admin
  name                           = "FULLSTORY_WAREHOUSE_SETUP_${local.suffix}"
  default_warehouse              = var.warehouse_name
  default_role                   = snowflake_account_role.main.name
  password                       = var.manage_password ? random_password.main[0].result : var.password
  rsa_public_key                 = var.rsa_public_key
  rsa_public_key_2               = var.rsa_public_key_2
  default_secondary_roles_option = "ALL"
  network_policy                 = snowflake_network_policy.main.name
}

resource "snowflake_grant_privileges_to_account_role" "user" {
  provider          = snowflake.security_admin
  account_role_name = snowflake_account_role.main.name
  privileges        = ["MONITOR"]
  on_account_object {
    object_type = "USER"
    object_name = snowflake_user.main.name
  }
}

resource "snowflake_grant_account_role" "main" {
  provider  = snowflake.security_admin
  role_name = snowflake_account_role.main.name
  user_name = snowflake_user.main.name
}

resource "snowflake_storage_integration" "main" {
  provider         = snowflake.account_admin
  name             = local.storage_integration_name
  comment          = "Stage for FullStory data"
  enabled          = true
  storage_provider = var.fullstory_storage_provider

  storage_allowed_locations = var.fullstory_storage_allowed_locations
}

resource "snowflake_grant_privileges_to_account_role" "integration" {
  provider          = snowflake.security_admin
  account_role_name = snowflake_account_role.main.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "INTEGRATION"
    object_name = snowflake_storage_integration.main.name
  }
}

resource "snowflake_network_policy" "main" {
  provider        = snowflake.security_admin
  name            = "FULLSTORY_NETWORK_POLICY_${local.suffix}"
  allowed_ip_list = local.fullstory_cidr_ipv4s
}
