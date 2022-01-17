targetScope = 'resourceGroup'

@minLength(2)
@maxLength(60)
@description('The name of the Web App')
param appServiceWebAppName string

@description('Web App location')
param location string = resourceGroup().location

@description('ID of the App Service Plan')
param appServicePlanId string

@description('The name and tag of the Ghost container image (name:tag)')
param containerImageNameAndTag string

@description('Name of the storage account hosting Ghost content files')
param storageAccountName string

@secure()
@description('Access key of the storage account')
param storageAccountKey string

@description('Name of the file share that hosts Ghost content files')
param fileShareName string

@description('Location of the mount point within the container where the fileshare will be mounted')
param mountPoint string

var containerImage = 'DOCKER|${containerImageNameAndTag}'

resource appServiceWebApp 'Microsoft.Web/sites@2021-02-01' = {
  name: appServiceWebAppName
  location: location
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    clientAffinityEnabled: false
    serverFarmId: appServicePlanId
    httpsOnly: true
    enabled: true
    reserved: true
    siteConfig: {
      minTlsVersion: '1.2'
      httpLoggingEnabled: true
      http20Enabled: true
      ftpsState: 'Disabled'
      linuxFxVersion: containerImage
      alwaysOn: true
      use32BitWorkerProcess: false
      azureStorageAccounts: {
        ContentFilesVolume: {
          type: 'AzureFiles'
          accountName: storageAccountName
          shareName: fileShareName
          mountPath: mountPoint
          accessKey: storageAccountKey
        }
      }
    }
  }
}

resource webAppFrontDoorSecurityAllow 'Microsoft.Web/sites/config@2021-02-01' = {
  parent: appServiceWebApp
  name: 'web'
  properties: {
    ipSecurityRestrictions: [
      {
        ipAddress: 'AzureFrontDoor.Backend'
        action: 'Allow'
        tag: 'ServiceTag'
        priority: 300
        name: 'Access from Azure Front Door'
        description: 'Allow access through Azure Front Door'
      }
    ]
  }
}

output name string = appServiceWebApp.name
output hostname string = appServiceWebApp.properties.hostNames[0]
output principalId string = appServiceWebApp.identity.principalId
