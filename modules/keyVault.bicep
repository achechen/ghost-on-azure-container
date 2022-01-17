targetScope = 'resourceGroup'

@description('Key Vault name')
@minLength(3)
@maxLength(24)
param keyVaultName string

@description('Secret name')
@minLength(1)
@maxLength(127)
param keyVaultSecretName string

@description('Secret value')
@secure()
param keyVaultSecretValue string

@description('KeyVault location')
param location string = resourceGroup().location

@description('Service principal ID that has access to secrets')
param servicePrincipalId string

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        objectId: servicePrincipalId
        tenantId: subscription().tenantId
        permissions: {
          secrets: [
            'get'
          ]
        }
      }
    ]
  }
}

resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: keyVaultSecretName
  parent: keyVault
  properties: {
    value: keyVaultSecretValue
  }
}

output dbSecretUri string = keyVaultSecret.properties.secretUri
