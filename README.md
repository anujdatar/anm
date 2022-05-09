# Another Node Manager

**DISCLAIMER**: Still pre-alpha, I am still tweaking and updating scripts. Please *DO NOT USE* just yet. I will update once basic functionality is tested and is error free.

A simple and lightweight alternative to [Node Version Manager](https://github.com/nvm-sh/nvm) (nvm). Also works for ARM based systems, supported architectures armv6l, armv7l, arm64, amd64 (x86_64).

> Wanted something to setup my SBC server projects. Did not want the overhead of nvm-sh.

Should technically work on Debian, Fedora, and Arch based systems. Testing being conducted on Ubuntu, Fedora, and Manjaro.
- Test Systems:
  - X86_64 PC: Ubuntu, Fedora and Manjaro
  - Raspberry PI 3B, 4B: Raspberry Pi OS, Ubuntu, Manjaro
  - Rock64, RockPro64: Armbian, Manjaro
  - Pinebook Pro: Manjaro

Only works for Node.js versions with specific distributions for Linux:
 - Node v0.8.6+ (x86, x86_64)
 - Node v4.0.0+ (armv6l, armv7l, arm64)

## Thanks
Uses some ideas from [NVM](https://github.com/nvm-sh/nvm), but works differently. Was initially inspired by their work. But when I started this project, I had issues with NVM on some of my RockChip based SBCs. It works perfectly now, but I had a few different ideas I wanted to try out for my local servers.

Unlike NVM, ANM does not load it's entire code to the shell profile every time you launch terminal. But has very limited functionality compared to NVM. Probably not the most elegant solution, but a learning process for me.
