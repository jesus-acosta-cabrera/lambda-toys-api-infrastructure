// global variables
param location string
param prefix string

// container parameters
param vnet object
param subnets array

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: '${prefix}-la-workspace'
  location: location
  properties: {
    sku: {
      name: 'Standard'
    }
  }
}

resource env 'Microsoft.Web/kubeEnvironments@2024-04-01' = {
  name: '${prefix}-container-env'
  location: location
  properties: {
    internalLoadBalancerEnabled: false
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    containerAppsConfiguration: {
      appSubnetResourceId: '${vnet.outputs.vnetId}/subnets/${subnets[1].name}'
      controlPlaneSubnetResourceId: '${vnet.outputs.vnetId}/subnets/${subnets[2].name}'
    }
  }
}
