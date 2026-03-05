resource "snowflake_database" "main" {
  name = "MY_DATABASE"
}

resource "snowflake_warehouse" "main" {
  name           = "MY_WAREHOUSE"
  warehouse_size = "small"
  auto_suspend   = 60
}

resource "tls_private_key" "fullstory_user_rsa_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

module "fullstory_warehouse_setup" {
  source  = "fullstorydev/fullstory-warehouse-setup/snowflake"
  version = "~> 1.0"
  providers = {
    snowflake.account_admin  = snowflake.account_admin
    snowflake.security_admin = snowflake.security_admin
    snowflake.sys_admin      = snowflake.sys_admin
  }

  database_name         = snowflake_database.main.name
  warehouse_name        = snowflake_warehouse.main.name
  fullstory_data_center = "NA1"
  rsa_public_key        = tls_private_key.fullstory_user_rsa_key.public_key_pem
  suffix                = "ACME" # This should represent this module's unique identifier
}

output "fullstory_warehouse_setup_role" {
  value = module.fullstory_warehouse_setup.role
}

output "fullstory_warehouse_setup_username" {
  value = module.fullstory_warehouse_setup.username
}

output "fullstory_warehouse_setup_password" {
  value     = module.fullstory_warehouse_setup.password
  sensitive = true
}

output "fullstory_warehouse_setup_private_key" {
  value     = tls_private_key.fullstory_user_rsa_key.private_key_pem
  sensitive = true
}

output "fullstory_warehouse_setup_gcs_storage_integration" {
  value = module.fullstory_warehouse_setup.gcs_storage_integration
}
