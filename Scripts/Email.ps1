

$workingDirectory = "./"
$reportDirectory = "./Reports"

$Result = Get-Content "${reportDirectory}/result.txt"
$paramsLists = Get-Content "${workingDirectory}/Parameter/parameters.json" | ConvertFrom-Json

$emailTo = $paramsLists.Request.RequesterEmailID
$emailCC = "dinesh.ginwali@xyz.com"
$emailFrom = "dinesh.ginwali@xyz.com"
$emailSubject = "VM Workload Migration : VM : $($VMInfo.Name) Cluster: $($VMInfo.VMHost.Parent )"
$emailBody = [string]$Result 
$smtpServer = "xx.xx.xx.xx"
$emailAttachments = "${reportDirectory}/$($paramsLists.Dest.Datacenter)/$($paramsLists.Dest.Environment)/$($paramsLists.Dest.HeadroomFileName)"


$emailParams = @{
      To = $emailTo
      CC = $emailCC
      From = $emailFrom
      Subject = $emailSubject
      Body = $emailBody
      SmtpServer = $smtpServer
      Attachments = $emailAttachments
}

Send-MailMessage @emailParams
