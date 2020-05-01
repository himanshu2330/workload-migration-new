Import-Module -Name ./Module/VMinfoModule -Force

$workingDirectory = "./"
$reportDirectory = "./Reports"

$paramsLists = Get-Content "${workingDirectory}/Parameter/parameters.json" | ConvertFrom-Json

$User = $paramsLists.Src.server.user
$PWord = ConvertTo-SecureString -String $paramsLists.Src.server.pass -AsPlainText -Force
$vcenterCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord

$VMInfo = Get-VMInfo -Server $paramsLists.Src.server.Name `
    -Credential $vcenterCredential `
    -MigrateVM $paramsLists.Src.MigrateVM.Name

$VMInfo | ConvertTo-Json -Depth 1 | Out-File "${reportDirectory}\VMInfo.json"
