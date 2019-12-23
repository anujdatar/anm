#!/bin/bash

# contains() {
#     [[ $1 =~ (^|[[:space:]])"$2"($|[[:space:]]) ]] && exit(0) || exit(1)
# }

# contains "a b c d" "a"



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

# `list_include_item "10 11 12" "12"`  && echo "yes" || echo "no"

# if `list_include_item "10 11 12" "12"` ; then
#   echo "yes"
# else 
#   echo "no"
# fi

# check=0
# while [ $check == 0 ]
# do
#     read -p "Would you like to upgrade system? [Y]/n: " yes_no
#     if `list_include_item "y Y n N  " $yes_no`; then
#         check=1
#         echo aaaaaaa
#     else
#         echo Invalin input
#     fi

# done

check=0
while [ $check == 0 ]
do
    read -p "Would you like to upgrade system? [Y]/n: " yes_no
    if [[ "y Y n N  " =~ (^|[[:space:]])"$yes_no"($|[[:space:]]) ]]; then
        check=1
        echo aaaaaaa
    else
        echo Invalin input
    fi

done


# if [ "$yes_no" == "y" ] || [ "$yes_no" == "Y" ] || [ "$yes_no" == "" ]; then
#     printf "upgrade installed packages\n"
#     printf "UNCOMMENT NEXT LINE TO INCLIDE UPDATE && UPGRADE \n\n"
#     # sudo apt update && sudo apt upgrade -y
# elif [ "$yes_no" == "n" ] || [ "$yes_no" == "N" ]; then
#     printf "Upgrade skipped ..."
# else
#     while
#     do
#     done
# fi
