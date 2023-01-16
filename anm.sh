#!/bin/bash

ANM_VERSION="3.1.2"

node_dist_index="https://nodejs.org/dist/index.json"

####################  utility functions ######################
# OS detection functions
linux() { [[ "$OSTYPE" == "linux-gnu"* ]]; }
darwin() { [[ "$OSTYPE" == "darwin"* ]]; }
windows() { [ -n "$WINDIR" ]; }

# some text color formatting functions
format_red() {
  ### Usage: format_dist "string", use \n at the end for linebreak ###
  printf "\e[31m$1\e[0m"
}
format_green() {
  printf "\e[32m$1\e[0m"
}
format_yellow() {
  printf "\e[33m$1\e[0m"
}

parse_version() {
  local version_1=$1

  if [[ $version_1 == v* ]]; then
    echo "$version_1"
  else
    echo "v$version_1"
  fi
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

# set which python keyword to use
if windows; then
  PYTHON="python"
else
  PYTHON="python3"
fi

### get system arch, return strings that nodejs website uses ###
if windows; then
  EXT="zip"
  node_arch="win-x64-zip"
  filename_suffix="win-x64"
elif linux; then
  EXT="tar.xz"
  case "$(uname -m)" in
    x86_64)
      node_arch="linux-x64"
      filename_suffix="linux-x64";;
    aarch64|arm64)
      node_arch="linux-arm64"
      filename_suffix="linux-arm64";;
    armhf)
      node_arch="linux-armv7l"
      filename_suffix="linux-armv7l";;
    *)
      format_red "System OS and architecture not supported by ANM\n"
      format_red "Please contact developer on GitHub for solution\n"
      exit 1;;
  esac
elif darwin; then
  EXT="tar.xz"
  case "$(uname -m)" in
    x86_64)
      node_arch="osx-x64-tar"
      filename_suffix="darwin-x64";;
    arm64)
      node_arch="osx-arm64-tar"
      filename_suffix="darwin-arm64";;
    *)
      format_red "System OS and architecture not supported by ANM\n"
      format_red "Please contact developer on GitHub for solution\n"
      exit 1;;
  esac
fi

get_download_filename() {
  ### construct download filename string
  if [ "$1" = "" ]; then
    format_red "No node version provided for download\n"
    exit 1
  fi
  local version="$(parse_version $1)"

  echo "node-$version-$filename_suffix"
}

get_download_link() {
  ### construct the download link string
  if [ "$1" = "" ]; then
    format_red "No node version provided for download\n"
    exit 1
  fi
  local version="$(parse_version $1)"

  if [ "$2" = "" ]; then
    format_red "No filename provided for download\n"
    exit 1
  fi
  local download_filename="$2"

  echo "https://nodejs.org/dist/$version/$download_filename.$EXT"
}

python_script_path="$(get_anm_install_location)/web_json_parse.py"

list_compat_node_versions() {
  ### List compatible versions of node for your system
  ### Usage: list_compat_node_version [...options]
  ###         ls_all: list all compatible versions
  ###         ls_latest: list latest release of each version
  ###         ls_lts: list all compatible LTS versions
  ###         lts_latest_data <lts_name>: latest release details of given LTS name
  ### .       latest_version_number [latest/lts_name]: latest release or LTS version number
  $PYTHON $python_script_path $node_dist_index $node_arch $@
}

anm_ls_remote() {
  case "$1" in
    "--lts")
      if [ "$2" ]; then
        # latest release of LTS for given codename
        list_compat_node_versions "lts_latest_data" $2
      else
        # latest release for all LTS versions
        list_compat_node_versions "ls_lts"
      fi;;
    "--latest")
      # latest release for all node versions
      list_compat_node_versions "ls_latest";;
    "")
      # all compatible node versions
      list_compat_node_versions "ls_all";;
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
      get_version="latest";;
    "--lts")
      if [ "$2" ]; then
        get_version="$(echo "$2" | tr '[:upper:]' '[:lower:]')"
      else
        get_version="latest_lts"
      fi;;
    *)
      version="$(parse_version $1)";;
  esac

  if [ "$get_version" ]; then
    version="$(list_compat_node_versions "latest_version_number" $get_version)"
  fi

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

  local download_filename="$(get_download_filename $version)"
  local download_link="$(get_download_link $version $download_filename)"

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
  curl $download_link --output "$anm_dir/versions/node/$download_filename.$EXT"

  echo "Extracting nodejs to $node_install_dir"
  if windows; then
    unzip -q "$anm_dir/versions/node/$download_filename.$EXT" -d "$anm_dir/versions/node"
    rm -rf "$node_install_dir"
    mv "$anm_dir/versions/node/$download_filename" "$node_install_dir"
    rm "$anm_dir/versions/node/$download_filename.$EXT"

    # making all nodejs binaries executable for Cygwin compatibility
    chmod +x "$node_install_dir/node.exe"
    chmod +x "$node_install_dir/npm"
    chmod +x "$node_install_dir/npx"
    chmod +x "$node_install_dir/corepack"
  else
    # is_sudo tar -xf "/tmp/$download_filename" -C $node_install_dir --strip-components=1
    is_sudo tar -xf "$anm_dir/versions/node/$download_filename.$EXT" \
      -C $node_install_dir \
      --strip-components=1
    rm $anm_dir/versions/node/$download_filename.$EXT
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

anm_upgrade() {
  local CURRENT_DIR="$(pwd)"
  local install_path="$(get_anm_install_location)"
  cd $install_path
  git pull
  cd $CURRENT_DIR
}

print_help() {
  echo; echo "Another Node Manager ($ANM_VERSION)"
  echo "Usage: anm [command] [options...]"; echo
  echo "    anm upgrade               # upgrade ANM to latest version"; echo
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
    "upgrade")
      anm_upgrade;;
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
