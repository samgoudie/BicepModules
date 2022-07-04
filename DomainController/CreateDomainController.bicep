@description('set location for resources to match that of the resource group')
param location string = resourceGroup().location
@description('VM size')
param VMSize string = 'Standard_D2s_v3'
@description('VM Admin username')
param adminUsername string = 'TestAdmin'
@description('VM Admin password')
@secure()
param adminPassword string
@description('VM name')
param VMName string = 'DC1'

@description('Auto-generated token to access _artifactsLocation. Leave it blank unless you need to provide your own value.')
@secure()
param artifactsLocationSasToken string = ''

var addressPrefix = '10.10.0.0/27'
var dcsubnetspace = '10.10.0.0/27'

var storageAccountName = 'bootdiags${uniqueString(resourceGroup().id)}'
var subnetName = 'subnet-dc'
var domainName = 'testdom.local'

resource identityVNET 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: 'VNET-Identity'
  location: location
  properties:{
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets:[
      {
        name: subnetName
        properties:{
          addressPrefix: dcsubnetspace
        }
      }
    ] 
  }

}
resource DC1 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  location: location
  name: 'DC1'
  properties:{
    hardwareProfile: {
      vmSize: VMSize
    }
    diagnosticsProfile:{
      bootDiagnostics: {
        enabled: true
        storageUri: diagSA.properties.primaryEndpoints.blob
      }
    }
    osProfile:{
      computerName: VMName
      adminPassword:adminPassword
      adminUsername:adminUsername
    }
    storageProfile:{
      imageReference:{
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: '17763.3131.220505'
      }
      osDisk: {
        createOption: 'FromImage'
        caching: 'ReadOnly'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile:{
      networkInterfaces:[
        {
          id:vmnic.id
        }
      ]
    }
  }

}
resource diagSA 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
}
resource vmnic 'Microsoft.Network/networkInterfaces@2021-08-01' = {
  name: 'VMNic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet:{
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', identityVNET.name, subnetName)
          }
        }
      }
    ]
  }
  dependsOn: [
    identityVNET
  ]
}
resource DSCCreateForest 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = {
  parent: DC1
  name: 'CreateForest'
  location:location
  properties:{
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.19'
    autoUpgradeMinorVersion: true
    settings: {
      ModulesUrl: uri('https://github.com/samgoudie/BicepModules/blob/main/DomainController/', 'DomainControllerDSC.zip${artifactsLocationSasToken}?raw=true')
      ConfigurationFunction: 'DomainControllerDSC.ps1\\Main'
//      ModulesUrl: uri('https://raw.githubusercontent.com/SMBrook/SQLAOAG/main/', 'DSC/CreateADPDC.zip${artifactsLocationSasToken}')
//      ConfigurationFunction: 'CreateADPDC.ps1\\CreateADPDC'
      Properties: {
        domainName: domainName
        domainAdminCredentials: {
          UserName: 'TestAdmin'
          Password: 'PrivateSettingsRef:adminPassword'
        }
      }
    }
    protectedSettings: {
      Items: {
        AdminPassword: adminPassword
      }
    }
  }
}
