// common parameters
param location string
param prefix string

// vnet parameters
param vnetSettings object = {
  addressPrefixes: ['10.0.0.0/20']
  subnets: [
    {
      name: 'subnet1'
      addressPrefix: '10.0.0.0/22'
    }
  ]
}

resource defaultNSG 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: '${prefix}-default-nsg'
  location: location
  properties: {
    securityRules: []
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  // vnet name prefix + vnet object
  name: '${prefix}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: vnetSettings.addressPrefixes
    }
    // subnet loop on subnet array
    subnets: [
      for subnet in vnetSettings.subnets: {
        name: subnet.name
        properties: {
          addressPrefix: subnet.addressPrefix
          networkSecurityGroup: {
            id: defaultNSG.id
          }
        }
      }
    ]
  }
}

// Cosmos Db account used
resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2021-03-15' = {
  name: '${prefix}-cosmos-account'
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
      }
    ]
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: false
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
  }
}


// db instance
resource sqlDb 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-06-15' = {
  parent: cosmosDbAccount
  name: '${prefix}-sqldb'
  properties: {
    resource: {
      id: '${prefix}-sqldb'
    }
    options: {}
  }
}

// db container
resource sqlContainerName 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-06-15' = {
  parent: sqlDb
  name: '${prefix}-orders'
  properties: {
    resource: {
      id: '${prefix}-orders'
      partitionKey: {
        paths: [
          '/id'
        ]
      }
    }
    options: {}
  }
}

// cosmos DNS
resource cosmosPrivateDNS 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.documents.azure.com' // this is azure DNS zone, we have to look it up on the documentation
  location: 'global' // must be global
}

// Link from Cosmos DNS to vnet
resource cosmosPrivateDnsNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: cosmosPrivateDNS
  name: '${prefix}-cosmos-dns-link'
  location: 'global'
  properties: {
    registrationEnabled: false // disable vm register to zone aotumatically
    virtualNetwork: {
      id: virtualNetwork.id // relation to vnet
    }
  }
}

// Creating actual Private Endpoint
resource cosmosPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: '${prefix}-cosmos-pe'
  location: location // the region for the resource
  properties: {
    privateLinkServiceConnections: [
      {
          name: '${prefix}-cosmos-pe' // any name {unique}
          properties: {
            privateLinkServiceId: cosmosDbAccount.id // CosmosDB linked to
            groupIds: [ // sub resource
              'SQL'
            ]
          }
      }
    ]
    subnet: {
      id: virtualNetwork.properties.subnets[0].id // subnet that the private endpoint is linked to
    }
  }
}

// Link private endpoint to the CosmosDNS
resource cosmosPrivateEndpointDnsLink 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent: cosmosPrivateEndpoint
  name: '${prefix}-cosmos-pe-dns'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink.documents.azure.com'
        properties: {
          privateDnsZoneId: cosmosPrivateDNS.id
        }
      }
    ]
  }
}
