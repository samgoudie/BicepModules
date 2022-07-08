param location string = resourceGroup().location

@description('Availability zone numbers e.g. 1,2,3.')
param availabilityZones array = [
  '1'
  '2'
  '3'
]

resource azfwTestVWan 'Microsoft.Network/virtualWans@2021-08-01' = {
  name: 'TestVWANAZFW'
  location: location
  properties:{
    type: 'Standard'
  }
}

resource virtualHub 'Microsoft.Network/virtualHubs@2021-08-01' = {
  name: 'Hub-NE'
  location: location
  properties:{
    addressPrefix: '10.10.0.0/23'
    virtualWan: {
      id: azfwTestVWan.id
    }
  }
}

resource azfw 'Microsoft.Network/azureFirewalls@2021-08-01' = {
  name: 'testAZFWHub'
  location: location
  zones: ((length(availabilityZones) == 0) ? json('null') : availabilityZones)
  properties: {
    additionalProperties: {

    }
    sku: {
      name: 'AZFW_Hub'
      tier: 'Standard'
    }
    hubIPAddresses: {
      publicIPs: {
        count: 1
      }
    }
    virtualHub: {
      id: virtualHub.id
    }
  }
}
