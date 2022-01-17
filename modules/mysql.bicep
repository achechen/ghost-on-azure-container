targetScope = 'resourceGroup'

@minLength(3)
@maxLength(63)
@description('Name of the mysql server')
param mysqlServerName string

@allowed([
  'B_Gen5_1'
  'B_Gen5_2'
])
@description('SKU of the mysql server')
param mysqlServerSku string

@description('DB administrator username')
param dbAdminUser string

@secure()
@description('DB administrator password')
param dbAdminPassword string

@description('Location of the mysql server')
param location string = resourceGroup().location

resource mysqlServer 'Microsoft.DBforMySQL/servers@2017-12-01' = {
  name: mysqlServerName
  location: location
  sku: {
    name: mysqlServerSku
    tier: 'Basic'
  }
  properties: {
    createMode: 'Default'
    version: '5.7'
    sslEnforcement: 'Enabled'
    minimalTlsVersion: 'TLS1_2'
    administratorLogin: dbAdminUser
    administratorLoginPassword: dbAdminPassword
  }
}

resource firewallRules 'Microsoft.DBforMySQL/servers/firewallRules@2017-12-01' = {
  name: 'AllowAzureIPs'
  parent: mysqlServer
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

output mysqlServerName string = mysqlServer.name
output mysqlServerFqdn string = mysqlServer.properties.fullyQualifiedDomainName
