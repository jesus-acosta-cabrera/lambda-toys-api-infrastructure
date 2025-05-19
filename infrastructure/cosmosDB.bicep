// global parameters
param location string
param prefix string

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

resource sqlDb 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-06-15' = {
  parent: cosmosDbAccount
  name: '${prefix}-sqlDB'
  properties: {
    resource: {
      id: '${prefix}-sqlDB'
    }
    options: {}
  }
}

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

output cosmosAccountId string = cosmosDbAccount.id
