#!/bin/bash

# *************** do system upgrade ***************
check=0
while [ $check == 0 ]
do
    read -p "Would you like to update system? [Y]/n: " yes_no
    if [[ "y Y n N  " =~ (^|[[:space:]])"$yes_no"($|[[:space:]]) ]]; then
        check=1
    else
        printf "Invalid input\n"
    fi
done

if [ "$yes_no" == "n" ] || [ "$yes_no" == "N" ]; then
    printf "Upgrade skipped ...\n"
else
    printf "Upgrading installed packages\n"
    printf "UNCOMMENT NEXT LINE TO INCLIDE UPDATE && UPGRADE \n\n"
    # sudo apt update && sudo apt upgrade -y
fi
# *****************************************************

# ********** check program dependencies ***************
printf "checking dependencies ...\n"
dependency="curl wget git jq python3 nodejs npm"

not_installed=""
for pkg in $dependency
do
PKG_OK=$(dpkg-query -W -f='${Status}\n' $pkg 2>/dev/null)
printf "Checking $pkg: "
if [ "$PKG_OK" == "" ]; then
  printf "$pkg is not installed.\n"
  not_installed="$not_installed $pkg"
else
  printf "Installed \n"
fi
done

if [ "$not_installed" == "" ]; then
    printf "\nDependencies OK. Proceeding ...\n"
else
    printf "Need to install missing dependencies: $not_installed\n"
    check=0
    while [ $check == 0 ]
    do
        read -p "Would you like to install dependencies to continue? [Y]/n: " yes_no
        if [[ "y Y n N  " =~ (^|[[:space:]])"$yes_no"($|[[:space:]]) ]]; then
            check=1
        else
            printf "Invalid input\n"
        fi
    done
fi

if [ "$yes_no" == "n" ] || [ "$yes_no" == "N" ]; then
    printf "Installation cancelled.. Bye!!\n"
    exit 0
else
    printf "Installing dependencies\n"
    printf "UNCOMMENT NEXT LINE TO INCLIDE install dependencies \n\n"
    # sudo apt install $not_installed
fi
# ******************************************************

# echo $(pwd)
# echo "${XDG_CONFIG_HOME}"
# echo "${HOME}/.anm"

# *********** copy anm folder to $HOME *****************
anm_install_dir="${HOME}/.anm"
printf "$anm_install_dir\n"
printf "Installing Arm Node Manager\n"
# cp -r $(pwd) $anm_install_dir
# if [[ -e $anm_install_dir ]]; then
#     printf "anm installed"
# else
#     printf "anm not installed"
# fi
# # ******************************************************

# ************** copy settings into bashrc **************
check=0
while [ $check == 0 ]
do
    read -p "Would you like installer to initialize ANM? [Y]/n: " yes_no
    if [[ "y Y n N  " =~ (^|[[:space:]])"$yes_no"($|[[:space:]]) ]]; then
        check=1
    else
        printf "Invalid input\n"
    fi
done

if [ "$yes_no" == "n" ] || [ "$yes_no" == "N" ]; then
    printf "Initialization skipped ...\n"
else
    printf "Initializing nvm ...\n"
    # echo dddddd >> a.txt
    # bashrc_file="$HOME/.bashrc"
    bashrc_file="a.txt"

    # create bashrc backup
    cp "$bashrc_file" "$bashrc_file.anm.bak"

    printf '\n>>>>> ANM initialization >>>>>\n' >> $bashrc_file
    printf 'export ANM_DIR="$HOME/.anm"\n' >> $bashrc_file
    printf '[ -s "$ANM_DIR/anm.sh" ] && \. "$ANM_DIR/anm.sh"\n' >> $bashrc_file
    printf '<<<<< ANM initialization <<<<<\n' >> $bashrc_file
fi

printf "Installation complete. Bye!!\n"
