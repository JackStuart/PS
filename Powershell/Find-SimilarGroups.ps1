$CSVLocation = ""
$GoodPercentage = 75
$FilteredGroups = ""
$ALlGroups = @()
$FinalOutput = @()
$ADUsers = Import-CSV $CSVLocation
$ADuser = ""
$ADGroupOutput = New-Object psobject

foreach($ADUser in $ADUsers){
    foreach($ADGroup in (Get-ADPrincipalGroupMembership $ADUser.Username)){
        $ADGroupOutput = New-Object psobject
        $ADGroupOutput = "" | Select-Object Username, ADGroup 
        $ADGroupOutput.Username = $ADUser.Username
        $ADGroupOutput.ADGroup = $ADGroup.Name

        $AllGroups += $ADGroupOutput
    }
}
$FilteredGroups = $AllGroups | sort ADGroup -Unique

Foreach($FilteredGroup in $FilteredGroups){
    $FilteredADGroupOutput = New-Object psobject
    $FilteredADGroupOutput = "" | Select ADGroup, UserCount, TotalGroupMembers, Percentage

    $FilteredADGroupOutput.ADGroup = $FilteredGroup.ADGroup
    $FilteredADGroupOutput.UserCount = (($AllGroups | Where-Object {$_.ADGroup -eq ($FilteredGroup.ADGroup)} | Measure-Object).count)
    $FilteredADGroupOutput.TotalGroupMembers = (Get-ADGroup -properties Member $FilteredGroup.ADGroup).Member.count
    $FilteredADGroupOutput.Percentage = [math]::Round((($FilteredADGroupOutput.UserCount / $FilteredADGroupOutput.TotalGroupMembers) * 100),2)

    if($FilteredADGroupOutput.Percentage > $GoodPercentage){
        Write-Output "$($FilteredADGroupOutput.ADGroup) may be a good fit. The provided users make up ($FilteredADGroupOutput.Percentage) of that group"
    }
}
