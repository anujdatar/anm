#!/bin/bash
{
  # enclosing everything in braces to ensure entire file is downloaded
  # and intact, so there are no errors on first download/install
  
  # utility function for this
  # some text color formatting functions
  format_red() {
    ### Usage: format_dist "string", use \n at the end for linebreak ###
    echo -en "\e[31m$1\e[0m"
  }
  format_green() {
    echo -en "\e[32m$1\e[0m"
  }
  format_yellow() {
    echo -en "\e[33m$1\e[0m"
  }

  get_dist() {
    ### Usage: get_dist ####
    local filename="/etc/os-release"
    # filename="./os-release.txt"  # local copy of /etc/os-release for testing

    if [[ $(grep -i fedora $filename) ]]; then
      echo "fedora"
    elif [[ $(grep -i arch $filename) || $(grep -i manjaro $filename) ]]; then
      echo "arch"
    elif [[ $(grep -i debian $filename) ]]; then
      echo "debian"
    else
      format_red "Unable to use your system's package manager\n"
      format_red "Please check params or get in touch with the dev on GitHub\n"
      format_red "Sorry for the inconvenience. Thanks.\n"
      exit 1
    fi
  }

  yes_no_prompt() {
    ### Usage: yes_no_prompt [question] [if_yes] [if_no] ###
    local question="$1"
    local yes="$2"
    local no="$3"
    
    while true; do
      read -p "$question"

      case $REPLY in
        ""|[Yy]|[Yy][Ee][Ss]) # blank or y or yes, any case
          # eval $yes
          echo $yes
          break;;
        [Nn]|[Nn][Oo]) # n or no, any case
          # eval $no
          echo $no
          return 1
          break;;
        *)
          echo -e "Invalid input";;
        esac
    done
  }

  ############################################################################

  echo "Installing myNas to system"; echo

  ### check distro and use corresponding package manager
  dist=$(get_dist)
  if [[ $? == 1 ]]; then
    echo $dist
    text_format red "Script Error. Exiting\n"
    exit 1
  fi

  if [[ $dist == "debian" ]]; then
    dependency_list="curl wget git jq python3 python3-pip"
    update="apt-get update"
    upgrade="apt-get upgrade"
    install="apt-get install"
    check="dpkg-query -s"
  elif [[ $dist == "fedora" ]]; then
    dependency_list="curl wget git jq python3 python3-pip"
    # update="dnf check-update"
    upgrade="dnf upgrade"
    install="dnf install"
    check="dnf list installed"
  elif [[ $dist == "arch" ]]; then
    dependency_list="curl wget git jq python3 python-pip"
    # update="pacman -Sy"
    upgrade="pacman -Syu"
    install="pacman -S"
    check="pacman -Qi"
  fi

  ### update and upgrade
  echo "Updating package lists and upgrading system packages"
  if [[ $update ]]; then
    sudo $update
  fi
  sudo $upgrade

  ### check if dependencies are met, else install
  echo "Checking package dependencies"
  # dependency_list="curl wget git jq python3 python3-pip"
  not_installed=""

  for pkg in $dependency_list; do
    echo -n "Checking package: "
    format_yellow "$pkg\n"
    $check $pkg &> /dev/null

    if [[ $? == 1 ]]; then
      format_yellow "    $pkg"
      echo -n " is "
      format_red "not installed\n"
      not_installed="$not_installed $pkg"
    else
      format_yellow "    $pkg"
      echo -n " is "
      format_green "installed\n"
    fi
  done

  if [[ "$not_installed" == "" ]]; then
    echo -e "\nDependencies OK. Proceeding ..."; echo
  else
    echo -e "Need to install missing dependencies: $not_installed"; echo
    question="Would you like to install dependencies to continue? [Y]/n: "
    yes="Installing dependencies"
    no="Installation cancelled.. Bye!!"
    yes_no_prompt "$question" "$yes" "$no"
  fi

  if [[ $? == 1 ]]; then
    exit 1
  fi
  echo "Running: $install $not_installed"; echo
  sudo $install $not_installed

  if [[ $? == 1 ]]; then
    text_format red "Dependency install unsuccessful. Exiting installation\n"
    exit 1
  fi
  text_format green "Dependency install successful\n"

  if [[ $1 == 'system' ]]; then
    echo "Installing ANM for entire system"
    install_path="/opt/anm"

    echo "Install path = $install_path"
    sudo git clone https://github.com/anujdatar/anm.git ${install_path}

    chmod +x ${install_path}/anm

    echo "Adding ANM executable symlink to bin"
    sudo ln -s ${install_path}/anm /usr/bin/anm

    sudo mkdir -p ${install_path}/versions/node
  else
    echo "Installing ANM for user $USER"
    install_path="/home/$USER/.anm"

    echo "Install path = $install_path"
    git clone https://github.com/anujdatar/anm.git ${install_path}

    chmod +x ${install_path}/anm

    echo "Adding ANM executable symlink to bin"
    mkdir -p /home/$USER/.local/bin
    ln -s ${install_path}/anm /home/$USER/.local/bin/anm

    sudo mkdir -p ${install_path}/versions/node
  fi
}
