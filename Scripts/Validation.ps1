Import-Module -Name ./Module/ValidateModule -Force

$workingDirectory = "./"
$reportDirectory = "./Reports"

$VMInfo = Get-Content "${reportDirectory}/VMInfo.json" | ConvertFrom-Json 
$ClusterInfo = Get-Content "${reportDirectory}/ClusterInfo.json" | ConvertFrom-Json

$Result = Validate -VMInfo $VMInfo -ClusterInfo $ClusterInfo

$Result | Out-File "${reportDirectory}/result.txt"
