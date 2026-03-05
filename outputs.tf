output "role" {
  description = "The Fullstory role that can be used in the Fullstory app when configuring the Snowflake integration."
  value       = snowflake_account_role.main.name
}

output "username" {
  description = "The Fullstory username that can be used in the Fullstory app when configuring the Snowflake integration."
  value       = snowflake_user.main.login_name
}

output "password" {
  description = "The password for the configured user that can be used in the Fullstory app when configuring the Snowflake integration. Will be empty if `manage_password` is false."
  value       = snowflake_user.main.password
  sensitive   = true
}

output "gcs_storage_integration" {
  description = "The name of the GCS storage integration that can be used in the Fullstory app when configuring the Snowflake integration."
  value       = snowflake_storage_integration.main.name
}
