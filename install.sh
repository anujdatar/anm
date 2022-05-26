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
          echo $yes
          break;;
        [Nn]|[Nn][Oo]) # n or no, any case
          echo $no
          return 1
          break;;
        *)
          echo -e "Invalid input";;
        esac
    done
  }

  ############################################################################

  echo -e "Installing ANM to system\n\n"

  ### check distro and use corresponding package manager
  dist=$(get_dist)
  if [[ $? == 1 ]]; then
    echo $dist
    format_red "Script Error. Exiting\n"
    exit 1
  fi

  if [[ $dist == "debian" ]]; then
    dependency_list="curl wget git jq python3 python3-pip"
    update="apt-get update"
    upgrade="apt-get upgrade -y"
    install="apt-get install -y"
    check="dpkg-query -s"
  elif [[ $dist == "fedora" ]]; then
    dependency_list="curl wget git jq python3 python3-pip"
    upgrade="dnf upgrade -y"
    install="dnf install -y"
    check="dnf list installed"
  elif [[ $dist == "arch" ]]; then
    dependency_list="curl wget git jq python3 python-pip"
    upgrade="pacman -Syu --noconfirm"
    install="pacman -S --noconfirm"
    check="pacman -Qi"
  fi

  ### update and upgrade
  echo -e "\nUpdating package lists and upgrading system packages\n"
  if [[ $update ]]; then
    sudo $update
  fi
  sudo $upgrade

  ### check if dependencies are met, else install
  echo -e "\nChecking package dependencies\n"
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
    echo -e "\nDependencies OK. Proceeding ...\n"
  else
    echo -e "Need to install missing dependencies: $not_installed \n"
    question="Would you like to install dependencies to continue? [Y]/n: "
    yes="Installing dependencies"
    no="Installation cancelled.. Bye!!"
    yes_no_prompt "$question" "$yes" "$no"

    if [[ $? == 1 ]]; then
      exit 1
    fi
    echo -e "\nRunning: $install $not_installed\n"
    sudo $install $not_installed

    if [[ $? == 1 ]]; then
      format_red "Dependency install unsuccessful. Exiting installation\n"
      exit 1
    fi
    format_green "Dependency install successful\n"
  fi

  echo -e "\nInstalling pip dependencies: packaging\n"
  pip3 install packaging

  if [[ $1 == 'system' ]]; then
    echo -e "\nInstalling ANM for entire system\n"
    install_path="/opt/anm"
    bin_path="/usr/bin"

    echo "Install path = $install_path"
  else
    echo -e "\nInstalling ANM for user $USER\n"

    install_path="$HOME/.anm"
    bin_path="$HOME/.local/bin"

    echo "Install path = $install_path"

    if ! [[ "$PATH" =~ "$HOME/.local/bin" ]]; then
      if [[ "$SHELL" =~ "bash" ]]; then
        RC_FILE="$HOME/.bashrc"
      elif [[ "$SHELL" =~ "zsh" ]]; then
        RC_FILE="$HOME/.zshrc"
      else
        RC_FILE="$HOME/.profile"
      fi

      MESSAGE=$(printf "%s\n" '# User specific environment\n'\
        'if ! [[ "$PATH" =~ "$HOME/.local/bin" ]]; then\n'\
        'PATH="$HOME/.local/bin:$PATH"\n'\
        'fi\n'\
        'export PATH\n'
      )

      echo "Adding $HOME/.local/bin to path, adding the following to $RC_FILE"
      format_yellow $MESSAGE; echo
      echo "Works for Bash, Zsh. Please add $HOME/.profile to you rc file for other shells"

      echo -e $MESSAGE >> $RC_FILE
    fi
  fi

  is_sudo() {
    if [[ $install_path == "/opt/anm" ]]; then
      sudo $@
    else
      $@
    fi
  }

  is_sudo git clone https://github.com/anujdatar/anm.git ${install_path}

  is_sudo chmod +x ${install_path}/anm.sh

  echo -e "\nAdding ANM executable symlink to bin\n"
  is_sudo mkdir -p ${bin_path}
  is_sudo ln -s ${install_path}/anm.sh ${bin_path}/anm

  is_sudo mkdir -p ${install_path}/versions/node
  is_sudo touch ${install_path}/active
  is_sudo touch ${install_path}/installed
}
