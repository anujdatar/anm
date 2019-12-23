#!/bin/bash


# sys and nodejs arch detection
function get_sys_node_arch() {
  sys_arch=$(dpkg --print-architecture)

  if [ "$sys_arch" == "armhf" ]
  then
    node_arch="linux-armv7l"
  elif [ "$sys_arch" == "arm64" ] || [ "$sys_arch" == "aarch64" ]
  then
    node_arch="linux-arm64"
  elif [ "$sys_arch" == "amd64" ]
  then
    node_arch="linux-x64"
  fi

  echo $node_arch
}

function yes_no_response() {
  read -p "Would you like to proceed? [Y]/n: " yes_no
  if [ "$yes_no" == "n" ]; then
    printf "Exiting installation. Bye!!\n"
  elif [ "$yes_no" == "y" ] || [ "$yes_no" == "Y" ]; then
    printf "\nInstalling missing dependencies ...\n"
  else
    echo "Invalid input"
  fi
}

function check_depencency() {
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
    user_input="Invalid input"
    first=0
    while [ "$user_input" == "Invalid input" ]
    do 
      user_input=$(yes_no_response $first)
      echo $user_input
    done
  fi
}

# silence dependency check function output comment out after testing
# check_depencency > /dev/null

# echo $not_installed
nodejs_dist_index="https://nodejs.org/dist/index.json"
# nodejs_dist_index=$(curl -s https://nodejs.org/dist/index.json)

# python3 web_json_parse.py $nodejs_dist_index $node_arch
function ls_all() {
  python3 web_json_parse.py $nodejs_dist_index $node_arch "ls_all"
}
function ls_lts() {
  python3 web_json_parse.py $nodejs_dist_index $node_arch "ls_lts"
}
function ls_latest() {
  python3 web_json_parse.py $nodejs_dist_index $node_arch "ls_latest"
}
function test() {
  python3 web_json_parse.py $nodejs_dist_index $node_arch
}
function latest_lts_version_by_name() {
  python3 web_json_parse.py $nodejs_dist_index $node_arch "lts_latest" $1
}

function anm() {
  get_sys_node_arch
  check_depencency

  if [ "$1" == "ls" ]; then
    if [ "$2" == "" ]; then
      ls_all
    elif [ "$2" == "--lts" ]; then
      ls_lts
    elif [ "$2" == "--latest" ]; then
      ls_latest
    fi
  elif [[ "$1" == "install" ]]; then
    response=$(latest_lts_version_by_name $2)
    if [ "$response" == "-1" ]; then
      echo "Error!! Invalid LTS version name: $2"
    fi
  elif [[ "$1" == "test" ]]; then
    test
  fi
}

# anm ls --lts
anm test
