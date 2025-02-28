Start-Transcript -Path C:\tmp\mssql_cleanup.log

# Deleting Azure Arc Data Controller namespace and it's resources (SQLMI incl.)
Start-Process PowerShell {for (0 -lt 1) {kubectl get pod -n $env:ARC_DC_NAME; sleep 5; clear }}
azdata arc sql mi delete --name $env:MSSQL_MI_NAME
azdata arc dc delete --name $env:ARC_DC_NAME --namespace $env:ARC_DC_NAME --yes

# az login --service-principal --username $env:SPN_CLIENT_ID --password $env:SPN_CLIENT_SECRET --tenant $env:SPN_TENANT_ID --output none // Will be uncomment upon "Directly Connected" functionality restore 
# az resource delete -g $env:resourceGroup -n $env:ARC_DC_NAME --namespace "Microsoft.AzureArcData" --resource-type "dataControllers" // Will be uncomment upon "Directly Connected" functionality restore

# Restoring Azure Data Studio settings
Write-Host "Restoring Azure Data Studio settings"
Stop-Process -Name azuredatastudio
$settingsFile = "C:\Users\$env:adminUsername\AppData\Roaming\azuredatastudio\User\settings.json"
Remove-Item $settingsFile -Force
Remove-Item "C:\tmp\sql_instance_list.txt"

Stop-Transcript

Stop-Process -Name powershell -Force
