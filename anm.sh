#!/bin/bash

ANM_VERSION="1.0.0"

node_dist_index="https://nodejs.org/dist/index.json"

####################  utility functions ######################
# OS detection functions
linux() { [[ "$OSTYPE" == "linux-gnu"* ]]; }
darwin() { [[ "$OSTYPE" == "darwin"* ]]; }
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

# set which python keyword to use
if windows; then
  PYTHON="python"
else
  PYTHON="python3"
fi

get_sys_node_arch() {
  ### get system arch, return strings that nodejs website uses ###
  # TODO: add Darwin detection
  if windows; then
    node_arch="win-x64-zip"
  elif linux; then
    case "$(uname -m)" in
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
  elif darwin; then
    echo "macOS not supported yet. Coming soon though"
    exit 1
  fi
}

parse_version() {
  local version_1=$1

  if [[ $version_1 == v* ]]; then
    echo "$version_1"
  else
    echo "v$version_1"
  fi
}

get_sys_node_arch
if [ "$?" = 1 ]; then
  format_red "System OS and architecture not supported by ANM\n"
  format_red "Please check compatibility or contact developer\n"
  exit 1
fi

get_download_link() {
  ### construct the download link string
  if [ "$1" = "" ]; then
    format_red "No node version provided for download\n"
    exit 1
  fi
  local version="$(parse_version $1)"

  local download_filename=""
  if windows; then
    download_filename="node-$version-win-x64.zip"
  elif linux; then
    download_filename="node-$version-$node_arch.tar.xz"
  fi

  local base_link="https://nodejs.org/dist"
  local version_page="$base_link/$version"
  local download_link="$version_page/$download_filename"
  echo "$download_link"
}

get_anm_install_location() {
  ### get ANM install location (folder)
  if [ -d "$ANM_DIR" ]; then
    echo "$ANM_DIR"
  else
    echo "$(pwd)"
    touch "$(pwd)/active"
    touch "$(pwd)/installed"
    mkdir -p "$(pwd)/versions/node"
  fi
}

get_bin_path() {
  ### get path of the anm bin folder
  local install_path="$(get_anm_install_location)"

  echo "$install_path/bin"
}

python_script_path="$(get_anm_install_location)/web_json_parse.py"

ls_all() {
  $PYTHON $python_script_path $node_dist_index $node_arch "ls_all"
}
ls_lts() {
  $PYTHON $python_script_path $node_dist_index $node_arch "ls_lts"
}
ls_latest() {
  $PYTHON $python_script_path $node_dist_index $node_arch "ls_latest"
}
ls_latest_lts_version_data_by_name() {
  $PYTHON $python_script_path $node_dist_index $node_arch "lts_latest_data" $1
}
latest_lts_version_number() {
  $PYTHON $python_script_path $node_dist_index $node_arch "latest_version_number" $1
}

anm_ls_remote() {
  case "$1" in
    "--lts")
      if [ "$2" ]; then
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
  local install_path="$(get_anm_install_location)"
  local current_installed="$(cat $install_path/installed | sort -V -r)"

  if [ "$current_installed" = "" ]; then
    format_red "No versions of NodeJs installed using ANM\n"
    exit 0
  fi

  local current_active="$(cat $install_path/active)"

  for installed in $current_installed; do
    if [ "$installed" = "$current_active" ]; then
      format_green "$installed"; echo " (active)"
    else
      echo "$installed"
    fi
  done
}

is_sudo() {
  local install_path="$(get_anm_install_location)"
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

anm_deactivate() {
  local version="$(parse_version $1)"

  if [ "$version" = "" ]; then
    echo "No version passed to deactivate"
    return 0
  fi

  local install_path="$(get_anm_install_location)"
  local current_active="$(cat $install_path/active)"
  local bin_path="$(get_bin_path)"

  if [ "$current_active" = "$version" ]; then
    echo "Deactivating current version of NodeJs: $version"
    echo "" | is_sudo tee "" $install_path/active &> /dev/null

    if [ -d "$install_path/versions/current" ]; then
      is_sudo rm ${install_path}/versions/current
    fi
  fi
}

anm_activate() {
  local version="$(parse_version $1)"

  local install_path="$(get_anm_install_location)"
  local bin_path="$(get_bin_path)"

  local current_active="$(cat $install_path/active)"

  local binary_folder=""
  if windows; then
    local binary_folder="$install_path/versions/node/$version"
  else
    local binary_folder="$install_path/versions/node/$version/bin"
  fi

  if ! [ -d "$install_path/versions/node/$version" ]; then
    format_red "Version $version not installed"
    exit 1
  fi

  anm_deactivate $current_active

  echo "Activating NodeJs version: $version"

  if [ -d "$binary_folder" ]; then
    is_sudo symlink "$binary_folder" "$install_path/versions/current"
  fi

  if [ "$?" != 1 ]; then
    echo $version | is_sudo tee $install_path/active &> /dev/null
  else
    format_red "Error while activating node version $version\n"
    exit 1
  fi
}

anm_install() {
  local version=""
  case "$1" in
    "")
      version="$($PYTHON $python_script_path $node_dist_index $node_arch "latest_version_number" "")";;
    "--lts")
      if [ "$2" ]; then
        lts_name="$(echo "$2" | tr '[:upper:]' '[:lower:]')"
        version="$($PYTHON $python_script_path $node_dist_index $node_arch "latest_version_number" $lts_name)"
      else
        version="$($PYTHON $python_script_path $node_dist_index $node_arch "latest_version_number" "latest_lts")"
      fi;;
    *)
      version="$(parse_version $1)"
  esac

  if [ "$?" = 1 ]; then
    format_red "Unable to find version: $2\n"
    exit 1
  fi

  anm_dir="$(get_anm_install_location)"
  node_install_dir="$anm_dir/versions/node/$version"

  if [ -d "$node_install_dir" ]; then
    format_yellow "NodeJs release: $version is already installed"
    exit 1
  fi

  is_sudo mkdir -p "$node_install_dir"

  if windows; then
    download_filename="node-$version-win-x64"
    extension="zip"
  elif linux; then
    download_filename="node-$version-$node_arch"
    extension="tar.xz"
  elif darwin; then
    download_filename="node-$version-darwin-(arm64 or x64)"
    extension="tar.xz"
    format_red "macOS not supported as yet."
    exit 1
  fi
  download_link="$(get_download_link $version)"

  # if ! wget -q --method=HEAD $download_link; then
  if ! curl --output /dev/null --silent --head --fail "$download_link"; then
    format_red "Incorrect download link for node.js version\n"
    format_yellow "If you think this is an error, please contact dev on GitHub\n"
    echo "$download_link"
    exit 1
  fi

  echo
  echo "Downloading nodejs version: $version from"
  echo "$download_link"; echo
  # wget -O "/tmp/$download_filename" $download_link
  curl $download_link --output "$anm_dir/versions/node/$download_filename.$extension"

  echo "Extracting nodejs to $node_install_dir"
  if windows; then
    unzip -q "$anm_dir/versions/node/$download_filename.$extension" -d "$anm_dir/versions/node"
    rm -rf "$node_install_dir"
    mv "$anm_dir/versions/node/$download_filename" "$node_install_dir"
    rm "$anm_dir/versions/node/$download_filename.$extension"
  else
    # is_sudo tar -xf "/tmp/$download_filename" -C $node_install_dir --strip-components=1
    is_sudo tar -xf "$anm_dir/versions/node/$download_filename.$extension" \
      -C $node_install_dir \
      --strip-components=1
    rm $anm_dir/versions/node/$download_filename.$extension
  fi

  echo "$version" | is_sudo tee -a $anm_dir/installed &> /dev/null

  anm_activate $version
}

anm_uninstall() {
  local version="$(parse_version $1)"

  local install_path="$(get_anm_install_location)"
  local bin_path="$(get_bin_path)"

  if [ -d "$install_path/versions/node/$version" ]; then
    echo "Uninstalling node version: $version"
    anm_deactivate $version
    is_sudo rm -rf $install_path/versions/node/$version
  else
    format_red "Node version: $version not installed\n"
    exit 1
  fi

  local current_installed="$(cat $install_path/installed)"
  local final_list=""
  for installed in $current_installed; do
    if [ "$installed" != "$version" ]; then
      final_list="$final_list $installed"
    fi
  done
  echo "$final_list" | is_sudo tee $install_path/installed &> /dev/null

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
  echo "                              # v18.2.0, v17.9.0, 12.22.12, etc. v-prefix not necessary"
  echo "        --lts                 # Install latest LTS release of NodeJs"
  echo "        --lts <version>       # Install latest LTS release of a version of NodeJs"
  echo "                              # gallium, fermium, erbium, etc"; echo
  echo "    anm uninstall <version>   # Uninstall a specific version of NodeJs"
  echo "                              # v18.2.0, v17.9.0, 12.22.12, etc. v-prefix not necessary"; echo
  echo "    anm use <version>         # Activate or use a particular version of NodeJs"
  echo "                              # v18.2.0, v17.9.0, v12.22.12, etc. v-prefix not necessary"; echo
  echo "    anm deactivate <version>  # Deactivate an active version of NodeJs if installed with ANM"
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
    "deactivate")
      shift
      anm_deactivate $@;;
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
