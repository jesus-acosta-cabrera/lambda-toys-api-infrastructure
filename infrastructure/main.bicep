// global param
param location string
param prefix string

module virtualNetwork 'vnet.bicep' = {
  params: {
    location: location
    prefix: prefix
  }
}

module cosmosDB 'cosmosDB.bicep' = {
  params: {
    location: location
    prefix: prefix
  }
}

module cosmosPE 'cosmosPE.bicep' = {
  params: {
    location: location
    prefix: prefix
    cosmosAccountId: cosmosDB.outputs.cosmosAccountId
    vnetId: virtualNetwork.outputs.vnetId
    subnets: virtualNetwork.outputs.subnets
  }
}

module containerReg 'containerReg.bicep' = {
  params: {
    location: location
    prefix: prefix
  }
}

module container 'container.bicep' = {
  params: {
    location: location
    prefix: prefix
    vnet: virtualNetwork
    subnets: virtualNetwork.outputs.subnets
  }
}
