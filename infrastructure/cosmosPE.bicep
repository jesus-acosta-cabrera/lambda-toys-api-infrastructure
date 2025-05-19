// Global Params
param location string
param prefix string

// private endpoint specific params
param cosmosAccountId string
param vnetId string
param subnets array

// Cosmos DNS zone
resource cosmosPrivateDNS 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.documents.azure.com'
  location: 'global'
}

// Linking Cosmos DNS to vnet
resource cosmosPrivateDnsNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: cosmosPrivateDNS
  name: '${prefix}-cosmos-dns-link'
  location: 'global'
  properties: {
    registrationEnabled: false // disable vm register to zone aotumatically
    virtualNetwork: {
      id: vnetId // relation to vnet
    }
  }
}

// Creating the Private Endpoint on the cosmos account
resource cosmosPrivateEndpoint 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: '${prefix}-cosmos-pe'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${prefix}-cosmos-pe'
        properties: {
          privateLinkServiceId: cosmosAccountId
          groupIds: [
            'SQL'
          ]
        }
      }
    ]
    subnet: {
      id: subnets[0].id
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
