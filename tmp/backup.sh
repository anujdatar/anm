#!/bin/bash

# update && upgrade
printf "upgrade installed packages\n"
printf "UNCOMMENT NEXT LINE TO INCLIDE UPDATE && UPGRADE \n\n"
# sudo apt update && sudo apt upgrade -y

# sys and nodejs arch detection
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

printf "os architecture: $sys_arch\n"
printf "nodejs architecture: $node_arch \n\n"

# dependency check
printf "Checking dependencies ...\n"
dependency="curl wget git jq python3 nodejs npm"

uninstalled=""
for pkg in $dependency
do 
  PKG_OK=$(dpkg-query -W -f='${Status}\n' $pkg 2>/dev/null)
  printf "Checking $pkg: "
  if [ "$PKG_OK" == "" ]; then
    printf "$pkg not installed. \n"
    uninstalled="$uninstalled $pkg"
  else
    printf "Installed \n"
  fi
done

if [ "$uninstalled" == "" ]; then
  printf "\nDependencies OK. Proceeding..\n"
else
  printf "\nInstalling missing dependencies ...\n"
  printf "$uninstalled \n\n"
  # sudo apt install $uninstalled
fi

nodejs_dist_index="https://nodejs.org/dist/index.json"
# nodejs_dist_index=$(curl -s https://nodejs.org/dist/index.json)

python3 web_json_parse.py $nodejs_dist_index $node_arch

function test1() {
  echo test1 successful
}