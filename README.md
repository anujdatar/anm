# Another Node Manager

**DISCLAIMER**: Still pre-alpha, I am still tweaking and updating scripts. Please *DO NOT USE* just yet. I will update once basic functionality is tested and is error free.

A simple and lightweight alternative to [Node Version Manager](https://github.com/nvm-sh/nvm) (nvm). Also works for ARM based systems, supported architectures armv6l, armv7l, arm64, amd64 (x86_64).

> Wanted something to setup my SBC server projects without the overhead of nvm-sh.

Should technically work on Debian, Fedora, and Arch based systems. Testing being conducted on Ubuntu, Fedora, and Manjaro.
- Test Systems:
  - X86_64 PC: Ubuntu, Fedora and Manjaro
  - Raspberry PI 3B, 4B: Raspberry Pi OS, Ubuntu, Manjaro
  - Rock64, RockPro64: Armbian, Manjaro
  - Pinebook Pro: Manjaro

Only works for Node.js versions with specific distributions for Linux:
 - Node v0.8.6+ (x86, x86_64)
 - Node v4.0.0+ (armv6l, armv7l, arm64)

## Install
```
curl -o- https://raw.githubusercontent.com/anujdatar/anm/main/install.sh | bash
```
```
wget -qO- https://raw.githubusercontent.com/anujdatar/anm/main/install.sh | bash
```
This should install to `/home/$USER/.anm`. It does the following things
  1. Update/upgrade system
  2. Install missing dependencies using your package manager (apt/dnf/pacman)
    - `curl`, `wget`, `git`, `jq`, `python3`, `python3-pip`. Ironically you need either `curl` or `wget to get started. 😝
  3. Install `packaging` (a python package) using `pip`
  4. Clones the [ANM git repo](https://github.com/anujdatar/anm) to `/home/$USER/.anm`
  5. Makes `anm.sh` an executable and creates a symlink in `/home/$USER/.local/bin`

You might have to restart your system, or logout and log back in. Depends. You should be able to use anm from command line after this.

## Thanks
Uses some ideas from [NVM](https://github.com/nvm-sh/nvm), but works differently. Was initially inspired by their work. But when I started this project, I had issues with NVM on some of my RockChip based SBCs. It works perfectly now, but I had a few different ideas I wanted to try out for my local servers.

Unlike NVM, ANM does not load it's entire code to the shell profile every time you launch terminal. But has very limited functionality compared to NVM. Probably not the most elegant solution, but a learning process for me.
