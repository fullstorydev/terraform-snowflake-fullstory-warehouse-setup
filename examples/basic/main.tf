resource "snowflake_database" "main" {
  name = "MY_DATABASE"
}

resource "snowflake_warehouse" "main" {
  name           = "MY_WAREHOUSE"
  warehouse_size = "small"
  auto_suspend   = 60
}

module "fullstory_warehouse_setup" {
  source = "fullstorydev/fullstory-warehouse-setup/snowflake"
  providers = {
    snowflake.account_admin  = snowflake.account_admin
    snowflake.security_admin = snowflake.security_admin
    snowflake.sys_admin      = snowflake.sys_admin
  }

  database_name         = snowflake_database.main.name
  warehouse_name        = snowflake_warehouse.main.name
  fullstory_data_center = "NA1"
  suffix                = "ACME" # This should represent this module's unique identifier
}

output "fullstory_warehouse_setup_role" {
  value = module.fullstory_warehouse_setup.role
}

output "fullstory_warehouse_setup_username" {
  value = module.fullstory_warehouse_setup.username
}

output "fullstory_warehouse_setup_password" {
  value = module.fullstory_warehouse_setup.password
}

output "fullstory_warehouse_setup_gcs_storage_integration" {
  value = module.fullstory_warehouse_setup.gcs_storage_integration
}
