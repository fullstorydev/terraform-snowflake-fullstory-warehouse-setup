terraform {
  required_version = ">= 0.13"

  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 2.14"
      configuration_aliases = [
        snowflake.account_admin,
        snowflake.security_admin,
        snowflake.sys_admin,
      ]
    }
  }
}
