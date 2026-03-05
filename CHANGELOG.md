# Changelog

## 1.0.0

### BREAKING CHANGES

- **Provider migration**: Switched from `Snowflake-Labs/snowflake` (~> 0.83.1) to `snowflakedb/snowflake` (~> 2.14). Users must update their provider configuration and run `terraform init -upgrade`.
  - **Resource renames**: The following resources have been renamed to match the new provider's requirements. Existing state must be migrated using `terraform state mv` or resources will be destroyed and recreated:
    - `snowflake_role` → `snowflake_account_role`
    - `snowflake_grant_privileges_to_role` → `snowflake_grant_privileges_to_account_role`
    - `snowflake_role_grants` → `snowflake_grant_account_role`
    - `snowflake_storage_integration` remains `snowflake_storage_integration` (with `storage_provider` attribute)
  - **Attribute changes**:
    - `role_name` → `account_role_name` on grant resources
    - `default_secondary_roles` → `default_secondary_roles_option` on user resource
    - `snowflake_grant_account_role` now uses `user_name` (single string) instead of `users` (list)

### Migration Guide

There are two options for migrating to v1.0.0.

#### Option A: Destroy and Recreate (simpler, but causes downtime)

Due to the provider change from `Snowflake-Labs/snowflake` to `snowflakedb/snowflake`, the simplest migration path is to destroy the old module resources and recreate them with the new version. FullStory will temporarily lose the ability to sync data to your warehouse during this process.

1. **Remove the module block** from your Terraform configuration. For example, remove or comment out:
   ```hcl
   module "fullstory_warehouse_setup" {
     source = "fullstorydev/fullstory-warehouse-setup/snowflake"
     version = "0.2.3" # your current version
     # ...
   }
   ```
2. **Run `terraform plan` and `terraform apply`** to destroy the old module's resources (role, user, grants, storage integration, network policy).
3. **Update your provider configuration** to use `snowflakedb/snowflake` ~> 2.14.
4. **Run `terraform init -upgrade`** to download the new provider.
5. **Add the module block back** with the new version:
   ```hcl
   module "fullstory_warehouse_setup" {
     source  = "fullstorydev/fullstory-warehouse-setup/snowflake"
     version = "~> 1.0"
     # ...
   }
   ```
6. **Run `terraform init -upgrade`, `terraform plan` and `terraform apply`** to download the new module and create the new resources.
7. **Update FullStory** with the new connection details from your Terraform outputs if changed (role, username, key, storage integration).
8. For resources **outside of this module** (e.g., custom grant resources you manage yourself), follow the [Snowflake provider's Migration Guide](https://registry.terraform.io/providers/snowflakedb/snowflake/latest/docs/guides/resource_migration) to migrate to the new resource types.

#### Option B: Manual State Migration (no downtime)

This approach removes the old resources from Terraform state and imports them back under the new resource types, preserving the actual Snowflake objects. No resources are destroyed or recreated in **Snowflake**, so there is no downtime.

> **Note**: In the examples below, replace `module.fullstory_warehouse_setup` with the actual module path in your Terraform configuration, and replace `<SUFFIX>` with your configured suffix value (uppercased).

1. **List existing resources** to identify what needs to be migrated:
   ```bash
   terraform state list | grep fullstory_warehouse_setup
   ```
   You should see resources like:
   ```
   module.fullstory_warehouse_setup.snowflake_role.main
   module.fullstory_warehouse_setup.snowflake_grant_privileges_to_role.database
   module.fullstory_warehouse_setup.snowflake_grant_privileges_to_role.warehouse
   module.fullstory_warehouse_setup.snowflake_grant_privileges_to_role.user
   module.fullstory_warehouse_setup.snowflake_grant_privileges_to_role.integration
   module.fullstory_warehouse_setup.snowflake_role_grants.main
   module.fullstory_warehouse_setup.snowflake_storage_integration.main
   ```

2. **Remove the old resources from state** (this does NOT delete the actual Snowflake objects):
   ```bash
   # Remove the role
   terraform state rm 'module.fullstory_warehouse_setup.snowflake_role.main'

   # Remove all grant_privileges_to_role resources
   terraform state rm 'module.fullstory_warehouse_setup.snowflake_grant_privileges_to_role.database'
   terraform state rm 'module.fullstory_warehouse_setup.snowflake_grant_privileges_to_role.warehouse'
   terraform state rm 'module.fullstory_warehouse_setup.snowflake_grant_privileges_to_role.user'
   terraform state rm 'module.fullstory_warehouse_setup.snowflake_grant_privileges_to_role.integration'

   # Remove the role grants
   terraform state rm 'module.fullstory_warehouse_setup.snowflake_role_grants.main'

   # Remove the storage integration
   terraform state rm 'module.fullstory_warehouse_setup.snowflake_storage_integration.main'
   ```

3. **Update your provider configuration** to use `snowflakedb/snowflake` ~> 2.14, and **update the module version** to `~> 1.0`:
   ```hcl
   module "fullstory_warehouse_setup" {
     source  = "fullstorydev/fullstory-warehouse-setup/snowflake"
     version = "~> 1.0"
     # ...
   }
   ```

4. **Run `terraform init -upgrade`** to download the new provider.

5. **Import the resources back** under the new resource types. The resources still exist in Snowflake and just need to be re-associated with the new Terraform resource names:
   ```bash
   # Import the role (snowflake_role → snowflake_account_role)
   terraform import 'module.fullstory_warehouse_setup.snowflake_account_role.main' '"FULLSTORY_WAREHOUSE_SETUP_<SUFFIX>"'

   # Import grant_privileges_to_account_role resources (snowflake_grant_privileges_to_role → snowflake_grant_privileges_to_account_role)
   # Format: <account_role_name>|<with_grant_option>|<always_apply>|<all_privileges>|<privileges>|<grant_type>|<grant_data>
   terraform import 'module.fullstory_warehouse_setup.snowflake_grant_privileges_to_account_role.database' \
     '"FULLSTORY_WAREHOUSE_SETUP_<SUFFIX>"|false|false|true||OnAccountObject|DATABASE|"<DATABASE_NAME>"'
   terraform import 'module.fullstory_warehouse_setup.snowflake_grant_privileges_to_account_role.warehouse' \
     '"FULLSTORY_WAREHOUSE_SETUP_<SUFFIX>"|false|false|false|USAGE|OnAccountObject|WAREHOUSE|"<WAREHOUSE_NAME>"'
   terraform import 'module.fullstory_warehouse_setup.snowflake_grant_privileges_to_account_role.user' \
     '"FULLSTORY_WAREHOUSE_SETUP_<SUFFIX>"|false|false|false|MONITOR|OnAccountObject|USER|"FULLSTORY_WAREHOUSE_SETUP_<SUFFIX>"'
   terraform import 'module.fullstory_warehouse_setup.snowflake_grant_privileges_to_account_role.integration' \
     '"FULLSTORY_WAREHOUSE_SETUP_<SUFFIX>"|false|false|false|USAGE|OnAccountObject|INTEGRATION|"<STORAGE_INTEGRATION_NAME>"'

   # Import the role grant (snowflake_role_grants → snowflake_grant_account_role)
   # Format: <role_name>|USER|<user_name>
   terraform import 'module.fullstory_warehouse_setup.snowflake_grant_account_role.main' \
     '"FULLSTORY_WAREHOUSE_SETUP_<SUFFIX>"|USER|"FULLSTORY_WAREHOUSE_SETUP_<SUFFIX>"'

   # Import the storage integration
   terraform import 'module.fullstory_warehouse_setup.snowflake_storage_integration.main' '"<STORAGE_INTEGRATION_NAME>"'
   ```

   Where:
   - `<SUFFIX>` is your configured suffix value (uppercased), e.g. `ACME`
   - `<DATABASE_NAME>` is your Snowflake database name
   - `<WAREHOUSE_NAME>` is your Snowflake warehouse name
   - `<STORAGE_INTEGRATION_NAME>` is the storage integration name (defaults to `FULLSTORY_STAGE_<SUFFIX>` unless you set `stage_name`)

6. **Run `terraform plan`** to verify that no changes are needed. The plan should show no major additions or destructions for the migrated resources. If there are minor diffs (e.g., attributes defaults in the new providers, etc.), review and apply them.

7. For resources **outside of this module** (e.g., custom grant resources you manage yourself), follow the [Snowflake provider's Migration Guide](https://registry.terraform.io/providers/snowflakedb/snowflake/latest/docs/guides/resource_migration) to migrate to the new resource types.
