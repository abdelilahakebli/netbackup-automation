#!/bin/bash
clear

# Print Header
function Header() {
    today=`date '+%D %H:%M'`
    echo -e "======================================================="
    echo -e "Script Started AT :  $today  Server :  $(hostname) "
    echo -e "======================================================="
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
function verify_imports() {
    imports_ok=$(
        bpdbjobs -most_columns  -t $filter_date_time | 
        awk -F "," '$5!~"TEST" && $2==21 && $3==3 {countA++;} END {print countA}')
    imports_nok=$(bpdbjobs -most_columns  -t $filter_date_time | 
        awk -F "," '$5!~"TEST" && $2==21 && $3==3 && $4>0 {countA++;} END {print countA}')
    imports_queud=$(
        bpdbjobs -most_columns -t "$filter_date_time" |
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

    echo -e "\n"
    echo -e "IMPORTS Check Count : "
    echo -e "\n"
    echo -e "${BLUE} IMPORTS OK : ${imports_ok}  |  IMPORTS NOK : ${imports_nok} | IMPORTS QUEUD : ${imports_queud}"
}
#============================================
# Check nbdevquery 🚀
#============================================
function nbdevquery_func() {
    echo -e "======================================================="
    echo -e "           Check Status Of DP and DV"
    echo -e "======================================================="
    echo -e '-------------- [ storage Server ] -------------- \n'; 
    nbdevquery -listdp -stype PureDisk -U | grep "Storage Server";

    echo -e '\n-------------- [ storage Server status ]--------------\n'; 
    nbdevquery -listdp -stype PureDisk -U | grep "Status";

    echo -e '\n-------------- [ Disk Volume Status ]--------------\n'; 
    nbdevquery -listdv -stype PureDisk -U | grep "Status";
}

#============================================
# Main Programme
#============================================
# 1 - Print Header
Header

# 2 - Get Data 
verify_backups

# 3 - Print DP and DV Status
nbdevquery_func