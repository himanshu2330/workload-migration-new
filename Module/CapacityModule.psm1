function Get-Capacity {
    param (
        [Parameter(Mandatory = $true)] [PSCustomObject[]] $Server,
        [Parameter(Mandatory = $false)] [String] $Environment,
        [Parameter(Mandatory = $true)] [PSCredential] $Credential,
        [Parameter(Mandatory = $true)] [Int16] $CpuOverCommit,
        [Parameter(Mandatory = $true)] [Int16] $MemoryOverCommit,
        [Parameter(Mandatory = $true)] [Int16] $TemplateCpu,
        [Parameter(Mandatory = $true)] [Int16] $TemplateMemory,
        [Parameter(Mandatory = $false)] [Double] $BufferHosts = 0.0
    )

    begin {
        $currentDate = Get-Date
        $startDate = $currentDate.AddDays(-2)
        $endDate = $currentDate.AddDays(-1)
        $lineRecords = @()
    }

    process {

        foreach ($s in $Server) {
            $domainName = $s.Name.Split(".", 2)[1]

            switch ($domainName) {
                "domain1.com" { $network = "Network1"; break }
                "domain2.com" { $network = "Network2"; break }
                default { $network = "Other" }
            }
          
            Connect-VIServer -Server $s.Name -Credential $Credential | Out-Null
            $computeClusters = foreach ($clusterLocation in $S.ClusterLocations) {
                Get-Cluster -Server $s.Name -Name $clusterLocation.Name | Sort-Object -Property Name
            }

            foreach ($computeCluster in $computeClusters) {
                $clusterType = ($s.ClusterLocations | Where-Object { $_.Name -eq $computeCluster.Name }).Type
                $clusterStatus = "Provisioning"
                $vmHosts = Get-VMHost -Location $computeCluster
                $hostCount = $vmHosts.Count

                if ($hostCount -eq 0) {
                    continue
                }

                [Double] $totalCpu = ($vmHosts | Measure-Object -Property NumCpu -Sum).Sum
                [Double] $totalMemoryGB = ($vmHosts | Measure-Object -Property MemoryTotalGB -Sum).Sum
                $totalCpuOvercommit = $totalCpu * $CpuOverCommit
                $totalMemoryOvercommitGB = $totalMemoryGB * $MemoryOverCommit
                $bufferCpu = ($totalCpuOvercommit / $hostCount) * $BufferHosts
                $bufferMemoryGB = ($totalMemoryOvercommitGB / $hostCount) * $BufferHosts

                $vms = Get-VM -Location $computeCluster | Where-Object { $_.PowerState -eq "PoweredOn" }
                $vmCount = $vms.Count
                [Double] $totalAllocatedCpu = ($vms | Measure-Object -Property NumCpu -Sum).Sum
                [Double] $totalAllocatedMemoryGB = ($vms | Measure-Object -Property MemoryGB -Sum).Sum

                $totalRemainingCpu = $totalCpuOvercommit - $totalAllocatedCpu - $bufferCpu
                $totalRemainingMemoryGB = $totalMemoryOvercommitGB - $totalAllocatedMemoryGB - $bufferMemoryGB

                if ($vmCount -eq 0) {
                    $averageVMCpu = $TemplateCpu
                    $averageVMMemoryGB = $TemplateMemory
                }
                else {
                    $averageVMCpu = ($totalAllocatedCpu / $vmCount)
                    $averageVMMemoryGB = ($totalAllocatedMemoryGB / $vmCount)
                }

                $vmCpuHeadroom = ($totalRemainingCpu / $averageVMCpu)
                $vmMemoryHeadroom = ($totalRemainingMemoryGB / $averageVMMemoryGB)

                $allocatedCpuPercentage = ($totalAllocatedCpu / $totalCpuOvercommit) * 100
                $allocatedMemoryPercentage = ($totalAllocatedMemoryGB / $totalMemoryOvercommitGB) * 100
                [Double] $averageUtilizedCpu = (Get-Stat -Entity $vmHosts -Start $startDate -Finish $endDate -Stat "cpu.usage.average" | Measure-Object -Property Value -Average).Average
                [Double] $averageUtilizedMemory = (Get-Stat -Entity $vmHosts -Start $startDate -Finish $endDate -Stat "mem.usage.average" | Measure-Object -Property Value -Average).Average

                if ($vmCpuHeadroom -lt $vmMemoryHeadroom) {
                    $vmHeadroom = $vmCpuHeadroom
                }
                else {
                    $vmHeadroom = $vmMemoryHeadroom
                }

                if (($vmHeadroom -le 0) -or
                    ($averageUtilizedCpu -gt 80) -or
                    ($averageUtilizedMemory -gt 80)) {
                    $clusterStatus = "Closed"
                }

                $datastores = Get-Datastore -RelatedObject $computeCluster
                $datastoreCount = 0
                $remainingStorageTB = 0.0
                $totalStorageTB = 0.0
                $largestFreeDatastore = "NA"
                $maximumFreeStorageTB = 0.0

                foreach ($datastore in $datastores) {
                    if ($datastore.Name.Contains("local") -or $datastore.Name.Contains("ISOImages")) {
                        continue
                    }
                    else {
                        $datastoreCount++
                        $totalStorageTB = $totalStorageTB + ($datastore.CapacityGB)
                        $remainingStorageTB = $remainingStorageTB + ($datastore.FreeSpaceGB)
                        if (($datastore.FreeSpaceGB) -gt $maximumFreeStorageTB) {
                            $largestFreeDatastore = $datastore.Name
                            $maximumFreeStorageTB = ($datastore.FreeSpaceGB)
                        }
                    }
                }

                $usedStorageTB = $totalStorageTB - $remainingStorageTB

                if ($totalStorageTB -eq 0) {
                    $usedStoragePercentage = 0
                }
                else {
                    $usedStoragePercentage = ($usedStorageTB / $totalStorageTB) * 100
                }
           
                $lineRecord = [PSCustomObject]@{
                    Date                       = $currentDate.ToString('MM/dd/yyyy')
                    vCenter                    = $s.Name
                    Network                    = $network
                    ComputeCluster             = $computeCluster.Name
                    ClusterType                = $clusterType
                    ClusterStatus              = $clusterStatus
                    HostCount                  = $hostCount
                    TotalCPU                   = $totalCpu
                    TotalCPUOC                 = $totalCpuOvercommit
                    TotalMemory                = $totalMemoryGB.ToString('F')
                    TotalMemoryOC              = $totalMemoryOvercommitGB.ToString('F')
                    VMCount                    = $vmCount
                    TotalAllocatedCPU          = $totalAllocatedCpu
                    TotalAllocatedMemory       = $totalAllocatedMemoryGB.ToString('F')
                    TotalRemainingCPU          = $totalRemainingCpu
                    TotalRemainingMemory       = $totalRemainingMemoryGB.ToString('F')
                    AllocatedCPUPercentage     = $allocatedCpuPercentage.ToString('F')
                    AllocatedMemoryPercentage  = $allocatedMemoryPercentage.ToString('F')
                    AverageUtilizedCPU         = $averageUtilizedCpu.ToString('F')
                    AverageUtilizedMemory      = $averageUtilizedMemory.ToString('F')
                    AverageVMCPU               = $averageVMCpu.ToString('F')
                    AverageVMMemory            = $averageVMMemoryGB.ToString('F')
                    VMCPUHeadroom              = $vmCpuHeadroom.ToString('F0')
                    VMMemoryHeadroom           = $vmMemoryHeadroom.ToString('F0')
                    VMHeadroom                 = $vmHeadroom.ToString('F0')
                    DatastoreCount             = $datastoreCount
                    TotalStorageTB             = $totalStorageTB.ToString('F')
                    TotalUsedStorageTB         = $usedStorageTB.ToString('F')
                    TotalRemainingStorage      = $remainingStorageTB.ToString('F')
                    TotalUsedStoragePercentage = $usedStoragePercentage.ToString('F')
                    LargestFreeDatastore       = $largestFreeDatastore
                    MaximumFreeStorageTB       = $maximumFreeStorageTB.ToString('F')
                }

                $lineRecords += $lineRecord
            }

        }
        
    }
    
    end {
        Disconnect-VIServer -Server * -Confirm:$false
        return $lineRecords
    }
}
