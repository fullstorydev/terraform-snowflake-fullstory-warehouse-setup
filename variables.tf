variable "database_name" {
  type        = string
  description = "The name of the Snowflake database to use"
}

variable "fullstory_cidr_ipv4" {
  type        = string
  description = "The CIDR block that Fullstory will use to connect to the Redshift cluster."
  default     = ""
}

variable "fullstory_data_center" {
  type        = string
  description = "The data center where your Fullstory account is hosted. Either 'NA1' or 'EU1'. See https://help.fullstory.com/hc/en-us/articles/8901113940375-Fullstory-Data-Residency for more information."
  default     = "NA1"
  validation {
    condition     = var.fullstory_data_center == "NA1" || var.fullstory_data_center == "EU1"
    error_message = "The data center must be either 'NA1' or 'EU1'."
  }
}

variable "fullstory_storage_allowed_locations" {
  type        = list(string)
  description = "The list of allowed locations for the storage provider. This is an advanced option and should only be changed if instructed by Fullstory. Ex. <cloud>://<bucket>/<path>/"
  default     = "gcs://fullstoryapp-warehouse-sync-bundles"
}

variable "fullstory_storage_provider" {
  type        = string
  description = "The storage provider to use. Either 'S3', 'GCS' or 'AZURE'. This is an advanced option and should only be changed if instructed by Fullstory."
  validation {
    condition     = var.storage_provider == "S3" || var.storage_provider == "GCS" || var.storage_provider == "AZURE"
    error_message = "The storage provider must be either 'S3', 'GCS', or 'AZURE'."
  }
  default = "GCS"
}

variable "suffix" {
  type        = string
  description = "The suffix to append to the names of the resources created by this module so that the module can be instantiated many times. Must only contain letters."
  validation {
    condition     = can(regex("^[a-zA-Z]+$", var.suffix))
    error_message = "The suffix must only contain letters."
  }
}

variable "warehouse_name" {
  type        = string
  description = "The name of the Snowflake warehouse to use."
}
