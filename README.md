# BicepModules
$RGName = "enterName"
New-AzResourceGroup -Name $RGName
New-AzResourceGroupDeployment -ResourceGroupName $RGName -TemplateFile CreateDomainController.bicep -Verbose
