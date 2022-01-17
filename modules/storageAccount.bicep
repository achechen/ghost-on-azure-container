targetScope = 'resourceGroup'

@minLength(3)
@maxLength(24)
@description('Name of the storage account that will host Ghostcontent files')
param storageAccountName string

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
])
@description('Storage Account SKU')
param storageAccountSku string

@description('File share that will host Ghost content files')
param fileShareName string

@description('Storage account location')
param location string = resourceGroup().location

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountSku
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2021-06-01' = {
  name: 'default'
  parent: storageAccount
}

resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-06-01' = {
  parent: fileServices
  name: fileShareName
}

output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
output fileShareFullName string = fileShare.name
output storageAccountKey string = listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value
