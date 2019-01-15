# PS
Powershell scripts - Mostly aimed at O365

## O365_Best_Practices

This script connects to your Office365 tenant and gets a list of all mailboxes, It then lets you adjust the below settings as required

**Default Values** - 
.\O365_Best_Practices.ps1 -DeletedItemsRun $true -LitigationHoldRun $true -AuditingRun $true -IMAPPlanRun $false -IMAPMailboxesRun $false

**DeletedItemsRun** - Adjusts the RetainDeletedItemsFor to 30. This allows you to recover items from the recycle bin for up to 30 days instead of 14 days
[MS Link](https://docs.microsoft.com/en-us/exchange/recipients/user-mailboxes/deleted-item-retention-and-recoverable-items-quotas?view=exchserver-2019)

**LitigationHoldRun** - Adjusts Litigation Hold to 2555 days for all EOP2 and E3+ licences - [MS Link](https://docs.microsoft.com/en-us/exchange/policy-and-compliance/holds/litigation-holds?view=exchserver-2019)

**AuditingRun** - Turns on all Mailbox Auditing so you can see all possible events in the Audit Log

**IMAPPlanRun** - Disables POP/IMAP for all future mailboxes by turning it off in the CAS plan

**IMAPMailboxesRun** - Disables POP/IMAP for all current mailboxes by turning it off directly at the mailbox level 
