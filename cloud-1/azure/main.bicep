// Cloud-1 Azure Infrastructure as Code (Bicep)
// Provisions a secure, cost-optimized Ubuntu 22.04 LTS host for Cloud-1 deployment.

@description('Location for all resources.')
param location string = resourceGroup().location

@description('VM Size (e.g. Standard_B1s or Standard_B2s for burstable low cost).')
param vmSize string

@description('Admin username for the Ubuntu VM.')
param adminUsername string = 'azureuser'

@description('SSH RSA Public Key for authentication (Password authentication is disabled).')
@secure()
param adminSshPublicKey string

@description('Admin IPv4 CIDR allowed to access SSH on port 22 (e.g. 198.51.100.25/32).')
param adminAllowedCidr string

@description('Globally unique DNS name label for the Public IP.')
param dnsLabelPrefix string

@description('Storage account type for OS Managed Disk.')
@allowed([
  'Standard_LRS'
  'StandardSSD_LRS'
  'Premium_LRS'
])
param osDiskType string = 'StandardSSD_LRS'

@description('OS Disk size in GB.')
@minValue(30)
param osDiskSizeGB int = 30

var baseName = 'cloud1'
var vnetName = '${baseName}-vnet'
var subnetName = '${baseName}-subnet'
var nsgName = '${baseName}-nsg'
var publicIpName = '${baseName}-pip'
var nicName = '${baseName}-nic'
var vmName = '${baseName}-vm'

// 1. Network Security Group (Enforces 22, 80, 443 with restricted SSH)
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-SSH-Admin-Only'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: adminAllowedCidr
          destinationAddressPrefix: '*'
          description: 'Restricted SSH ingress for administrator'
        }
      }
      {
        name: 'Allow-HTTP-Public'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          description: 'Public HTTP ingress for HTTPS redirect and ACME challenges'
        }
      }
      {
        name: 'Allow-HTTPS-Public'
        properties: {
          priority: 120
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          description: 'Public HTTPS ingress for WordPress and phpMyAdmin'
        }
      }
    ]
  }
}

// 2. Virtual Network & Subnet
resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

// 3. Static Standard Public IP with FQDN
resource publicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

// 4. Network Interface
resource nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
  dependsOn: [
    vnet
  ]
}

// 5. Ubuntu 22.04 LTS Virtual Machine
resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: adminSshPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        name: '${vmName}-osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        diskSizeGB: osDiskSizeGB
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

output vmPublicIP string = publicIp.properties.ipAddress
output vmFqdn string = publicIp.properties.dnsSettings.fqdn
output sshCommand string = 'ssh ${adminUsername}@${publicIp.properties.ipAddress}'
