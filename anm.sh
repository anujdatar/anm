#!/bin/bash

node_dist_index="https://nodejs.org/dist/index.json"

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

get_sys_node_arch() {
  ### get system arch, return strings that nodejs website uses ###
  case $(uname -m) in
    x86_64)
      node_arch="linux-x64";;
    aarch64|arm64)
      node_arch="linux-arm64";;
    armhf)
      node_arch="linux-armv7l";;
    *)
      format_red "Unable to recognize system architecture\n"
      format_red "Please contact developer on GitHub for solution\n"
      exit 1;;
  esac
}

get_sys_node_arch
if [[ $? == 1 ]]; then
  format_red "System OS and architecture not supported by ANM\n"
  format_red "Please check compatibility or contact developer\n"
  exit 1
fi

get_download_link() {
  if [[ $1 == "" ]]; then
    format_red "No node version provided for download\n"
    exit 1
  fi
  local base_link="https://nodejs.org/dist"
  local version_page="$base_link/$1"
  local download_filename="node-$1-$node_arch.tar.xz"
  local download_link="$version_page/$download_filename"
  echo $download_link
}
get_lts_download_link() {
  local base_link="https://nodejs.org/dist"
  local version_page="$base_link/latest-$1"
  local download_filename="node-$2-$node_arch.tar.xz"
  local download_link="$version_page/$download_filename"
  echo $download_link
}

get_anm_install_location() {
  local executable_path=$(which anm)

  if [[ $executable_path == "/usr/bin/anm" ]]; then
    echo "/opt/anm"
  else
    echo "/home/$USER/.anm"
  fi
}
get_bin_path() {
  local install_path=$(get_anm_install_location)
  
  if [[ $install_path == "/opt/anm" ]]; then
    echo "/usr/bin"
  else
    echo "/home/$USER/.local/bin"
  fi
}

python_script_path=$(get_anm_install_location)/web_json_parse.py

ls_all() {
  python3 $python_script_path $node_dist_index $node_arch "ls_all"
}
ls_lts() {
  python3 $python_script_path $node_dist_index $node_arch "ls_lts"
}
ls_latest() {
  python3 $python_script_path $node_dist_index $node_arch "ls_latest"
}
ls_latest_lts_version_data_by_name() {
  python3 $python_script_path $node_dist_index $node_arch "lts_latest_data" $1
}
latest_lts_version_number() {
  python3 $python_script_path $node_dist_index $node_arch "latest_version_number" $1
}

anm_ls_remote() {
  case $1 in
    "--lts")
      if [[ $2 ]]; then
        ls_latest_lts_version_data_by_name $2
      else
        ls_lts
      fi;;
    "--latest")
      ls_latest;;
    "")
      ls_all;;
  esac
}

is_sudo() {
  local install_path=$(get_anm_install_location)
  if [[ $install_path == "/opt/anm" ]]; then
    sudo $@
  else
    $@
  fi
}

anm_activate() {
  local version=$1

  local install_path=$(get_anm_install_location)
  local bin_path=$(get_bin_path)

  local binary_folder="$install_path/versions/node/$version/bin"

  is_sudo mkdir -p $bin_path

  is_sudo ln -s $binary_folder/node $bin_path/node
  is_sudo ln -s $binary_folder/npm $bin_path/npm
  is_sudo ln -s $binary_folder/npx $bin_path/npx
}

anm_install() {
  local version=""
  case $1 in
    "")
      version=$(python3 $python_script_path $node_dist_index $node_arch "latest_version_number" "");;
    "--lts")
      if [[ $2 ]]; then
        lts_name=$(echo "$2" | tr '[:upper:]' '[:lower:]')
        version=$(latest_version_number $lts_name)
      else
        version=$(python3 $python_script_path $node_dist_index $node_arch "latest_version_number" "latest_lts")
      fi;;
    *)
      version="$2"
  esac

  if [[ $? == 1 ]]; then
    format_red "Unable to find version: $2\n"
    exit 1
  fi

  anm_dir=$(get_anm_install_location)
  node_install_dir="$anm_dir/versions/node/$version"

  if [[ -d node_install_dir ]]; then
    format_yellow "NodeJs release: $version is already installed"
    exit 1
  fi

  is_sudo mkdir -p "$node_install_dir"

  download_filename="node-$version-$node_arch.tar.xz"
  download_link=$(get_download_link $version)

  # if ! wget -q --method=HEAD $download_link; then
  if ! curl --output /dev/null --silent --head --fail "$download_link"; then
    format_red "Incorrect download link for node.js version\n"
    format_yellow "If you think this is an error, please contact dev on GitHub\n"
    echo $download_link 
    exit 1
  fi

  echo
  echo "Downloading nodejs version: $version from"
  echo "$download_link"; echo
  wget -O "/tmp/$download_filename" $download_link
    
  echo "Extracting nodejs to $anm_dir"
  is_sudo tar -xf "/tmp/$download_filename" -C $node_install_dir --strip-components=1


  anm_activate $version
}

anm_uninstall() {
  local version=$1

  local install_path=$(get_anm_install_location)
  local bin_path=$(get_bin_path)

  if [[ -d $install_path/versions/node/$version ]]; then
    echo "Uninstalling node version: $version"
    is_sudo rm $bin_path/node $bin_path/npm $bin_path/npx
    is_sudo rm -rf $install_path/versions/node/$version
  else
    echo "Node version: $version not installed"
    exit 1
  fi
}

print_help() {
  echo "Trust me I am helping here"
}

anm() {
  case $1 in
    "ls-remote")
      shift
      anm_ls_remote $@;;
    "install")
      shift
      anm_install $@;;
    "uninstall")
      shift
      anm_uninstall $@;;
    *)
      echo "Unknown option"
      print_help
      exit 1;;
  esac
}
anm $@
