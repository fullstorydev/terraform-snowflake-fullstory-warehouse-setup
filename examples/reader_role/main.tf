resource "snowflake_role" "data_user_role" {
  provider = snowflake.security_admin
  name     = "READER"
}

resource "snowflake_grant_privileges_to_role" "data_user_database" {
  provider  = snowflake.security_admin
  role_name = snowflake_role.data_user_role.name

  privileges = ["USAGE", "MONITOR"]
  on_account_object {
    object_name = "MY_DATABASE"
    object_type = "DATABASE"
  }
}

resource "snowflake_grant_privileges_to_role" "data_user_schema" {
  provider  = snowflake.security_admin
  role_name = snowflake_role.data_user_role.name

  privileges = [
    "USAGE",
    "MONITOR",
  ]
  on_schema {
    all_schemas_in_database = "MY_DATABASE"
  }
}

resource "snowflake_grant_privileges_to_role" "data_user_future_schema" {
  provider  = snowflake.security_admin
  role_name = snowflake_role.data_user_role.name

  privileges = [
    "USAGE",
    "MONITOR",
  ]
  on_schema {
    future_schemas_in_database = "MY_DATABASE"
  }
}

resource "snowflake_grant_privileges_to_role" "data_user_tables" {
  provider  = snowflake.security_admin
  role_name = snowflake_role.data_user_role.name

  privileges = ["SELECT"]
  on_schema_object {
    all {
      object_type_plural = "TABLES"
      in_database        = "MY_DATABASE"
    }
  }
}

resource "snowflake_grant_privileges_to_role" "data_user_future_tables" {
  provider  = snowflake.security_admin
  role_name = snowflake_role.data_user_role.name

  privileges = ["SELECT"]
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_database        = "MY_DATABASE"
    }
  }
}

resource "snowflake_grant_privileges_to_role" "data_user_views" {
  provider  = snowflake.security_admin
  role_name = snowflake_role.data_user_role.name

  privileges = ["SELECT"]
  on_schema_object {
    all {
      object_type_plural = "VIEWS"
      in_database        = snowflake_database.db.name
    }
  }
}

resource "snowflake_grant_privileges_to_role" "data_user_future_views" {
  provider  = snowflake.security_admin
  role_name = snowflake_role.data_user_role.name

  privileges = ["SELECT"]
  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_database        = snowflake_database.db.name
    }
  }
}

resource "snowflake_grant_privileges_to_role" "data_user_mat_views" {
  provider  = snowflake.security_admin
  role_name = snowflake_role.data_user_role.name

  privileges = ["SELECT"]
  on_schema_object {
    all {
      object_type_plural = "MATERIALIZED VIEWS"
      in_database        = snowflake_database.db.name
    }
  }
}


resource "snowflake_grant_privileges_to_role" "data_user_future_mat_views" {
  provider  = snowflake.security_admin
  role_name = snowflake_role.data_user_role.name

  privileges = ["SELECT"]
  on_schema_object {
    future {
      object_type_plural = "MATERIALIZED VIEWS"
      in_database        = snowflake_database.db.name
    }
  }
}
