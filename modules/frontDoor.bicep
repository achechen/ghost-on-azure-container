targetScope = 'resourceGroup'

@minLength(5)
@maxLength(64)
@description('Name of the Front Door')
param frontDoorName string

@minLength(1)
@maxLength(128)
@description('Name of the WAF policy')
param wafPolicyName string

@description('Web App name for which Front Door is being configured')
param appServiceWebAppName string

var backendPoolName = '${frontDoorName}-backendPool'
var healthProbeName = '${frontDoorName}-healthProbe'
var frontendEndpointName = '${frontDoorName}-frontendEndpoint'
var loadBalancingName = '${frontDoorName}-loadBalancing'
var routingRuleName = '${frontDoorName}-routingRule'
var frontendEndpointhostName = '${frontDoorName}.azurefd.net'

resource existingWebApp 'Microsoft.Web/sites@2021-02-01' existing = {
  name: appServiceWebAppName
}

resource frontDoor 'Microsoft.Network/frontDoors@2020-05-01' = {
  name: frontDoorName
  location: 'global'
  properties: {
    routingRules: [
      {
        name: routingRuleName
        properties: {
          frontendEndpoints: [
            {
              id: resourceId('Microsoft.Network/frontDoors/frontendEndpoints', frontDoorName, frontendEndpointName)
            }
          ]
          acceptedProtocols: [
            'Http'
            'Https'
          ]
          patternsToMatch: [
            '/*'
          ]
          routeConfiguration: {
            '@odata.type': '#Microsoft.Azure.FrontDoor.Models.FrontdoorForwardingConfiguration'
            forwardingProtocol: 'HttpsOnly'
            backendPool: {
              id: resourceId('Microsoft.Network/frontDoors/backendPools', frontDoorName, backendPoolName)
            }
            cacheConfiguration: {
              queryParameterStripDirective: 'StripNone'
              dynamicCompression: 'Enabled'
            }
          }
          enabledState: 'Enabled'
        }
      }
    ]
    healthProbeSettings: [
      {
        name: healthProbeName
        properties: {
          path: '/'
          protocol: 'Https'
          intervalInSeconds: 120
        }
      }
    ]
    loadBalancingSettings: [
      {
        name: loadBalancingName
        properties: {
          sampleSize: 4
          successfulSamplesRequired: 2
        }
      }
    ]
    backendPools: [
      {
        name: backendPoolName
        properties: {
          backends: [
            {
              address: existingWebApp.properties.defaultHostName
              backendHostHeader: existingWebApp.properties.defaultHostName
              httpsPort: 443
              httpPort: 80
              priority: 1
              enabledState: 'Enabled'
              weight: 50
            }
          ]
          loadBalancingSettings: {
            id: resourceId('Microsoft.Network/frontDoors/loadBalancingSettings', frontDoorName, loadBalancingName)
          }
          healthProbeSettings: {
            id: resourceId('Microsoft.Network/frontDoors/healthProbeSettings', frontDoorName, healthProbeName)
          }
        }
      }
    ]
    frontendEndpoints: [
      {
        name: frontendEndpointName
        properties: {
          hostName: frontendEndpointhostName
          sessionAffinityEnabledState: 'Disabled'
          webApplicationFirewallPolicyLink: {
            id: wafPolicy.id
          }
        }
      }
    ]
    enabledState: 'Enabled'
  }
}

resource wafPolicy 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2020-11-01' = {
  name: wafPolicyName
  location: 'global'
  properties: {
    policySettings: {
      mode: 'Prevention'
      enabledState: 'Enabled'
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'Microsoft_DefaultRuleSet'
          ruleSetVersion: '1.1'
        }
      ]
    }
  }
}

output frontendEndpointHostName string = frontendEndpointhostName
