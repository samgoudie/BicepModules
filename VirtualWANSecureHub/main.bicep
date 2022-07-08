param location string = resourceGroup().location

@description('Availability zone numbers e.g. 1,2,3.')
param availabilityZones array = [
  '1'
  '2'
  '3'
]

var virtualHubSubnetPrefix = '10.10.0.0/23'
var virtualHubName = 'Hub-NE'
var azfwName = 'testAZFWHub'
var virtualWANName = 'TestVWANAZFW'

resource azfwTestVWan 'Microsoft.Network/virtualWans@2021-08-01' = {
  name: virtualWANName
  location: location
  properties:{
    type: 'Standard'
  }
}

resource virtualHub 'Microsoft.Network/virtualHubs@2021-08-01' = {
  name: virtualHubName
  location: location
  properties:{
    addressPrefix: virtualHubSubnetPrefix
    virtualWan: {
      id: azfwTestVWan.id
    }
  }
}

resource azfw 'Microsoft.Network/azureFirewalls@2021-08-01' = {
  name: azfwName
  location: location
  zones: ((length(availabilityZones) == 0) ? json('null') : availabilityZones)
  properties: {
    sku: {
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
