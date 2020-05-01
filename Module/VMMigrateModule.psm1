function VMMigrate {
    param (
        [Parameter(Mandatory = $true)] [PSCustomObject[]] $SrcServer,
        [Parameter(Mandatory = $true)] [PSCustomObject[]] $DestServer,
        [Parameter(Mandatory = $true)] [PSCredential] $SrcCredential,
        [Parameter(Mandatory = $true)] [PSCredential] $DestCredential,
        [Parameter(Mandatory = $true)] [string] $MigrateVM,
        [Parameter(Mandatory = $true)] [string] $destination,
        [Parameter(Mandatory = $true)] [string] $datastore,
        [Parameter(Mandatory = $true)] [string] $DstPortGroup
    )

    begin {
        
    }

    process {
               ####################################################################################
                    # Function GetPortGroupObject
                    function GetPortGroupObject {
                        Param(
                            [Parameter(Mandatory=$True)] [string]$PortGroup
                           # [Parameter(Mandatory = $true)] [PSCustomObject[]] $DestServer
                        )

                        if (Get-VDPortGroup -Name $DstPortGroup -ErrorAction SilentlyContinue) {
                            return Get-VDPortGroup -Name $DstPortGroup -Server $DestServer
                        }
                        else {
                            if (Get-VirtualPortGroup -Name $DstPortGroup -ErrorAction SilentlyContinue) {
                                return Get-VirtualPortGroup -Name $DstPortGroup -Server $DestServer | Select-Object -First 1
                            }
                            else {
                                Write-Host "The PorGroup '$DstPortGroup' doesn't exist in the destination vCenter"
                                exit
                            }
                        }
                    }

                    function Drawline {
                        for($i=0; $i -lt (get-host).ui.rawui.buffersize.width; $i++) {write-host -nonewline -foregroundcolor cyan "-"}
                    }

                    ####################################################################################


            $sourceVCConn = Connect-VIServer -Server $SrcServer -Credential $SrcCredential | Out-Null
            $destVCConn = Connect-VIServer -Server $DestServer -Credential $DestCredential | Out-Null

            $vm = Get-VM $MigrateVM -Server $SrcServer
            $dest = Get-VMHost -Location $destination -Server $DestServer | Select-Object -First 1
            $networkAdapter = Get-NetworkAdapter -VM $MigrateVM -Server $SrcServer
            $destinationPortGroup = GetPortGroupObject -PortGroup $DstPortGroup #-DestServer $DestServer
            $destinationDatastore = Get-Datastore $datastore -Server $DestServer

            $Result = $vm | Move-VM -Destination $dest -NetworkAdapter $networkAdapter -PortGroup $destinationPortGroup -Datastore $destinationDatastore | out-null
            Drawline
            Get-VM $MigrateVM | Get-NetworkAdapter | Select-Object @{N="VM Name";E={$_.Parent.Name}},@{N="Cluster";E={Get-Cluster -VM $_.Parent}},@{N="ESXi Host";E={Get-VMHost -VM $_.Parent}},@{N="Datastore";E={Get-Datastore -VM $_.Parent}},@{N="Network";E={$_.NetworkName}} | Format-List
            
    }

    end {
        Disconnect-VIServer -Server * -Confirm:$false
        return $Result
    }
 }

