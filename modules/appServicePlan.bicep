targetScope = 'resourceGroup'

@minLength(1)
@maxLength(40)
@description('The name of the App Service Plan')
param appServicePlanName string

@allowed([
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1v2'
  'P2v2'
  'P3v2'
])
@description('Sku of the App Service Plan')
param appServicePlanSku string

@description('App Service Plan location')
param location string = resourceGroup().location

resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: appServicePlanName
  location: location
  kind: 'linux'
  properties: {
    reserved: true
  }
  sku: {
    name: appServicePlanSku
  }
}

output appServicePlanId string = appServicePlan.id
