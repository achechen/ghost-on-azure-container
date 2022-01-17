targetScope = 'resourceGroup'

@description('URL of the container registry where the Ghost container is stored')
param containerRegistryUrl string

@description('FQDN of the MySQL server')
param dbServerFqdn string

@description('Ghost DB name')
param dbName string

@description('Ghost DB username')
param dbUser string

@description('Ghost DB password secret URI')
param dbSecretUri string

@description('Website URL')
param siteUrl string

@description('Existing Web App Name')
param webAppName string

@description('Location of the mount point within the container where the fileshare will be mounted')
param mountPoint string

resource existingWebApp 'Microsoft.Web/sites@2021-02-01' existing = {
  name: webAppName
}

resource webAppMiscSettings 'Microsoft.Web/sites/config@2021-02-01' = {
  parent: existingWebApp
  name: 'appsettings'
  properties: {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE: 'false'
    DOCKER_REGISTRY_SERVER_URL: containerRegistryUrl
    NODE_ENV: 'production'
    GHOST_CONTENT: mountPoint
    paths__contentPath: mountPoint
    privacy_useUpdateCheck: 'false'
    url: siteUrl
    database__client: 'mysql'
    database__connection__host: dbServerFqdn
    database__connection__user: dbUser
    database__connection__password: '@Microsoft.KeyVault(SecretUri=${dbSecretUri})'
    database__connection__database: dbName
    database__connection__ssl: 'true'
    database__connection__ssl_minVersion: 'TLSv1.2'
  }
}
