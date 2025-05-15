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
