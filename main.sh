#=======================================
# Author's      : Abdelilah AKEBLI, Amane Mahmoud, Mohamed el mehdi JAMAI
# Creation Date : 11/11/2022
# Description : This file contain the main Script that has been created contain an interactive interface 
# that could collect the MOC live check and the EIT Check
#=======================================
: <<'DOCUMENTATION'
    bdpjobs is the command used for collect it return fields started from 1
    the `$x` represent the column number and what it does.
    ===========================================================================
    $2 => Job Type (0 backup, 28 Snapshot, 21 import, 22 backup form snapshot)
    $3 => State of job (3 DONE, 0 Queued, 1 active, )
    $4 => JOB STATUS CODE
    $5 => Policy Name
    $7 => Client Name
    $9 => Job Started Time
    $10 => Elapsed Time
    $11 => Job End Time
    $18 => Percent Complete
    $23 => Schedule Type [0=Full, 1=incremental]
DOCUMENTATION


############################################################
# Function that pring the Help command 
############################################################
Help()
{
   echo
   echo "As part of daily AA task is controlling backup Daily, and this for guarentee the QOS and satisfaction of clients, /n there for a MOC Live Check Is a set of commands that help 24/7 staff to get live data status"
   echo
   echo "Syntax: moc [-h|b|i|c|t]"
   echo
   echo "options:"
   echo
   echo "h     Print this Help. --- Example : moc -h"
   echo
   echo "b     Print the count of Backups ( DONE | ACTIVE |FAILED | QUEUD ). --- Example : moc -b"
   echo
   echo "i     Print the count of Imports (OK | NOK). --- Example : moc -i."
   echo
   echo "c     Check the status of MSDP, Disk Pools and Disk Volums Status [UP|DOWN]. --- Example : moc -c "
   echo
   echo "t     Check the last backup test executed on current master with their state. --- Example : moc -t"
   echo
   echo "e     Return the state of MSDP and with last executed backup check. --- Example : moc -e"
   echo
   echo "NOTE 1 : If no Option are specified then the default is show the Backup Count from 18H00 TO 06H00 and State OF Storage"
   echo "NOTE 1 : The script is interactive and always waiting for user input to print the result, else you can always press q to exit"
   echo
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

#=======================================
# Defining Colors
#=======================================
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
Yellow='\033[0;33m'
Purple='\033[0;35m'
NC='\033[0m'

#=======================================
# To clear the Console once the Script Started
clear
#=======================================

#=======================================
# Printing a handsome Header 🏁
#=======================================
function Header() {
    today=`date '+%D'`
    echo -e "
=======================================================
 _      _______      __ __   _____ _    _ ______ _____ _  __
 | |    |_   _\ \    / //_/_ / ____| |  | |  ____/ ____| |/ /
 | |      | |  \ \  / / ____| |    | |__| | |__ | |    | ' / 
 | |      | |   \ \/ /|  _| | |    |  __  |  __|| |    |  <  
 | |____ _| |_   \  / | |___| |____| |  | | |___| |____| . \ 
 |______|_____|   \/  |_____|\_____|_|  |_|______\_____|_|\_\
 
=======================================================
"
echo -e "Script Started AT : ${GREEN} $today ${NC} Server : ${Yellow} $(hostname) ${NC}"
echo

}
#=======================================
# Detecting Time ⏱️
# The MOC start from 18H PM to 06 AM for that we a Time formating
#=======================================
isMidnight=$(date +'%r' | awk '{print $2}')
if [[ $isMidnight == "PM" ]]; then
 filter_date=$(date +"%m/%d/%y")
 filter_date_time="${filter_date} 18:00:00"
else [[ $isMidnight == "AM" ]]
 filter_date=$(date +"%m/%d/%y" -d "Yesterday")
 filter_date_time="${filter_date} 18:00:00"
fi
#=======================================
# Start Job Filtring For Backups 🗄️
#=======================================
function verify_backups() {
    done=$(
        bpdbjobs -most_columns -t "$filter_date_time" |
        sort -t, -nrk11  |
        awk -F "," '$5!~"TEST" && $2==0 && $3==3 {count++} END {print count}'
    )
    active=$(
        bpdbjobs -most_columns -t "$filter_date_time" |
        sort -t, -nrk11 |
        awk -F "," '$5!~"TEST" && $2==0 && $3==1 {countA++;} END {print countA}'
    )
    failed=$(
        bpdbjobs -most_columns -t "$filter_date_time" | sort -t, -nrk11 | awk -F "," '$5!~"TEST" && ($2==0 || $2==28 || $2==22) && $3==3 && $4>1 {countF++;} END {print countF}'
    )
    queud=$(
        bpdbjobs -most_columns -t "$filter_date_time" |
        sort -t, -nrk11 |
        awk -F "," '$3==0 {countA++;} END {print countA}'
    )
    #=======================================
    # Formating Failed
    if [ -z "$failed" ]; then
    failed="0"
    fi
    if [ -z "$active" ]; then
    active=0
    fi
    if [ -z "$done" ]; then
    done=0
    fi
    if [ -z "$queud" ]; then
    queud="0"
    fi

    Header
    #=======================================
    # print Output
    echo
    echo -e "${Yellow} BACKUPS Check Count : ${NC}"
    echo -e "\n"
    echo -e "${BLUE} DONE : ${done} ${NC} | ${GREEN} Active :  ${active} ${NC} | ${RED} Failed : ${failed}${NC} | QUEUD : ${queud} "
    echo -e "\n"
}

#=========================================
# Start Filtring for Imports ⏫
# $2==21 for imports and $3==3 means its done
#=======================================
function verify_imports() {
    imports_ok=$(
        bpdbjobs -most_columns  -t $filter_date_time | 
        sort -t, -nrk11 | 
        awk -F "," '$5!~"TEST" && $2==21 && $3==3 {countA++;} END {print countA}')
    imports_nok=$(bpdbjobs -most_columns  -t $filter_date_time | sort -t, -nrk11 | awk -F "," '$5!~"TEST" && $2==21 && $3==3 && $4>0 {countA++;} END {print countA}')
    imports_queud=$(
        bpdbjobs -most_columns -t "$filter_date_time" |
        sort -t, -nrk11 |
        awk -F "," '$3==0 {countA++;} END {print countA}'
    )
    if [ -z "$imports_ok" ]; then
    imports_ok="0"
    fi
    if [ -z "$imports_nok" ]; then
    imports_nok="0"
    fi
    if [ -z "$imports_queud" ]; then
    imports_queud="0"
    fi
    Header
    echo -e "\n"
    echo -e "${Yellow} IMPORTS Check Count : ${NC}"
    echo -e "\n"
    echo -e "${BLUE} IMPORTS OK : ${imports_ok} ${NC} | ${RED} IMPORTS NOK : ${imports_nok} | IMPORTS QUEUD : ${imports_queud}${NC}"
}

#============================================
# Check nbdevquery 🚀
#============================================
function check_nbdevquery() {
    echo -e '\n'
    echo "=================================================="
    echo -e "${Yellow} Media Server State Check : ${NC}"
    echo "=================================================="
    echo
    nbdevquery -listdp -stype PureDisk -U | grep "Storage Server" | awk '{ print $4}' > Storage_Server
    nbdevquery -listdp -stype PureDisk -U | grep "Status" | awk '{print $NF}' > Storage_Server_status
    nbdevquery -listdv -stype PureDisk -U | grep "Status" | awk '{print $NF}' > Disk_Volume_Status
    paste Storage_Server Storage_Server_status Disk_Volume_Status > Disk_Volume_Status
    paste Storage_Server Storage_Server_status Disk_Volume_Status > st_stat
    awk -F, 'NR==1 {print "Media","DiskPool","DiskVolume"}{gsub(/"/,""); print $1,$2,$3}' st_stat | column -t | sed '/^$/d; $ !G'
    rm -f Storage_Server Storage_Server_status Disk_Volume_Status st_stat
    echo
}

#============================================
# Check Backup Test
#============================================
function backup_test() {
    bpdbjobs -all_columns | awk -F","  '{$9=strftime("%Y-%m-%d %H:%M:%S", $9); $10=strftime("%M:%S", $10); $11=strftime("%Y-%m-%d %H:%M:%S", $11); print $5, $9, $11, $10, $4}' | grep "TEST_MSDP2_[srvbks]*" > allbptestjobs
    bpdbjobs -all_columns | awk -F","  '{$9=strftime("%Y-%m-%d %H:%M:%S", $9); $10=strftime("%M:%S", $10); $11=strftime("%Y-%m-%d %H:%M:%S", $11); print $5, $9, $11, $10, $4}' | grep "TEST_MSDP2_[srvbks]*"  | sort -u | awk '{print $1;}' | uniq > policiesliste
    for i in $(cat policiesliste); do grep $i allbptestjobs | head -n 1; done > backupcheck
    awk -F, 'NR==1 {{print "Policy_Name","Start_Time",".","End_Time",".","Elapsed_Time","Status"}} {gsub(/"/,""); print $0}' backupcheck | column -t | sed '/^$/d; $ !G'
    rm -f allbptestjobs policiesliste backupcheck
}

function print_test_header() {
    echo -e "========================================================"
    echo -e "Backup Check Executions ${Yellow} $(hostname) ${NC}"
    echo -e "========================================================"
    echo
}

#============================================
# Check For Option
# This section allow to use command with params
#============================================
while getopts ":hbicet" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      b) # Check for Backup
        verify_backups
        exit;;
      i) # Check for Imports
        verify_imports
        exit;;
      c) # Use nbdevquery
        check_nbdevquery
        exit;;
      e) # Engie It Test
        print_test_header
        backup_test
        check_nbdevquery
        exit;;
      t) # Check Only For Test
        print_test_header
        backup_test
        exit;;
     \?) # Invalid option
         echo "Error: Invalid option please use [-h] to get Help"
         exit;;
   esac
done


# ============================================
# If user doesn't enter any option then 
# Interactive Console
# ============================================
to_lower () {
    input="$1"
    output=$(echo $input | tr [A-Z] [a-z])
    return $output
}
while true
do
    clear
    echo -e "To continue using this script you must specify an option : ${Yellow}[h, b, i, c, e, t, q]${NC}$"
    echo
    echo
    echo "h     Print Help."
    echo "b     Print the count of Backups ( DONE | ACTIVE |FAILED | QUEUD )."
    echo "i     Print the count of Imports (OK | NOK)."
    echo "c     Check the status of MSDP, Disk Pools and Disk Volums Status [UP|DOWN]. "
    echo "t     Check the last backup test executed on current master with their state."
    echo "e     Return the state of MSDP and with last executed backup check."
    echo "l     Live Check"
    echo
    echo -e "${RED}q     Exit${NC}"
    read -sn1
    case "$REPLY" in
        h)  clear
            Help;;
        b)
            clear
            verify_backups;;
        i)
            clear
            verify_imports;;
        c)
            clear
            check_nbdevquery;;
        e)
            clear
            print_test_header
            backup_test
            check_nbdevquery;;
        t)
            clear
            print_test_header
            backup_test;;
        l)
            clear
            verify_backups
            verify_backups
            print_test_header;;
        q) exit 0;;
    esac
    read -n1 -p "Press Any Key to continue"
    rm
done

# If code had mo issue then it will return ok
exit 0
