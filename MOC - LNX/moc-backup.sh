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
function verify_backups() {
    done=$(
        bpdbjobs -most_columns -t "$filter_date_time" |
        awk -F "," '$5!~"TEST" && $2==0 && $3==3 {count++} END {print count}'
    )
    active=$(
        bpdbjobs -most_columns -t "$filter_date_time" |
        awk -F "," '$5!~"TEST" && $2==0 && $3==1 {countA++;} END {print countA}'
    )
    failed=$(
        bpdbjobs -most_columns -t "$filter_date_time" |  
        awk -F "," '$5!~"TEST" && ($2==0 || $2==28 || $2==22) && $3==3 && $4>1 {countF++;} END {print countF}'
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

    #=======================================
    # print Output
    echo
    echo -e "BACKUPS Check Count : "
    echo -e "\n"
    echo -e "DONE : ${done} |  Active :  ${active} | Failed : ${failed} | QUEUD : ${queud} "
    echo -e "\n"
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