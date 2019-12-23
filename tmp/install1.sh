#!/bin/bash

# list_include_item "10 11 12" "2"
# function list_include_item {
#   local list="$1"
#   local item="$2"
#   if [[ $list =~ (^|[[:space:]])"$item"($|[[:space:]]) ]] ; then
#     result=0
#   else
#     result=1
#   fi
#   return $result
# }


function yes_no_response() {
    local check=0
    local question=$1
    local response_list=$2

    while [ $check == 0 ]
    do
        read -p "$question" response
        if [[ $response_list =~ (^|[[:space:]])"$response"($|[[:space:]]) ]]; then
            check=1
        else
            printf "Invalid input\n"
        fi
    done
}

yes_no_response "Would you like to update system? [Y]/n: " "y Y n N  "

# check=0
# while [ $check == 0 ]
# do
#     read -p "Would you like to update system? [Y]/n: " yes_no
#     if [[ "y Y n N  " =~ (^|[[:space:]])"$yes_no"($|[[:space:]]) ]]; then
#         check=1
#     else
#         printf "Invalin input\n"
#     fi
# done

# if [ "$yes_no" == "n" ] || [ "$yes_no" == "N" ]; then
#     printf "Upgrade skipped ..."
# else
#     printf "Upgrading installed packages\n"
#     printf "UNCOMMENT NEXT LINE TO INCLIDE UPDATE && UPGRADE \n\n"
#     # sudo apt update && sudo apt upgrade -y
# fi


# printf "checking dependencies ...\n"
# dependency="curl wget git jq python3 nodejs npm"

# not_installed=""
# for pkg in $dependency
# do
# PKG_OK=$(dpkg-query -W -f='${Status}\n' $pkg 2>/dev/null)
# printf "Checking $pkg: "
# if [ "$PKG_OK" == "" ]; then
#   printf "$pkg is not installed.\n"
#   not_installed="$not_installed $pkg"
# else
#   printf "Installed \n"
# fi
# done

# if [ "$not_installed" == "" ]; then
# printf "\nDependencies OK. Proceeding ...\n"
# else
# printf "Need to install missing dependencies: $not_installed\n"
# check=0
# while [ $check == 0 ]
# do
#     read -p "Would you like to install dependencies to continue? [Y]/n: " yes_no
#     if [[ "y Y n N  " =~ (^|[[:space:]])"$yes_no"($|[[:space:]]) ]]; then
#         check=1
#     else
#         printf "Invalin input\n"
#     fi
# done



# user_input="Invalid input"
# first=0
# while [ "$user_input" == "Invalid input" ]
# do 
#   user_input=$(yes_no_response $first)
#   echo $user_input
# done
# fi
