Configuration Main
{

Param ( 
        [Parameter(Mandatory)]
	  [string] $domainName,
	
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$domainAdminCredentials
	)

Import-DscResource -ModuleName PSDesiredStateConfiguration, xActiveDirectory, xPendingReboot, xStorage, xNetworking, ComputerManagementDSC

[System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($domainAdminCredentials.UserName)", $domainAdminCredentials.Password)

Node localhost
  {
	  LocalConfigurationManager
        {
            ConfigurationMode = 'ApplyAndAutoCorrect'
            RebootNodeIfNeeded = $true
            ActionAfterReboot = 'ContinueConfiguration'
            AllowModuleOverwrite = $true
        }
        
	  WindowsFeature DNS
        {
            Ensure = "Present"
            Name = "DNS"
        }
        
        WindowsFeature DnsTools
        {
            Ensure = "Present"
            Name = "RSAT-DNS-Server"
            DependsOn = "[WindowsFeature]DNS"
        }
 
        WindowsFeature DNS_RSAT
        { 
            Ensure = "Present"
            Name = "RSAT-DNS-Server"
        }
 
        WindowsFeature ADDS_Install 
        { 
            Ensure = 'Present'
            Name = 'AD-Domain-Services'
		DependsOn = "[WindowsFeature]DNS"
        } 
 
        WindowsFeature RSAT_AD_AdminCenter 
        {
            Ensure = 'Present'
            Name   = 'RSAT-AD-AdminCenter'
		DependsOn = "[WindowsFeature]DNS"
        }
 
        WindowsFeature RSAT_ADDS 
        {
            Ensure = 'Present'
            Name   = 'RSAT-ADDS'
		DependsOn = "[WindowsFeature]DNS"
        }
 
        WindowsFeature RSAT_AD_PowerShell 
        {
            Ensure = 'Present'
            Name   = 'RSAT-AD-PowerShell'
        }
 
        WindowsFeature RSAT_AD_Tools 
        {
            Ensure = 'Present'
            Name   = 'RSAT-AD-Tools'
        }
 
        WindowsFeature RSAT_Role_Tools 
        {
            Ensure = 'Present'
            Name   = 'RSAT-Role-Tools'
        }      

        xADDomain CreateForest 
        { 
            DomainName = $domainName           
            DomainAdministratorCredential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds
            DatabasePath = "C:\Windows\NTDS"
            LogPath = "C:\Windows\NTDS"
            SysvolPath = "C:\Windows\Sysvol"
            DependsOn = "[WindowsFeature]ADDS_Install"
        }

  }
}