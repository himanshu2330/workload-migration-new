Import-Module -Name ./Module/VMMigrateModule -Force

$workingDirectory = "./"
$reportDirectory = "./Reports"

$paramsLists = Get-Content "${workingDirectory}/Parameter/parameters.json" | ConvertFrom-Json

$DestUser = $paramsLists.Dest.server.user
$DestPWord = ConvertTo-SecureString -String $paramsLists.Dest.server.pass -AsPlainText -Force
$DestvcenterCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $DestUser, $DestPWord

$SrcUser = $paramsLists.Src.server.user
$SrcPWord = ConvertTo-SecureString -String $paramsLists.Src.server.pass -AsPlainText -Force
$SrcvcenterCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $SrcUser, $SrcPWord


$ClusterInfo = Get-Content "${reportDirectory}/ClusterInfo.json" | ConvertFrom-Json
$destination = $ClusterInfo.ComputeCluster
$datastore = $ClusterInfo.LargestFreeDatastore
$DstPortGroup = $paramsLists.Src.MigrateVM.DestinationPortGroup

$VMMigrate = VMMigrate -SrcServer $paramsLists.Src.server.Name `
    -DestServer $paramsLists.Dest.server.Name `
    -SrcCredential $SrcvcenterCredential `
    -DestCredential $DestvcenterCredential `
    -MigrateVM $paramsLists.Src.MigrateVM.Name `
    -destination $destination `
    -datastore $datastore `
    -DstPortGroup $DstPortGroup

$VMMigrate | Out-File "${reportDirectory}/VMMigrate.txt"
