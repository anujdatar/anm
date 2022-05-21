#!/bin/bash

ANM_VERSION="1.0.0"

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
  elif [[ $executable_path == "/home/$USER/.local/bin/anm" ]]; then
    echo "/home/$USER/.anm"
  else
    echo $(pwd)
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

anm_ls() {
  local install_path=$(get_anm_install_location)
  local current_installed=$(cat $install_path/installed | sort -V -r)
  local current_active=$(cat $install_path/active)

  for installed in $current_installed; do
    if [[ $installed == $current_active ]]; then
      format_green "$installed"; echo " (active)"
    else
      echo $installed
    fi
  done
}

is_sudo() {
  local install_path=$(get_anm_install_location)
  if [[ $install_path == "/opt/anm" ]]; then
    sudo $@
  else
    $@
  fi
}

anm_deactivate() {
  local version=$1

  if [[ $version == "" ]]; then
    echo No version active currently
    return 0
  fi

  local install_path=$(get_anm_install_location)
  local current_active=$(cat $install_path/active)
  local bin_path=$(get_bin_path)

  if [[ $current_active == $version ]]; then
    echo "Deactivating current version of NodeJs: $version"
    echo "" | is_sudo tee "" $install_path/active &> /dev/null

    if [[ -f $bin_path/node ]]; then
      echo "Deleting node from bin"
      is_sudo rm $bin_path/node
    fi
    if [[ -f $bin_path/npm ]]; then
      echo "Deleting npm from bin"
      is_sudo  rm $bin_path/npm
    fi
    if [[ -f $bin_path/npx ]]; then
      echo "Deleting npx from bin"
      is_sudo rm $bin_path/npx
    fi
  fi
}

anm_activate() {
  local version=$1

  local install_path=$(get_anm_install_location)
  local bin_path=$(get_bin_path)

  local current_active=$(cat $install_path/active)

  local binary_folder="$install_path/versions/node/$version/bin"

  is_sudo mkdir -p $bin_path

  anm_deactivate $current_active

  echo "Activating NodeJs version: $version"

  is_sudo ln -s $binary_folder/node $bin_path/node
  is_sudo ln -s $binary_folder/npm $bin_path/npm
  is_sudo ln -s $binary_folder/npx $bin_path/npx

  if [[ $? != 1 ]]; then
    echo $version | is_sudo tee $install_path/active &> /dev/null
  fi
}

anm_install() {
  local version=""
  case $1 in
    "")
      version=$(python3 $python_script_path $node_dist_index $node_arch "latest_version_number" "");;
    "--lts")
      if [[ $2 ]]; then
        lts_name=$(echo "$2" | tr '[:upper:]' '[:lower:]')
        version=$(python3 $python_script_path $node_dist_index $node_arch "latest_version_number" $lts_name)
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

  echo "Extracting nodejs to $node_install_dir"
  is_sudo tar -xf "/tmp/$download_filename" -C $node_install_dir --strip-components=1

  echo $version | is_sudo tee -a $anm_dir/installed &> /dev/null

  anm_activate $version
}

anm_uninstall() {
  local version=$1

  local install_path=$(get_anm_install_location)
  # local current_active=$(cat $install_path/active)
  local bin_path=$(get_bin_path)

  if [[ -d $install_path/versions/node/$version ]]; then
    echo "Uninstalling node version: $version"
    # is_sudo rm $bin_path/node $bin_path/npm $bin_path/npx
    anm_deactivate $version
    is_sudo rm -rf $install_path/versions/node/$version
  else
    echo "Node version: $version not installed"
    exit 1
  fi

  local current_installed=$(cat $install_path/installed)
  local final_list=""
  for installed in $current_installed; do
    if [[ $installed != $version ]]; then
      final_list="$final_list $installed"
    fi
  done
  echo $final_list | is_sudo tee $install_path/installed &> /dev/null

  # if [[ $current_active == $version ]]; then
  #   is_sudo tee "" $install_path/active &> /dev/null
  # fi

  echo "Uninstall complete. Please activate a different version of NodeJs if installed"
  echo "anm use <version number>    # v16.15.0, v12.22.12, etc"
}

print_help() {
  echo; echo "Another Node Manager ($ANM_VERSION)"
  echo "Usage: anm [command] [options...]"; echo
  echo "    anm ls                    # List locally installed NodeJs versions"; echo
  echo "    anm ls-remote             # List node versions available for install from www.nodejs.org"
  echo "        --lts                 # List LTS versions of node available for install"
  echo "        --lts <version>       # List latest LTS release for a version that is available for install"
  echo "                              # gallium, fermium, erbium, etc"
  echo "        --latest              # List latest release for all node versions available for install"; echo
  echo "    anm install               # Install latest release of NodeJs"
  echo "        <version number>      # Install a perticular version of NodeJs"
  echo "                              # v18.2.0, v17.9.0, v12.22.12, etc"
  echo "        --lts                 # Install latest LTS release of NodeJs"
  echo "        --lts <version>       # Install latest LTS release of a version of NodeJs"
  echo "                              # gallium, fermium, erbium, etc"; echo
  echo "    anm uninstall <version>   # Uninstall a specific version of NodeJs"
  echo "                              # v18.2.0, v17.9.0, v12.22.12, etc"; echo
  echo "    anm use <version>         # Activate or use a particular version of NodeJs"
  echo "                              # v18.2.0, v17.9.0, v12.22.12, etc"; echo
  echo "    anm --version             # Print version of ANM locally installed"
  echo "    anm --path                # Print ANM install path, NodeJs binaries stored here as well"
  echo "    anm --help                # Print this help message"
  echo
}

anm() {
  case $1 in
    "ls")
      anm_ls;;
    "ls-remote")
      shift
      anm_ls_remote $@;;
    "install")
      shift
      anm_install $@;;
    "uninstall")
      shift
      anm_uninstall $@;;
    "use")
      shift
      anm_activate $@;;
    "--version")
      echo $ANM_VERSION;;
    "--path")
      get_anm_install_location;;
    "--help")
      print_help;;
    *)
      echo "Unknown option"
      print_help
      exit 1;;
  esac
}
anm $@
