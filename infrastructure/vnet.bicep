// global parameters
param location string
param prefix string

// vnet specific param
param vnetSettings object = {
  addressSpace: ['10.0.0.0/20']
  subnets: [
    {
      name: 'subnet1'
      addressPrefix: '10.0.0.0/22'
    }
    {
      name: 'acaAppSubnet'
      addressPrefix: '10.0.4.0/22'
    }
    {
      name: 'acaControlPlaneSubnet'
      addressPrefix: '10.0.8.0/22'
    }
  ]
}

// NSG for subnets
resource defaultNSG 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: '${prefix}-default-nsg'
  location: location
  properties: {
    securityRules: []
  }
}

// vnet creation
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  // name + prefix given
  name: '${prefix}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: vnetSettings.addressSpace
    }
    // obtaining subnets from the array created
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

output vnetId string = virtualNetwork.id
output subnets array = virtualNetwork.properties.subnets
