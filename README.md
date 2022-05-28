# Another Node Manager

![version](https://img.shields.io/github/v/tag/anujdatar/anm?label=version&sort=semver)

A simple and lightweight alternative to
[Node Version Manager](https://github.com/nvm-sh/nvm) (nvm). Also works for ARM
based systems, supported architectures armv6l, armv7l, arm64, amd64 (x86_64).

> Wanted something to setup my SBC server projects without the overhead of nvm-sh.

Should technically work on Debian, Fedora, and Arch based systems. Testing being
conducted on Ubuntu, Fedora, and Manjaro.
- Test Systems:
  - X86_64 PC: Ubuntu, Fedora and Manjaro
  - Raspberry PI 3B, 4B: Raspberry Pi OS, Ubuntu, Manjaro
  - Rock64, RockPro64: Armbian, Manjaro
  - Pinebook Pro: Manjaro

Only works for Node.js versions with specific distributions for Linux:
 - Node v0.8.6+ (x86, x86_64)
 - Node v4.0.0+ (armv6l, armv7l, arm64)

## Install
1. Install to default user-space. This should install to `/home/$USER/.anm`
  ```
  curl -o- https://raw.githubusercontent.com/anujdatar/anm/main/install.sh | bash
  ```
  ```
  wget -qO- https://raw.githubusercontent.com/anujdatar/anm/main/install.sh | bash
  ```

2. Install ANM system-wide, for all users. This should install to /opt/anm. Use the following:
  ```
  curl -o- https://raw.githubusercontent.com/anujdatar/anm/main/install.sh | bash -s system
  ```
  ```
  wget -qO- https://raw.githubusercontent.com/anujdatar/anm/main/install.sh | bash -s system
  ```
  > NOTE: most ANM actions, and node (npm install -g) will require `sudo` privileges.

3. Custom location:
    - Clone git repository
    - Make `install.sh` an executable. `chmod +x install.sh`
    - Run the install script. `./install.sh`

4. If you want to use the script without installing, just clone the repository,
install dependencies above, create files named `installed` and `active`. Make
`anm.sh` and executable file `chmod +x anm.sh`. You should now be able to run
ANM from the directory `./anm.sh ls-remote`, `./anm.sh install --lts`, etc.

The convenience script does the following in case you want to install manually.
  1. Update/upgrade system
  2. Install missing dependencies using your package manager (apt/dnf/pacman)
    - `curl`, `wget`, `git`, `jq`, `python3`, `python3-pip` (`python-pip` if using Arch). Ironically you need either `curl` or `wget` to get started. 😝
  3. Install `packaging` (a python package) using `pip`. `pip install packaging`
  4. Clones the [ANM git repo](https://github.com/anujdatar/anm) to `/home/$USER/.anm` or `/opt/anm`. This step is skipped if you are installing from the repo-clone.
  5. Makes `anm.sh` an executable (`chmod +x /<path>/anm.sh`). And creates a symlink in `/home/$USER/.local/bin` or `/opt/anm` depending on the install location (`ln -s /<path>/anm.sh /<bin_path>/anm`).
  6. Add `export $ANM_DIR=/<install_path>/` to your shell rc profile (`.bashrc`, `.zshrc`, `.profile`, `/etc/profile.d/anm_profile.sh`). This is required for anm detect install location and work correctly. Currently `bash` and `zsh` are supported. Other shell users should make sure `$HOME/.profile` and/or `/etc/profile` are loaded when shell is launched.

You might have to restart your system, or logout and log back in, or just close shell and reopen. Depends. You
should be able to use anm from command line after this.

> Note: If installing only to your userspace, step 5 also checks if `$HOME/.local/bin` is in path. If not, it adds that to your shell rc profile.

## Uninstall
Unfortunately this has to be manual for now
  1. Remove the installed directory
    ```
    rm -rf /home/$USER/.anm
    ```
  2. Remove symlink
    ```
    rm /home/$USER/.local/bin/anm
    ```

## Usage
1. List locally installed node versions / releases. Should tell you active version as well.
   ```
   anm ls
   ```
2. List node versions available for install from www.nodejs.org
     - List all available options
       ```
       anm ls-remote
       ```
     - List all LTS releases
       ```
       anm ls-remote --lts
       ```
     - List latest LTS release for a particular version
       ```
       anm ls-remote --lts <release name>  # gallium, fermium, argon, etc
       ```
     - List latest release of each version
       ```
       anm ls-remote --latest
       ```
3. Install a version of NodeJs
     - Install the latest available release
       ```
       anm install
       ```
     - Install the latest LTS version release
       ```
       anm install --lts
       ```
     - Install the latest release of a specific LTS version
       ```
       anm install --lts <release name>  # gallium, fermium, argon, etc
       ```
     - Install a specific release by version number
       ```
       anm install v16.15.0 # or 18.2.0, v-prefix not necessary
       ```
4. Uninstall an installed version of NodeJs
   ```
   anm uninstall <version number>  # v16.15.0 or 14.19.3, v-prefix not necessary
   ```
5. Use a particular version of NodeJs, if you already have a few installed
   ```
   anm use <version number>  # v16.15.0 or 18.2.0, v-prefix not necessary
   ```
6. Deactivate a currently installed version of NodeJs if managed by ANM
   ```
   anm deactivate <version number>  # v16.15.0 or 18.2.0, v-prefix not necessary
   ```
7. Other misc. commands
    ```
    anm --version    # print version of ANM that is installed
    ```
    ```
    anm --path       # print path where ANM is installed, NodeJs binaries in a subfolder here
    ```
    ```
    anm --help       # print help message
    ```

## TODO:
1. Look into aliasing installed node versions

## Thanks
Uses some ideas from [NVM](https://github.com/nvm-sh/nvm), but works differently.
Was initially inspired by their work. But when I started this project, I had
issues with NVM on some of my RockChip based SBCs. It works perfectly now, but I
had a few different ideas I wanted to try out for my local servers.

Unlike NVM, ANM does not load it's entire code to the shell profile every time
you launch terminal. But has very limited functionality compared to NVM.
Probably not the most elegant solution, but a learning process for me.
