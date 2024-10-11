// define the variables we will use
variable "dbt_account_id" {
  type = number
}

variable "dbt_token" {
  type = string
}

variable "dbt_host_url" {
  type = string
}


// initialize the provider and set the settings
terraform {
  required_providers {
    dbtcloud = {
      source  = "dbt-labs/dbtcloud"
      version = "0.3.13"
    }
  }
}

provider "dbtcloud" {
  account_id = var.dbt_account_id
  token      = var.dbt_token
  host_url   = var.dbt_host_url
}


// create a project
resource "dbtcloud_project" "my_project" {
  name = "sandeep demo"
}


// create a global connection
resource "dbtcloud_global_connection" "my_connection" {
  name       = "sandeep snowflake"
  snowflake  = {  
    account    = "kaycfpk-avb43396"
    database   = "dbt_cloud_db"
    role       = "dbt_cloud_role"
    warehouse  = "dbt_cloud_wh"
  }
}

// link a repository to the dbt Cloud project
// this example adds a github repo for which we know the installation_id but the resource docs have other examples
resource "dbtcloud_repository" "my_repository" {
  project_id             = dbtcloud_project.my_project.id
  remote_url             = "git@github.com:phdata-sandeep/dbt_terraform.git"
  github_installation_id = 9876
  git_clone_strategy     = "github_app"
}

resource "dbtcloud_project_repository" "my_project_repository" {
  project_id    = dbtcloud_project.my_project.id
  repository_id = dbtcloud_repository.my_repository.repository_id
}


// create 2 environments, one for Dev and one for Prod
// here both are linked to the same Data Warehouse connection
// for Prod, we need to create a credential as well
resource "dbtcloud_environment" "my_dev" {
  dbt_version     = "versionless"
  name            = "Dev"
  project_id      = dbtcloud_project.my_project.id
  type            = "development"
  connection_id   = dbtcloud_global_connection.my_connection.id
}

resource "dbtcloud_environment" "my_prod" {
  dbt_version     = "versionless"
  name            = "Prod"
  project_id      = dbtcloud_project.my_project.id
  type            = "deployment"
  deployment_type = "production"
  credential_id   = dbtcloud_snowflake_credential.prod_credential.credential_id
  connection_id   = dbtcloud_global_connection.my_connection.id
}

// we use user/password but there are other options on the resource docs
resource "dbtcloud_snowflake_credential" "prod_credential" {
  project_id  = dbtcloud_project.my_project.id
  auth_type   = "password"
  num_threads = 16
  schema      = "dbt_scm"
  user        = "Sandeep"
  // note, this is a simple example to get Terraform and dbt Cloud working, but do not store passwords in the config for a real productive use case
  // there are different strategies available to protect sensitive input: https://developer.hashicorp.com/terraform/tutorials/configuration-language/sensitive-variables
  password    = "Snowflake@2024$"
}