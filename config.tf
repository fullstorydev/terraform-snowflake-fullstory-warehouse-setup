terraform {
  required_version = ">= 0.13"

  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.83.1"
      configuration_aliases = [
        snowflake.account_admin,
        snowflake.security_admin,
        snowflake.sys_admin,
      ]
    }
  }
}
