// Resource group region
param resourceGroupLocation string = resourceGroup().location

// Networking Params
@description('Name of your Virtual Network (VNet)')
param vnetName string = 'subnets-lab'

@description('Name of the public subnet')
param publicSubnetName string = 'public-subnet'

@description('Name of the public subnet network security group')
param publicSGName string = 'public-sg'

@description('Name of the private subnet')
param privateSubnetName string = 'private-subnet'

@description('Name of the private subnet network security group')
param privateSGName string = 'private-sg'

// Virtual Machine Params
@description('Name of the Virtual Machine deployed to your public subnet')
param publicVMName string = 'public-vm'

@description('Name of the Virtual Machine deployed to your private subnet')
param privateVMName string = 'private-vm'

@description('Username for the Virtual Machines')
param adminUser string = 'azureuser'

@description('SSH Key for the Virtual Machine.')
@secure()
param adminPasswordOrKeyPath string

@description('Unique DNS Name for the Public IP used to access the Virtual Machine.')
param dnsLabelPrefix string = toLower('${publicVMName}-${uniqueString(resourceGroup().id)}')

@description('The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.')
@allowed([
  'Ubuntu-1804'
  'Ubuntu-2004'
  'Ubuntu-2204'
])
param ubuntuOSVersion string = 'Ubuntu-2004'

@description('The size of the VM')
param vmSize string = 'Standard_B1s'

var imageReference = {
  'Ubuntu-1804': {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '18_04-lts-gen2'
    version: 'latest'
  }
  'Ubuntu-2004': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-focal'
    sku: '20_04-lts-gen2'
    version: 'latest'
  }
  'Ubuntu-2204': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-jammy'
    sku: '22_04-lts-gen2'
    version: 'latest'
  }
}
var publicIPAddressName = '${publicVMName}PublicIP'
var publicNetworkInterfaceName = '${publicVMName}NetInt'
var privateNetworkInterfaceName = '${privateVMName}NetInt'
var osDiskType = 'Standard_LRS'
var publicSubnetAddressPrefix = '10.0.0.0/27'
var privateSubnetAddressPrefix = '10.0.0.32/27'
var vnetAddressPrefix = ['10.0.0.0/26']
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUser}/.ssh/authorized_keys'
        keyData: adminPasswordOrKeyPath
      }
    ]
  }
}

/**
  Networking Resources
*/
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: vnetName
  location: resourceGroupLocation
  properties: {
    addressSpace: {
      addressPrefixes: vnetAddressPrefix
    }
  }
}

resource publicSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' = {
  parent: virtualNetwork
  name: publicSubnetName
  properties: {
    addressPrefix: publicSubnetAddressPrefix
  }
}

resource publicSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: publicSGName
  location: resourceGroupLocation
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1010
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource privateSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' = {
  parent: virtualNetwork
  name: privateSubnetName
  properties: {
    addressPrefix: privateSubnetAddressPrefix
    networkSecurityGroup: {
      id: privateSecurityGroup.id
    }
  }
}

resource privateSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: privateSGName
  location: resourceGroupLocation
  properties: {
    securityRules: [
      {
        name: 'DenyVnetInbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: publicIPAddressName
  location: resourceGroupLocation
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
    idleTimeoutInMinutes: 4
  }
  sku: {
    name: 'Basic'
  }
}

/**
  Virtual Machine Resources
*/
resource publicNetworkInterface 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: publicNetworkInterfaceName
  location: resourceGroupLocation
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: publicSubnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
  }
}

resource publicUbuntuVM 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: publicVMName
  location: resourceGroupLocation
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: publicVMName
      adminUsername: adminUser
      adminPassword: adminPasswordOrKeyPath
      linuxConfiguration: linuxConfiguration
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: imageReference[ubuntuOSVersion]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: publicNetworkInterface.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

resource privateNetworkInterface 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: privateNetworkInterfaceName
  location: resourceGroupLocation
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: privateSubnet.id
          }
        }
      }
    ]
  }
}

resource privateUbuntuVM 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: privateVMName
  location: resourceGroupLocation
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: privateVMName
      adminUsername: adminUser
      adminPassword: adminPasswordOrKeyPath
      linuxConfiguration: linuxConfiguration
    }
    storageProfile: {
      imageReference: imageReference[ubuntuOSVersion]
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: privateNetworkInterface.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

/**
  Outputs
*/
output adminUsername string = adminUser
output hostname string = publicIP.properties.dnsSettings.fqdn
output sshCommand string = 'ssh -i .ssh/id_rsa ${adminUser}@${publicIP.properties.dnsSettings.fqdn}'
