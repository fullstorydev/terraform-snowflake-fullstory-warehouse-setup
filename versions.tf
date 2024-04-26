terraform {
  required_version = ">= 0.13"

  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = ">= 0.83.1"
    }
  }
}
