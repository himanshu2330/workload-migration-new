Import-Module -Name ./Module/CapacityModule -Force
Import-Module -Name ImportExcel -Force


$workingDirectory = "./"
$reportDirectory = "./Reports"

#$currentDate = (Get-Date).ToString('yyyy-MM-dd')
###########################
$paramsLists = Get-Content "${workingDirectory}/Parameter/parameters.json" | ConvertFrom-Json

foreach ($params in $paramsLists.Dest) {

    $reportPath = "${reportDirectory}/$($params.Datacenter)/$($params.Environment)"
    $headroomReportFileName = $params.HeadroomFileName

    $User = $params.server.user
    $PWord = ConvertTo-SecureString -String $params.server.pass -AsPlainText -Force
    $vcenterCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord

 #   $vcenterCredential = Get-StoredCredential -Target "vCenter"
    $capacityData = Get-Capacity -Server $params.Server `
    -Credential $vcenterCredential `
    -CpuOvercommit $params.CpuOverCommit `
    -MemoryOvercommit $params.MemoryOverCommit `
    -TemplateCpu $params.TemplateCpu `
    -TemplateMemory $params.TemplateMemory `
    -BufferHosts $params.BufferHosts
    
    $capacityData | ConvertTo-Json | Out-File "${reportDirectory}/ClusterInfo.json"
    Export-Excel -Path "${reportPath}/${headroomReportFileName}" -InputObject $capacityData  -WorksheetName "ClusterCapacity" -TableStyle Light8  -AutoFilter

}
