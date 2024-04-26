<a href="https://fullstory.com"><img src="https://github.com/fullstorydev/terraform-snowflake-fullstory-warehouse-setup/blob/main/assets/fs-logo.png?raw=true"></a>

# terraform-snowflake-fullstory-warehouse-setup

[![GitHub release](https://img.shields.io/github/release/fullstorydev/terraform-snowflake-fullstory-warehouse-setup.svg)](https://github.com/fullstorydev/terraform-snowflake-fullstory-warehouse-setup/releases/)

This module creates all the proper roles, users, grants, and storage integrations so that Fullstory can connect to the database and load data. For more information checkout [this KB article](https://help.fullstory.com/hc/en-us/articles/6295349250199-Snowflake).

This module **does not** create a reader role that can be used to view the data. To query the data inside Snowflake, you should create a role capable of reading the proper tables and columns according to your policies.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_snowflake"></a> [snowflake](#requirement\_snowflake) | >= 0.83.1 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_database_name"></a> [database\_name](#input\_database\_name) | The name of the Snowflake database to use | `string` | n/a | yes |
| <a name="input_fullstory_cidr_ipv4"></a> [fullstory\_cidr\_ipv4](#input\_fullstory\_cidr\_ipv4) | The CIDR block that Fullstory will use to connect to the Redshift cluster. | `string` | `""` | no |
| <a name="input_fullstory_data_center"></a> [fullstory\_data\_center](#input\_fullstory\_data\_center) | The data center where your Fullstory account is hosted. Either 'NA1' or 'EU1'. See https://help.fullstory.com/hc/en-us/articles/8901113940375-Fullstory-Data-Residency for more information. | `string` | `"NA1"` | no |
| <a name="input_fullstory_storage_allowed_locations"></a> [fullstory\_storage\_allowed\_locations](#input\_fullstory\_storage\_allowed\_locations) | The list of allowed locations for the storage provider. This is an advanced option and should only be changed if instructed by Fullstory. Ex. <cloud>://<bucket>/<path>/ | `list(string)` | <pre>[<br>  "gcs://fullstoryapp-warehouse-sync-bundles"<br>]</pre> | no |
| <a name="input_fullstory_storage_provider"></a> [fullstory\_storage\_provider](#input\_fullstory\_storage\_provider) | The storage provider to use. Either 'S3', 'GCS' or 'AZURE'. This is an advanced option and should only be changed if instructed by Fullstory. | `string` | `"GCS"` | no |
| <a name="input_suffix"></a> [suffix](#input\_suffix) | The suffix to append to the names of the resources created by this module so that the module can be instantiated many times. Must only contain letters. | `string` | n/a | yes |
| <a name="input_warehouse_name"></a> [warehouse\_name](#input\_warehouse\_name) | The name of the Snowflake warehouse to use. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gcs_storage_integration"></a> [gcs\_storage\_integration](#output\_gcs\_storage\_integration) | The name of the GCS storage integration that can be used in the Fullstory app when configuring the Snowflake integration. |
| <a name="output_password"></a> [password](#output\_password) | The Fullstory password that can be used in the Fullstory app when configuring the Snowflake integration. |
| <a name="output_role"></a> [role](#output\_role) | The Fullstory role that can be used in the Fullstory app when configuring the Snowflake integration. |
| <a name="output_username"></a> [username](#output\_username) | The Fullstory username that can be used in the Fullstory app when configuring the Snowflake integration. |

## Usage

```hcl
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
```

### Creating a READER role
This module **does not** create a READER role. You can use the following example to create a READER role that will allow a user to use and read all objects _and_ all future objects in the database.
```hcl
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
```
<!-- END_TF_DOCS -->

## Obtaining the output

This module outputs the role, username, password and storage integration that can be pasted into Fullstory in order for Fullstory to connect to your database. After using this module, you must output the value of these variables in your root module ([see above example](#usage)). Once that is done, you should be able to access outputs with

```bash
terraform output <name of your output varible> | pbcopy
```

The `password` output is a sensitive value. You need to use a slighly different command in order to see it.

```bash
terraform output -raw <name of your output varible> | pbcopy
```

Alternatively, you can find all of the inputs in your Snowflake account.

## Contributing

See [CONTRIBUTING.md](https://github.com/fullstorydev/terraform-snowflake-fullstory-warehouse-setup/blob/main/.github/CONTRIBUTING.md) for best practices and instructions on setting up your dev environment.
