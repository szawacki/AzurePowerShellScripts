<#
    .DESCRIPTION
        A runbook to shutdown all VMs in given subscription depending on "AutoShutdownSchedule"-Tag. Based on a script provided by 
		Microsoft: https://gallery.technet.microsoft.com/scriptcenter/Scheduled-Virtual-Machine-2162ac63.
        
        Create a runbook in your azure automation account and paste this script inside.
        In line 209 and 210 set your credential asset name, for login and your subscription name to manage.
        Create a schedule that runs once per hour and apply it to the runbook.
        Publish the runbook.

        For all virtual machines that should be mananged by the runbook, create a tag with key: "AutoShutdownSchedule".
         
        Valid options for value are:
                                     "None"                           = Virtual machine is not affected.
                                     "= 18:00"                        = Shutdown virtual machine at 18:00. Machine will not be started.
                                     "18:00 -> 07:00"                 = Shutdown virtual machine at 18:00 and start ist at 07:00.
                                     "14:00 -> 22:00, 04:00 -> 08:00" = Shutdown virtual machine at 14:00, starts it at 22:00, shutdown at 22:00 and start at 08:00.
                                                                        Even more then two time frames per machine are valid.
                                                                       
        All times are in 24 hour format. 
        Used time zone is "Western European Standard Time". Can be changed in lines 51, 171 and 231. 
        Only working with resource manager virtual machines, service manager virtual machines are not suppourted as they do not have tags.    

    .NOTES
        AUTHOR: Stefan Zawacki
        LASTEDIT: Apr 28, 2016
#>

function Convert-TimeZone {  
    [cmdletbinding()]            
    param(  [parameter( Mandatory=$true)]            
            [ValidateNotNullOrEmpty()]            
            [datetime]$DateTime,            
            [string]$ToTimeZone  = ([system.timezoneinfo]::UTC).id            
    )            

    $ToTimeZoneObj  = [system.timezoneinfo]::GetSystemTimeZones() | Where-Object {            
        $_.id -eq $ToTimeZone            
    }            
             
    [system.timezoneinfo]::ConvertTime($DateTime, $ToTimeZoneObj)                     
}

function CheckScheduleEntry () 
{     
    param( [string]$TimeRange
    )

    # Initialize variables 
    $RangeStart, $RangeEnd, $ParsedDay = $null 
    $CurrentTime = Convert-TimeZone -DateTime (Get-Date).ToUniversalTime() -ToTimeZone “W. Europe Standard Time”  
    $Midnight = $CurrentTime.AddDays(1).Date             
 
    try 
    { 
        # Parse as range if contains '->' 
        if($TimeRange -like "*->*") 
        { 
            $TimeRangeComponents = $TimeRange -split "->" | foreach {$_.Trim()} 
            if($TimeRangeComponents.Count -eq 2) 
            { 
                $RangeStart = Get-Date $TimeRangeComponents[0] 
                $RangeEnd = Get-Date $TimeRangeComponents[1] 
     
                # Check for crossing midnight 
                if($RangeStart -gt $RangeEnd) 
                { 
                    # If current time is between the start of range and midnight tonight, interpret start time as earlier today and end time as tomorrow 
                    if($CurrentTime -ge $RangeStart -and $CurrentTime -lt $Midnight) 
                    { 
                        $RangeEnd = $RangeEnd.AddDays(1) 
                    } 
                    # Otherwise interpret start time as yesterday and end time as today    
                    else 
                    { 
                        $RangeStart = $RangeStart.AddDays(-1) 
                    } 
                } 
            } 
            else 
            { 
                Write-Output "`tWARNING: Invalid time range format. Expects valid .Net DateTime-formatted start time and end time separated by '->'"  
            } 
        } 
        # Otherwise attempt to parse as a full day entry, e.g. 'Monday' or 'December 25'  
        else 
        { 
            # If specified as day of week, check if today 
            if([System.DayOfWeek].GetEnumValues() -contains $TimeRange) 
            { 
                if($TimeRange -eq (Get-Date).DayOfWeek) 
                { 
                    $ParsedDay = Get-Date "00:00" 
                } 
                else 
                { 
                    # Skip detected day of week that isn't today 
                } 
            } 
            # Otherwise attempt to parse as a date, e.g. 'December 25' 
            else 
            { 
                $ParsedDay = Get-Date $TimeRange 
            } 
         
            if($ParsedDay -ne $null) 
            { 
                $RangeStart = $ParsedDay # Defaults to midnight 
                $RangeEnd = $ParsedDay.AddHours(23).AddMinutes(59).AddSeconds(59) # End of the same day 
            } 
        } 
    } 
    catch 
    { 
        # Record any errors and return false by default 
        Write-Output "`tWARNING: Exception encountered while parsing time range. Details: $($_.Exception.Message). Check the syntax of entry, e.g. '<StartTime> -> <EndTime>', or days/dates like 'Sunday' and 'December 25'"    
        return $false 
    } 
     
    # Check if current time falls within range 
    if($CurrentTime -ge $RangeStart -and $CurrentTime -le $RangeEnd) 
    { 
        return $true 
    } 
    else 
    { 
        return $false 
    } 
     
}

function GetScheduledTime() {
    param(
        [Object]$VirtualMachine
    )

    if ($VirtualMachine.Tags.Name -contains "AutoShutdownSchedule")
    {
        return ($VirtualMachine.Tags | Where Name -eq "AutoShutdownSchedule")["Value"]
    }
}

function AssertResourceManagerVirtualMachinePowerState
{
    param(  [Object]$VirtualMachine,
            [string]$DesiredState
    )
	
    # Get VM with current status
    $ResourceManagerVM = Get-AzureRmVM -ResourceGroupName $VirtualMachine.ResourceGroupName -Name $VirtualMachine.Name -Status -ErrorAction SilentlyContinue
    
    if (!$ResourceManagerVM)
    {
        return
    }
    
    $CurrentStatus = $ResourceManagerVM.Statuses | where Code -like "PowerState*" 
    $CurrentStatus = $CurrentStatus.Code -replace "PowerState/",""

    $Schedule = GetScheduledTime -VirtualMachine $VirtualMachine

    if ($Schedule)
    {
        if ($Schedule -ieq "none")
        {
            return
        }
        
        if ($Schedule -like "=*")
        {
            $CurrentTime = Convert-TimeZone -DateTime (Get-Date).ToUniversalTime() -ToTimeZone “W. Europe Standard Time” 
            $ShutdownTimeComponents = $Schedule -split "=" | foreach {$_.Trim()}
            $ShutdownTime = Get-Date $ShutdownTimeComponents[1]

            if ($CurrentTime -ge $ShutdownTime -and $CurrentTime -le $ShutdownTime.AddHours(3))
            {
                if($CurrentStatus -ne "deallocated")
                {
                    Write-Output "[$($VirtualMachine.Name)]: Stopping VM"
                    $ResourceManagerVM | Stop-AzureRmVM -Force
                }
            }
            return
        } 
        else
        {
            $TimeRangeList = @($Schedule -split "," | foreach {$_.Trim()}) 
         
            # Check each range against the current time to see if any schedule is matched 
            $ScheduleMatched = $false 
        
            foreach($Entry in $TimeRangeList) 
            { 
                if((CheckScheduleEntry -TimeRange $Entry) -eq $true) 
                { 
                    $ScheduleMatched = $true 
                    break 
                } 
            } 

            if($ScheduleMatched) 
            { 
	            if($CurrentStatus -ne "deallocated")
	            {
                    Write-Output "[$($VirtualMachine.Name)]: Stopping VM"
                    $ResourceManagerVM | Stop-AzureRmVM -Force
	            }
            }
            else
            {
	            if($CurrentStatus -notmatch "running") 
	            {
                    Write-Output "[$($VirtualMachine.Name)]: Starting VM"
                    $ResourceManagerVM | Start-AzureRmVM
	            }		
            }
        }
    }
}

# Main runbook content
try
{
    # Provide authentication data
    $CredentialAssetName = "<your credential name>"
    $SubscriptionName = "<your subscription name>"

    $CurrentTime = (Get-Date).ToUniversalTime()
    Write-Output "Runbook started. Version: $VERSION"
    Write-Output "Current UTC/GMT time [$($CurrentTime.ToString("dddd, yyyy MMM dd HH:mm:ss"))] will be checked against schedules"
	Write-Output "Current CET time [$((Convert-TimeZone -DateTime $CurrentTime -ToTimeZone “W. Europe Standard Time”).ToString("dddd, yyyy MMM dd HH:mm:ss"))]"

    # Get the credential with the above name from the Automation Asset store
    $Cred = Get-AutomationPSCredential -Name $CredentialAssetName

    if(!$Cred) 
    {
        Throw "Could not find an Automation Credential Asset named '${CredentialAssetName}'. Make sure you have created one in this Automation Account."
    }

    # Login to subscription
	Login-AzureRmAccount -Credential $Cred -SubscriptionName $SubscriptionName

    # Get a list of all virtual machines in subscription
    $ResourceManagerVMList = @(Get-AzureRmResource | where {$_.ResourceType -like "Microsoft.*/virtualMachines"} | sort Name)

    

    Write-Output "Processing [$($ResourceManagerVMList.Count)] virtual machines found in subscription"

    foreach($Vm in $ResourceManagerVMList)
    {
        AssertResourceManagerVirtualMachinePowerState -VirtualMachine $Vm
    }

    Write-Output "Finished processing virtual machine schedules"
}
catch
{
    $ErrorMessage = $_.Exception.Message
    throw "Unexpected exception: $ErrorMessage"
}
finally
{
    Write-Output "Runbook finished (Duration: $(("{0:hh\:mm\:ss}" -f ((Get-Date).ToUniversalTime() - $CurrentTime))))"
}
