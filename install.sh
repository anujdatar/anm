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

  # test if system is running windows
  windows() { [[ -n "$WINDIR" ]]; }
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

  ############################################################################

  echo -e "Installing ANM to system\n"

  if [[ "$OSTYPE" = "msys" ]]; then
    # check for Windows
    echo "MinGW on WINDOWS detected. Setting up for Windows"

    install_path="$HOME/.anm"

    RC_FILE="$HOME/.bashrc"

  else
    # for Linux/Unix based systems

    ### check distro and use corresponding package manager
    dist=$(get_dist)
    if [ "$?" = 1 ]; then
      echo "$dist"
      format_red "Script Error. Exiting\n"
      exit 1
    fi

    if [ "$dist" = "debian" ]; then
      dependency_list="curl wget git jq python3 python3-pip"
      update="apt-get update"
      upgrade="apt-get upgrade -y"
      install="apt-get install -y"
      check="dpkg-query -s"
    elif [ "$dist" = "fedora" ]; then
      dependency_list="curl wget git jq python3 python3-pip"
      upgrade="dnf upgrade -y"
      install="dnf install -y"
      check="dnf list installed"
    elif [ "$dist" = "arch" ]; then
      dependency_list="curl wget git jq python3 python-pip"
      upgrade="pacman -Syu --noconfirm"
      install="pacman -S --noconfirm"
      check="pacman -Qi"
    fi

    ### update and upgrade
    echo -e "\nUpdating package lists and upgrading system packages\n"
    if [ "$update" ]; then
      sudo $update
    fi
    sudo $upgrade

    ### check if dependencies are met
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

    ### install missing dependencies
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

    ### set install and bin path for linux
    if [ "$1" = "system" ]; then
      echo -e "\nInstalling ANM for all users\n"
      install_path="/opt/anm"

      echo "Install path = $install_path"
      RC_FILE="/etc/profile.d/anm_profile.sh"
    else
      echo -e "\nInstalling ANM for user $USER\n"

      install_path="$HOME/.anm"

      if [[ "$SHELL" =~ "bash" ]]; then
        RC_FILE="$HOME/.bashrc"
      elif [[ "$SHELL" =~ "zsh" ]]; then
        RC_FILE="$HOME/.zshrc"
      else
        RC_FILE="$HOME/.profile"
      fi
    fi
  fi

  # function to check if sudo is required for install
  is_sudo() {
    if [[ "$OSTYPE" = "msys" ]]; then
      $@
    else
      if [ -w "$(dirname $install_path)" ]; then
        $@
      else
        sudo $@
      fi
    fi
  }

  # install pip dependency
  echo -e "\nInstalling pip dependencies: packaging\n"
  pip3 install packaging urllib3

  # check pwd and clone Git repo if necessary
  if [ -f "$(pwd)/anm.sh" ]; then
    install_path="$(pwd)"
  else
    is_sudo git clone https://github.com/anujdatar/anm.git ${install_path}
  fi

  echo "ANM install path: $install_path"

  ## add bin path and ANM_DIR to rc file
  if ! [[ "$PATH" =~ "$install_path/bin" ]]; then

    MESSAGE=$(printf "%s\n"\
    "if ! [[ \"\$PATH\" =~ \"$install_path/bin\" ]]; then\n"\
    "[ -d \"$install_path/bin\" ] && export PATH=\"$install_path/bin:\$PATH\"\n"\
    "fi"
    )

    echo -e "\nAdding $install_path/bin to path, added the following to $RC_FILE"
    echo -e "\n# Block added by ANM install >>>>>>>>>>>>"
    echo -e $MESSAGE
    echo "if [ -d \"$install_path\" ]; then export ANM_DIR=\"$install_path\"; fi"
    echo "# >>>>>>>>>>>>>> End ANM block >>>>>>>>>>>>>>>"
    echo -e "\nShould work directly for Bash, Zsh, and Git Bash for windows"
    echo "For other shells (on Linux), please ensure $HOME/.profile is included in rc file"

  fi

  echo -e "\n# Block added by ANM install >>>>>>>>>>>>" >> $RC_FILE

  echo -e $MESSAGE >> $RC_FILE

  echo "if [ -d \"$install_path\" ]; then export ANM_DIR=\"$install_path\"; fi" | \
  is_sudo tee -a $RC_FILE &> /dev/null

  echo "# >>>>>>>>>>>>>> End ANM block >>>>>>>>>>>>>>>" >> $RC_FILE

  # make sure anm is executable
  is_sudo chmod +x ${install_path}/anm.sh

  echo -e "\nAdding ANM executable symlink to bin\n"
  is_sudo mkdir -p ${install_path}/bin
  is_sudo ln -s ${install_path}/anm.sh ${install_path}/bin/anm

  is_sudo mkdir -p ${install_path}/versions/node
  is_sudo touch ${install_path}/active
  is_sudo touch ${install_path}/installed
}
