# $2 => Job Type (0 backup, 28 Snapshot, 21 import)
# $3 => State of job (3 DONE, 0 Queued, 1 active, )
# $4 => JOB STATUS CODE
# $5 => Policy Name
# $7 => Client Name 
# $9 => Job Started Time
# $10 => Elapsed Time
# $11 => Job End Time
# $18 => Percent Complete
# $23 => Schedule Type [0=Full, 1=incremental]

$hostname = hostname
$executionTime = Get-Date

# Get the date by checking the AM and PM Output
function Moc-Date() {


    # Defininf the current time perios
    $datenow = Get-Date
    $culture = [System.Globalization.CultureInfo]::CreateSpecificCulture('en-US')
    $isMidnight = (Get-Date $datenow).ToString('tt', $culture)

    # Initializing the variable that would be used as date
    $filter_date=$null

    # Check if the time now is evening
    if ( $isMidnight -eq 'PM' ) {
        # if so, then start the counting from today
        $filter_date = Get-Date -Format 'dd/MM/yyyy 18:00:00'
        
        # Else mean we are in night, then we must go and start counting from yesterday  
    } else {
        $filter_date= (Get-Date).AddDays(-1).ToString("dd/MM/yyyy 18:00:00")
    }

    #  clear variables

    $time=$null
    $atime=$null
    $ptime=$null

    return  $filter_date
}

# Printing the Header by adding hostname and Date
function header() {
   echo "" 
   echo "============================================================"
   echo "                  NetBackup - MOC Live Check" 
   echo "" 
   echo "Server : $hostname - Date : $executionTime"
   echo "============================================================"
   echo "" 
   echo "" 
}

# Getting Output in CSV, adding Header for data
function Get-CsvDate($file_name,$date){

    # Step 1 : create The output data
    bpdbjobs -most_columns -t $date | Out-File ".\$($file_name).csv"

    # Step 2 : Upload data file and set a header
    $filedata = Import-Csv ".\$($file_name).csv"-Header jobid,jobtype,state,status,policy,schedule,client,server,started,elapsed,ended,stunit,try,operation,kbytes,files,pathlastwritten,percent,jobpid,owner,subtype,classtype,scheule_ype,priority,group,masterserver,retentionunits,retentionperiod,compression,kbyteslastwritten,fileslastwritten,filelistcount,[files],trycount,[trypid,trystunit,tryserver,trystarted,tryelapsed,tryended,trystatus,trystatusdescription,trystatuscount,[trystatuslines],trybyteswritten,tryfileswritten],parentjob,kbpersec,copy,robot,vault,profile,session,ejecttapes,srcstunit,srcserver,srcmedia,dstmedia,stream,suspendable,resumable,restartable,datamovement,snapshot,backupid,killable,controllinghost -Delimiter ","

    # Step 3 : Delete the file
    Remove-Item -Path ".\$($file_name).csv"

    # Step 4 : export csv data

    return $filedata
}

# Processing cvs data and collecting informations
function Get-Imports {
    # Define Counters
    $imports_counter = 0
    $active_counter = 0
    $failed_counter = 0
    $queud_counter = 0

    # Loop Over data
    $data | foreach {
        # Initialize Filters
        $current = [int]$_.jobtype
        $backupType = $_.policy
        $backup_state = [int]$_.state
        $backup_status = [int]$_.status

        # Checking for Imports that done 
        if($current -eq 21 -and $backupType -NotLike "*TEST_MSDP2*" -and $backup_state -eq 3) {
            $imports_counter = $imports_counter + 1
        }
        
        # Checking for Imports that Active 
        if($current -eq 21 -and $backupType -NotLike "*TEST_MSDP2*" -and $backup_state -eq 1) {
            $active_counter = $active_counter + 1
        }  
        
        # Checking for Imports that Failed 
        if($current -eq 21  -and ($backupType -NotLike "*TEST_MSDP2*") -and ($backup_state -eq 3) -and ($backup_status -gt 1) )  {
            $failed_counter = $failed_counter + 1
        }

        # Checking for Imports that in Queud Status 
        if($backup_state -eq 0)  {
            $queud_counter = $queud_counter + 1
        }
    }

    # $yourData = @(
    #     @{Done="$backup_counter";Active="$active_counter";Failed="$failed_counter"}
    # ) | % { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru }


    # Print Data
    echo "IMPORTS CHECK"
    echo "DONE : $imports_counter - ACTIVE : $active_counter - FAILED : $failed_counter - QUEUD : $queud_counter" 


    # $yourData
}

# Checking DP and DV Status using nbdevQuery
function query() {

   echo "" 
   echo "============================================================" 
   echo "" 
   echo "                  Check DP and DV Status" 
   echo "" 
   echo "============================================================" 
   echo "" 


    echo "||||||||storage Server||||||||" 
    nbdevquery -listdp -stype PureDisk -U | Select-String "Storage Server" 
    echo "||||||||storage Server status||||||||" 
    nbdevquery -listdp -stype PureDisk -U | Select-String "Status" 
    echo "||||||||Disk Volume Status||||||||" 
    nbdevquery -listdv -stype PureDisk -U | Select-String "Status" 
    Get-Date -Format 'dd/MM/yyyy HH:mm:ss'
}



#######################################################################
#                   MAIN PROGRAMME
########################################################################

# 1 - Print the Header
header

# 2- Get the date time
$filter_date = Moc-Date

# 3 - Load Data
$data = Get-CsvDate 'data' $filter_date

# 4 - Print data to console
Get-Imports

# 5 - Print the Status of Dv and DP
query