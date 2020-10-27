Param(
    [Parameter()]
    [switch]$WhatIf,
    [Parameter(Mandatory=$true)]
    [string]$To,
    [Parameter()]
	[ValidateRange(1,14)] 
    [int32]$DayCount = 1
)

$days = $DayCount
if ($DayCount -gt 0)
{
    $days = $DayCount * -1
}

$connectionName = "AzureRunAsConnection"
$SubscriptionId = Get-AutomationVariable -Name "SubscriptionId"

try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         
    
    Write-Verbose "Logging in to Azure..."
    Add-AzureRmAccount `
       -ServicePrincipal `
       -TenantId $servicePrincipalConnection.TenantId `
       -ApplicationId $servicePrincipalConnection.ApplicationId `
       -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint | Out-Null
    
    Set-AzureRmContext -SubscriptionId $SubscriptionId | Out-Null
}
catch {
    if (!$servicePrincipalConnection)
    {
      # $ErrorMessage = "Connection $connectionName not found."
      # throw $ErrorMessage
    } else{
      # Write-Error -Message $_.Exception
      # throw $_.Exception
    }
}

if ($WhatIf)
{
  Write-Warning "Running in WhatIf mode - no changes will be made."
}

$allRGs = (Get-AzureRmResourceGroup).ResourceGroupName

Write-Warning "Found $($allRGs.Length) total RGs"

$aliasedRGs = (Find-AzureRmResourceGroup -Tag @{ alias = $null }).Name

Write-Warning "Found $($aliasedRGs.Length) aliased RGs"

$notAliasedRGs = $allRGs | ?{-not ($aliasedRGs -contains $_)}

Write-Warning "Found $($notAliasedRGs.Length) un-tagged RGs"

$result = New-Object System.Collections.ArrayList

foreach ($rg in $notAliasedRGs)
{
	$p = 100 / ($notAliasedRGs.Length -1 ) * $notAliasedRGs.IndexOf($rg)
    Write-Progress -Activity "Searching Resource Group Logs for last $days days..." -PercentComplete $p `
        -CurrentOperation "$p% complete" `
        -Status "Resource Group $rg"

    $callers = Get-AzureRmLog -ResourceGroup $rg `
				-StartTime (Get-Date).AddDays($days) `
				-EndTime (Get-Date)`
				| Select Caller `
				| Where-Object { $_.Caller -and ($_.Caller -ne "System")} `
				| Sort-Object -Property Caller -Unique
    if ($callers){
        $alias = $callers[0].Caller
				
        Write-Warning "Tagging Resource Group $rg for alias $alias"
        if (-not $WhatIf)
        {
            Set-AzureRmResourceGroup -Name $rg -Tag @{ alias = $alias}
        }
        $result.Add((New-Object PSObject -Property @{Name=$rg; Alias=$alias})) | Out-Null
        
    }
    else{
        Write-Warning "No activity found for Resource Group $rg"
    }
}

Write-Progress -Activity "Searching Resource Group Logs..." -Completed -Status "Done"

$rgString = ($result | ForEach-Object { "$($_.Name) ($($_.Alias))" }) -join "<br/>"

$toAffected = ($result | ForEach-Object { "<$($_.Alias)>" }) -join ";"

$body = "Hi<br/>$($toAffected)<br/>The following resource groups have been tagged:<br/>$($rgString)"
$subject = "$($result.Count) new resource groups tagged";

$toArray = $To.Split(";")

Write-Warning "Sending Mail to $To"

$mailCreds = Get-AutomationPSCredential -Name 'Office365'
Send-MailMessage -Body $body -BodyAsHtml -Credential $mailCreds `
     -From $mailCreds.UserName `
     -Port 587 -SmtpServer smtp.office365.com -Subject $subject -To $toArray -UseSSL


$result