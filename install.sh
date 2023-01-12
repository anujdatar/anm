#!/bin/bash
{
  # enclosing everything in braces to ensure entire file is downloaded
  # and intact, so there are no errors on first download/install

  ####################  utility functions ######################
  # OS detection functions
  linux() { [[ "$OSTYPE" == "linux-gnu"* ]]; }
  darwin() { [[ "$OSTYPE" == "darwin"* ]]; }
  cygwin() { [[ "$OSTYPE" == "cygwin"* ]]; }
  mingw() { [[ "$OSTYPE" == "msys"* ]]; }
  windows() { [ -n "$WINDIR" ]; }

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

  symlink() {
    ### Create symbolic links ###
    ### Usage: mklink "original-path" "link-path" ###
    if windows; then
      target=$(cygpath -w $1)
      link=$(cygpath -w $2)
      if [ -d "$target" ]; then
        cmd <<< "mklink /D $link $target" > /dev/null
      else
        cmd <<< "mklink $link $target" > /dev/null
      fi
    else
      ln -s "$1" "$2"
    fi
  }

  get_dist() {
    ### Usage: get_dist ####
    local filename="/etc/os-release"

    if [[ $(grep -i fedora "$filename") ]]; then
      echo "fedora"
    elif [[ $(grep -i arch "$filename") || $(grep -i manjaro $filename) ]]; then
      echo "arch"
    elif [[ $(grep -i debian "$filename") ]]; then
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
  ##############################################################
  if linux; then
    # update linux system packages, and install dependencies
    dist=$(get_dist)
    if [ "$?" = 1 ]; then
      echo "$dist"
      format_red "Script Error. Exiting\n"
      exit 1
    fi

    if [ "$dist" = "debian" ]; then
      dependency_list="curl wget git python3 python3-pip"
      update="apt-get update"
      upgrade="apt-get upgrade -y"
      install="apt-get install -y"
      check="dpkg-query -s"
    elif [ "$dist" = "fedora" ]; then
      dependency_list="curl wget git python3 python3-pip"
      upgrade="dnf upgrade -y"
      install="dnf install -y"
      check="dnf list installed"
    elif [ "$dist" = "arch" ]; then
      dependency_list="curl wget git python3 python-pip"
      upgrade="pacman -Syu --noconfirm"
      install="pacman -S --noconfirm"
      check="pacman -Qi"
    fi

    # update and upgrade
    echo -e "\nUpdating package lists and upgrading system packages\n"
    if [ "$update" ]; then
      sudo $update
    fi
    sudo $upgrade

    # check if dependencies are met
    echo -e "\nChecking package dependencies\n"
    not_installed=""

    for pkg in $dependency_list; do
      echo -n "Checking package: "
      format_yellow "$pkg\n"
      $check $pkg &> /dev/null

      if [ "$?" = 1 ]; then
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

    # install missing dependencies
    if [ "$not_installed" = "" ]; then
      echo -e "\nDependencies OK. Proceeding ...\n"
    else
      echo -e "Need to install missing dependencies: $not_installed \n"
      question="Would you like to install dependencies to continue? [Y]/n: "
      yes="Installing dependencies"
      no="Installation cancelled.. Bye!!"
      yes_no_prompt "$question" "$yes" "$no"

      if [ "$?" = 1 ]; then
        exit 1
      fi
      echo -e "\nRunning: $install $not_installed\n"
      sudo $install $not_installed

      if [ "$?" = 1 ]; then
        format_red "Dependency install unsuccessful. Exiting installation\n"
        exit 1
      fi
      format_green "Dependency install successful\n"
    fi
  fi

  # set install path and rc_file location
  install_path="$HOME/.anm"
  # RC_FILE="$HOME/.bashrc"

  case "$SHELL" in
    *bash*) RC_FILE="$HOME/.bashrc";;
    *zsh*) RC_FILE="$HOME/.zshrc";;
    *) RC_FILE="$HOME/.profile";;
  esac

  if cygwin; then
    echo "Cygwin detected, setting up for Windows+Cygwin"
    install_path="/cygdrive/c/Users/$USER/.anm"
  fi
  if linux; then
    if [ "$1" = "system" ]; then
      echo "Installing ANM for all users"
      install_path="/opt/anm"
      RC_FILE="/etc/profile.d/anm_profile.sh"
    else
      echo "Installing ANM for user $USER"
    fi
  else
    echo "Installing ANM for user $USER"
  fi

  is_sudo() {
    ### check if sudo is required for install
    ### Usage: is_sudo [command...]
    if windows; then
      $@
    else
      if [ -w "$(dirname $install_path)" ]; then
        $@
      else
        sudo $@
      fi
    fi
  }
  add_to_rc() {
    ### add string to rc-file
    ### Usage: add_to_rc [string]
    echo $1 | is_sudo tee -a $RC_FILE
  }

  # install pip dependencies
  echo "Installing pip dependencies: packaging urllib3"
  pip3 install packaging urllib3

  # check pwd and clone Git repo if necessary
  if [ -f "$(pwd)/anm.sh" ]; then
    install_path="$(pwd)"
  else
    is_sudo git clone https://github.com/anujdatar/anm.git ${install_path}
  fi

  echo "ANM install path: $install_path"

  # add bin path and ANM_DIR to rc file
  if ! [[ "$PATH" =~ "$install_path/bin" ]]; then
    echo "Adding $install_path/bin to path, added the following to $RC_FILE"

    add_to_rc "# >>>>>>>> Block added by ANM install >>>>>>>>"
    add_to_rc "if ! [[ \"\$PATH\" =~ \"$install_path/bin\" ]]; then"
    add_to_rc "[ -d \"$install_path/bin\" ] && export PATH=\"$install_path/bin:\$PATH\""
    add_to_rc "fi"

    add_to_rc "if ! [[ \"\$PATH\" =~ \"$install_path/versions/current\" ]]; then"
    add_to_rc "[ -d \"$install_path/bin\" ] && export PATH=\"$install_path/versions/current:\$PATH\""
    add_to_rc "fi"

    add_to_rc "if [ -d \"$install_path\" ]; then export ANM_DIR=\"$install_path\"; fi"
    add_to_rc "# >>>>>>>>>>>>>> End ANM block >>>>>>>>>>>>>>>"

    echo -e "\nShould work directly for Bash, Zsh, and Git Bash for windows"
    echo "For other shells (on Linux), please ensure $HOME/.profile is included in rc file"
  fi

  # make sure anm.sh is executable
  is_sudo chmod +x ${install_path}/anm.sh

  echo "Adding ANM executable symlink to bin"; echo
  is_sudo mkdir -p ${install_path}/bin
  is_sudo symlink "${install_path}/anm.sh" "${install_path}/bin/anm"

  is_sudo mkdir -p ${install_path}/versions/node
  is_sudo touch ${install_path}/active
  is_sudo touch ${install_path}/installed
}
