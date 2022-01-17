targetScope = 'resourceGroup'

@description('Prefix to be prepended to some of the resource names')
param applicationNamePrefix string = 'ghost'

@description('App Service Plan SKU')
param appServicePlanSku string = 'B1'

@description('Storage account SKU')
param storageAccountSku string = 'Standard_LRS'

@description('Location to deploy the resources')
param location string = resourceGroup().location

@description('MySQL server SKU')
param mysqlServerSku string = 'B_Gen5_1'

@description('MySQL server password')
@secure()
param dbAdminPassword string

@description('Ghost container full image name and tag')
param containerImageNameAndTag string = 'ghost:alpine'

@description('Container registry where the image is hosted')
param containerRegistryUrl string = 'https://index.docker.io/v1'


var appServiceWebAppName = '${applicationNamePrefix}-web-${uniqueString(resourceGroup().id)}'
var appServicePlanName = '${applicationNamePrefix}-asp-${uniqueString(resourceGroup().id)}'
var keyVaultName = '${applicationNamePrefix}-kv-${uniqueString(resourceGroup().id)}'
var storageAccountName = '${applicationNamePrefix}stor${uniqueString(resourceGroup().id)}'
var mysqlServerName = '${applicationNamePrefix}-mysql-${uniqueString(resourceGroup().id)}'
var dbUser = 'ghost'
var dbName = 'ghost'
var ghostContentFileShareName = 'contentfiles'
var mountPoint = '/var/lib/ghost/content_files'
var siteUrl = 'https://${frontDoorName}.azurefd.net'
var frontDoorName = '${applicationNamePrefix}-fd-${uniqueString(resourceGroup().id)}'
var wafPolicyName = '${applicationNamePrefix}waf${uniqueString(resourceGroup().id)}'


module storageAccount 'modules/storageAccount.bicep' = {
  name: 'storageAccountDeployment'
  params: {
    storageAccountName: storageAccountName
    storageAccountSku: storageAccountSku
    fileShareName: ghostContentFileShareName
    location: location
  }
}

module keyVault './modules/keyVault.bicep' = {
  name: 'keyVaultDeployment'
  params: {
    keyVaultName: keyVaultName
    keyVaultSecretName: 'dbAdminPassword'
    keyVaultSecretValue: dbAdminPassword
    servicePrincipalId: appServiceWebApp.outputs.principalId
    location: location
  }
}

module appServiceWebApp './modules/appServiceWebApp.bicep' = {
  name: 'webAppDeployment'
  params: {
    appServicePlanId: appServicePlan.outputs.appServicePlanId
    appServiceWebAppName: appServiceWebAppName
    containerImageNameAndTag: containerImageNameAndTag
    fileShareName: storageAccount.outputs.fileShareFullName
    mountPoint: mountPoint
    storageAccountKey: storageAccount.outputs.storageAccountKey
    storageAccountName: storageAccount.outputs.storageAccountName
  }
}

module appServiceWebAppSettings './modules/appServiceWebAppSettings.bicep' = {
  name: 'webAppSettingsDeployment'
  params: {
    containerRegistryUrl: containerRegistryUrl
    dbName: dbName
    dbSecretUri: keyVault.outputs.dbSecretUri
    dbServerFqdn: mysql.outputs.mysqlServerFqdn
    dbUser: dbUser
    mountPoint: mountPoint
    siteUrl: siteUrl
    webAppName: appServiceWebApp.outputs.name
  }
}

module appServicePlan './modules/appServicePlan.bicep' = {
  name: 'appServicePlanDeployment'
  params: {
    appServicePlanName: appServicePlanName
    appServicePlanSku: appServicePlanSku
    location: location
  }
}


module mysql 'modules/mysql.bicep' = {
  name: 'mysqlDeployment'
  params: {
    dbAdminPassword: dbAdminPassword
    dbAdminUser: dbUser
    mysqlServerName: mysqlServerName
    mysqlServerSku: mysqlServerSku
  }
}

module frontDoor 'modules/frontDoor.bicep' = {
  name: 'FrontDoorDeployment'
  params: {
    frontDoorName: frontDoorName
    wafPolicyName: wafPolicyName
    appServiceWebAppName: appServiceWebApp.outputs.name
  }
}

output webAppName string = appServiceWebApp.outputs.name
output webAppPrincipalId string = appServiceWebApp.outputs.principalId
output webAppHostName string = appServiceWebApp.outputs.hostname
output endpointHostName string = frontDoor.outputs.frontendEndpointHostName
