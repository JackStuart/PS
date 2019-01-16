param(
	[bool]$DeletedItemsRun = $true ,
	[bool]$LitigationHoldRun = $true ,
	[bool]$AuditingRun = $true ,
	[bool]$IMAPPlanRun = $false ,
	[bool]$IMAPMailboxesRun = $false
)

#Connect to Office365
$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session

#This command errors if it's already run, Hence the erroracction silentlycontinue
#However this is reqiured for some commands to take effect (Auditing, CASMailbox Plans etc) 
Enable-OrganizationCustomization -ErrorAction SilentlyContinue

#Collect information to variable for filtering below
$AllMailboxes = Get-mailbox -ResultSize unlimited -Filter {(RecipientTypeDetails -eq 'UserMailbox')} | Select-Object AuditOwner, AuditDelegate, AuditAdmin, AuditLogAgeLimit, PersistedCapabilities, LitigationHoldEnabled, UserPrincipalName, RetainDeletedItemsFor, AuditEnabled, LitigationHoldDuration

if($DeletedItemsRun -eq $true)
{
    $DeletedItems = $AllMailboxes | Where-Object {$_.RetainDeletedItemsFor -lt "29"}

    If(($DeletedItems.UserPrincipalName).count -eq 0)
    {
        Write-Host "There are no mailboxes with the RetainDeletedItemsFor not set correctly. No changes have been made" -ForegroundColor Green
    }
    else
    {
        Write-Host "There are" ($DeletedItems.UserPrincipalName).count "mailboxes with their Deleted Item Retetion not set correctly" -ForegroundColor Red
        Foreach($DelMailbox in $DeletedItems)
            {
                Set-Mailbox $DelMailbox.UserPrincipalName -retainDeletedItemsFor 30 -UseDatabaseRetentionDefaults $false
            }
    } 
}

if($LitigationHoldRun -eq $true)
{
    $LitigationHold = $AllMailboxes | Where-Object {$_.PersistedCapabilities -eq "BPOS_S_Enterprise" -and $_.LitigationHoldEnabled -ne $true -or $_.LitigationHoldDuration -lt "2554"}

    If(($LitigationHold.UserPrincipalName).count -eq 0)
    {
        Write-Host "There are no mailboxes with the LitigationHold not set correctly. No changes have been made" -ForegroundColor Green
    }
    else
    {
        Write-Host "There are" ($LitigationHold.UserPrincipalName).count "mailboxes with Litigation Hold not set correctly" -ForegroundColor Red
        Foreach($LitMailbox in $LitigationHold)
            {
            $LitMailbox.UserPrincipalName | Set-Mailbox -LitigationHoldEnabled $true -LitigationHoldDuration 2555
            }
    }
}

if($AuditingRun -eq $true)
{
    $Auditing = $AllMailboxes | Where-Object {$_.AuditEnabled -eq $false -or ($_.AuditAdmin.count) -lt 1 -or ($_.AuditDelegate.count) -lt 1 -or ($_.AuditOwner.count) -lt 1 -or $_.AuditLogAgeLimit -lt "364"} 

    If(($Auditing.UserPrincipalName).count -eq 0)
    {
        Write-Host "There are no mailboxes with Auditing not set correctly. No changes have been made" -ForegroundColor Green
    }
    else
    {
        Write-Host "There are" ($Auditing.UserPrincipalName).count "mailboxes with Auditing not set correctly" -ForegroundColor Red
        Foreach($Auditmailbox in $Auditing)
            {
            $Auditmailbox.UserPrincipalName | Set-Mailbox -AuditEnabled $true -AuditOwner Create,HardDelete,MailboxLogin,Move,MoveToDeletedItems,SoftDelete,Update -AuditDelegate Create,FolderBind,HardDelete,Move,MoveToDeletedItems,SendAs,SendOnBehalf,SoftDelete,Update –AuditAdmin Copy,Create,FolderBind,HardDelete,MessageBind,Move,MoveToDeletedItems,SendAs,SendOnBehalf,SoftDelete,Update -AuditLogAgeLimit 365
            }
    }
}

if($IMAPPlanRun -eq $true)
{
    $IMAPPlan = Get-CASMailboxPlan -Filter {ImapEnabled -eq "true" -or PopEnabled -eq "true" }

    If($IMAPPlan.count -eq 0)
    {
        Write-Host "All CAS Mailbox Plans have POP/IMAP disabled (Future Mailboxes wont have POP/IMAP Enabled)" -ForegroundColor Green
    }
    else
    {
        Write-Host "There are" $IMAPPlan.count "plans with POP/IMAP enabled. Future mailboxes may have POP/IMAP Enabled" -ForegroundColor Red
        Foreach($Plan in $IMAPPlan)
            {
            $Plan | Set-CASMailboxPlan -ImapEnabled $false -PopEnabled $false
            }
    }
}

if($IMAPMailboxesRun -eq $true)
{
    $IMAPMailboxes = Get-CASMailbox -Filter {ImapEnabled -eq "true" -or PopEnabled -eq "true" } | Select-Object @{n = "Identity"; e = {$_.primarysmtpaddress}}

    If($IMAPMailboxes.count -eq 0)
    {
        Write-Host "All Mailboxes have IMAP/POP disabled" -ForegroundColor Green
    }
    else
    {
        Write-Host "There are" $IMAPMailboxes.count "mailboxes with IMAP/POP enabled" -ForegroundColor Red
        Foreach($IMAPMail in $IMAPMailboxes)
            {
            $IMAPMail.identity | Set-CASMailbox -ImapEnabled $false -PopEnabled $false
            }
    }
}


#Checking scripts work
#Reset variables


$AllMailboxes = $null
$AllMailboxes = Get-mailbox -ResultSize unlimited -Filter {(RecipientTypeDetails -eq 'UserMailbox')} | Select-Object AuditOwner, AuditDelegate, AuditAdmin, AuditLogAgeLimit, PersistedCapabilities, LitigationHoldEnabled, UserPrincipalName, RetainDeletedItemsFor, AuditEnabled, LitigationHoldDuration

if($DeletedItemsRun -eq $true -and ($DeletedItems).count -ne 0)
{
    $DeletedItems = $null
    Write-Host "Checking that Deleted Items has been set correctly" -ForegroundColor Green
    $DeletedItems = $AllMailboxes | Where-Object {$_.RetainDeletedItemsFor -lt "29"}

    If(($DeletedItems.UserPrincipalName).count -eq 0)
    {
        Write-Host "All mailboxes have the DeletedItems retention set correctly!!!" -ForegroundColor Green
    }
    else
    {
        Write-Host "There are" ($DeletedItems.UserPrincipalName).count "mailboxes with their Deleted Item Retetion not set correctly - Please Investigate" -ForegroundColor Red
    } 
}

if($LitigationHoldRun -eq $true -and ($LitigationHold).count -ne 0)
{
    $LitigationHold = $null
    Write-Host "Checking that Litigation Hold has been set correctly" -ForegroundColor Green
    $LitigationHold = $AllMailboxes | Where-Object {$_.PersistedCapabilities -eq "BPOS_S_Enterprise" -and $_.LitigationHoldEnabled -ne $true -or $_.LitigationHoldDuration -lt "2554"}

    If(($LitigationHold.UserPrincipalName).count -eq 0)
    {
        Write-Host "All mailboxes have LitigationHold set correctly!!!" -ForegroundColor Green
    }
    else
    {
        Write-Host "There are" ($LitigationHold.UserPrincipalName).count "mailboxes with Litigation Hold not set correctly - Please Investigate" -ForegroundColor Red
    }
}

if($AuditingRun -eq $true -and ($Auditing).count -ne 0)
{
    $Auditing = $null
    Write-Host "Checking that Auditing has been set correctly" -ForegroundColor Green
    $Auditing = $AllMailboxes | Where-Object {$_.AuditEnabled -eq $false -or ($_.AuditAdmin.count) -ne 11 -or ($_.AuditDelegate.count) -ne 9 -or ($_.AuditOwner.count) -ne 7 -or $_.AuditLogAgeLimit -lt "364"} 

    If(($Auditing.UserPrincipalName).count -eq 0)
    {
        Write-Host "All mailboxes have Auditing set correctly!!!" -ForegroundColor Green
    }
    else
    {
        Write-Host "There are" ($Auditing.UserPrincipalName).count "mailboxes with Auditing not set correctly - Please Investigate" -ForegroundColor Red
    }
}

if($IMAPPlanRun -eq $true -and ($IMAPPlan).count -ne 0)
{
    $IMAPPlan = $null
    Write-Host "Checking that CAS Plans have been set correctly" -ForegroundColor Green
    $IMAPPlan = Get-CASMailboxPlan -Filter {ImapEnabled -eq "true" -or PopEnabled -eq "true" }

    If($IMAPPlan.count -eq 0)
    {
        Write-Host "All CAS Mailbox Plans have POP/IMAP disabled (Future Mailboxes wont have POP/IMAP Enabled)!!!" -ForegroundColor Green
    }
    else
    {
        Write-Host "There are" $IMAPPlan.count "plans with POP/IMAP enabled. Future mailboxes may have POP/IMAP Enabled" -ForegroundColor Red
    }
}

if($IMAPMailboxesRun -eq $true -and ($IMAPMailboxes).count -ne 0)
{
    $IMAPMailboxes = $null
    Write-Host "Checking that all mailboxes have POP/IMAP disabled" -ForegroundColor Green
    $IMAPMailboxes = Get-CASMailbox -Filter {ImapEnabled -eq "true" -or PopEnabled -eq "true" } | Select-Object @{n = "Identity"; e = {$_.primarysmtpaddress}}

    If($IMAPMailboxes.count -eq 0)
    {
        Write-Host "All Mailboxes have IMAP/POP disabled" -ForegroundColor Green
    }
    else
    {
        Write-Host "There are" $IMAPMailboxes.count "mailboxes with IMAP/POP enabled" -ForegroundColor Red
    }
}
Exit-PSSession