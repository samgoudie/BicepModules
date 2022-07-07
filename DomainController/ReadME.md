#Run template to deploy new forest  
$RGName = "enterName"
New-AzResourceGroup -Name $RGName
New-AzResourceGroupDeployment -ResourceGroupName $RGName -TemplateFile CreateDomainController.bicep -Verbose
