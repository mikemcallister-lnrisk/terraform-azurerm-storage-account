resource "random_string" "random" {
  length  = 24
  special = false
  upper   = false
}

resource "azurerm_storage_account" "sa" {
  name                     = (var.name == null ? random_string.random.result : var.name)
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_kind             = var.account_kind
  account_tier             = local.account_tier
  account_replication_type = var.replication_type
  access_tier              = var.access_tier
  tags                     = var.tags

  is_hns_enabled           = var.enable_hns
  large_file_share_enabled = var.enable_large_file_share

  allow_blob_public_access  = var.allow_blob_public_access
  enable_https_traffic_only = var.enable_https_traffic_only
  min_tls_version           = var.min_tls_version
  nfsv3_enabled             = var.nfsv3_enabled
  shared_access_key_enabled = true

  identity {
    type = "SystemAssigned"
  }

  
  dynamic "static_website" {
    for_each = local.static_website_enabled
    content {
      index_document     = var.index_path
      error_404_document = var.custom_404_path
    }
  }

  network_rules {
    default_action             = var.default_network_rule
    ip_rules                   = values(var.access_list)
    virtual_network_subnet_ids = values(var.service_endpoints)
    bypass                     = var.traffic_bypass
  }
}

## azure reference https://docs.microsoft.com/en-us/azure/storage/common/infrastructure-encryption-enable?tabs=portal
resource "azurerm_storage_encryption_scope" "scope" {
  for_each = var.encryption_scopes

  name                               = each.key
  storage_account_id                 = azurerm_storage_account.sa.id
  source                             = "Microsoft.Storage"
  infrastructure_encryption_required = each.value.enable_infrastructure_encryption
}
