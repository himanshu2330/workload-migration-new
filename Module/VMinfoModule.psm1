function Get-VMinfo {
    param (
        [Parameter(Mandatory = $true)] [PSCustomObject[]] $Server,
        [Parameter(Mandatory = $true)] [PSCredential] $Credential,
        [Parameter(Mandatory = $true)] [string] $MigrateVM
    )

    begin {
        $currentDate = Get-Date
        $startDate = $currentDate.AddDays(-2)
        $endDate = $currentDate.AddDays(-1)
        $lineRecords = @()
    }

    process {

    Connect-VIServer -Server $Server -Credential $Credential | Out-Null
    $VM = Get-VM | Where-Object { $_.Name -eq $MigrateVM } | Select-Object -Property Name, PowerState, Guest, NumCPU, CoresPerSocket,  MemoryGB, VMHost, UsedSpaceGB, ProvisionedSpaceGB, ID

    }

    end {
        Disconnect-VIServer -Server * -Confirm:$false
        return $VM
    }
 }

