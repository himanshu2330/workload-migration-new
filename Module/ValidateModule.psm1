function Validate {
    param (
        [Parameter(Mandatory = $true)] [PSCustomObject[]] $VMInfo,
        [Parameter(Mandatory = $true)] [PSCustomObject[]] $ClusterInfo
    )

    begin {
        $currentDate = Get-Date
        $startDate = $currentDate.AddDays(-2)
        $endDate = $currentDate.AddDays(-1)
        $lineRecords = @()
    }

    process {

            $StorageCheck = [float]$ClusterInfo.TotalStorageTB -gt [float]$VMInfo.ProvisionedSpaceGB
            $MemoryCheck = [float]$ClusterInfo.TotalMemoryOC -gt [float]$VMInfo.MemoryGB
            $CPUCheck = [float]$ClusterInfo.TotalCPUOC -gt [float]$VMInfo.NumCpu
            $MaxFreeStorageCheck = [float]$ClusterInfo.MaximumFreeStorageTB -gt [float]$VMInfo.ProvisionedSpaceGB
            $ClusterStatusCheck = $ClusterInfo.ClusterStatus -eq 'Provisioning'

            if($ClusterStatusCheck){
            if($StorageCheck){
                if($MemoryCheck){
                    if($CPUCheck){
                        if($MaxFreeStorageCheck){
                        Write-Output "Validation Completed : SUCCESS, VM : $($VMInfo.Name) Can be Migrated to Target Cluster : $($ClusterInfo.ComputeCluster)" 
                        Write-Output "CPU Required at destination cluster : $($VMInfo.NumCpu), Available CPU  :  $($ClusterInfo.TotalCPUOC)"
                        Write-Output "Memory Required at destination cluster : $($VMInfo.MemoryGB), Available Memory : $($ClusterInfo.TotalMemoryOC)"
                        Write-Output "Storage Required at destination cluster : $($VMInfo.ProvisionedSpaceGB), Available Storage : $($ClusterInfo.TotalStorageTB)"
                        Write-Output "Max storage at single datastore available : $($ClusterInfo.MaximumFreeStorageTB)"
                        }else{
                            Write-Output "*****Max Free Storage at a datastore check failed *****"
                            Write-Output "Max storage at single datastore available : $($MaxFreeStorageCheck)"
                         }
                    }else{
                        Write-Output "*****CPU Check Failed*****" 
                        Write-Output "CPU Required at destination cluster : $($VMInfo.NumCpu), Available CPU  : $($ClusterInfo.TotalCPUOC)";
                     } 
                }else {
                    Write-Output "*****Memory Check Failed*****" 
                    Write-Output "Memory Required at destination cluster : $($VMInfo.MemoryGB), Available Memory : $($ClusterInfo.TotalMemoryOC)";
                 } 
                }else {
                    Write-Output "*****Storage Check Failed*****" 
                    Write-Output "Storage Required at destination cluster : $($VMInfo.ProvisionedSpaceGB), Available Storage : $($ClusterInfo.TotalStorageTB)";
                 } 
            }else {
                    Write-Output "*****Cluster Status Check Failed*****" 
                    Write-Output "Destination cluster status does not allow any new VM provison, ClusterStatus : $($ClusterInfo.ClusterStatus)";
                 }
    }

    end {
       # return $VM
    }
 }

