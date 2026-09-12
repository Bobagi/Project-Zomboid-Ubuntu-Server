# Project Zomboid Dedicated Server on Ubuntu · Complete Setup Guide

> **Step-by-step guide to install, configure, and run a Project Zomboid dedicated server on Ubuntu 22.04 / 24.04 LTS using SteamCMD.** Covers firewall setup, RAM configuration, mod installation, server recovery, and common troubleshooting. Works on any VPS provider (Hostinger, DigitalOcean, Hetzner, Vultr, AWS, Linode, etc.).

[![Stars](https://img.shields.io/github/stars/Bobagi/Project-Zomboid-Ubuntu-Server?style=for-the-badge)](https://github.com/Bobagi/Project-Zomboid-Ubuntu-Server/stargazers)
[![Forks](https://img.shields.io/github/forks/Bobagi/Project-Zomboid-Ubuntu-Server?style=for-the-badge)](https://github.com/Bobagi/Project-Zomboid-Ubuntu-Server/network/members)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)
![Steam](https://img.shields.io/badge/steam-%23000000.svg?style=for-the-badge&logo=steam&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)

---

**[🇧🇷 Versão em Português](README.pt-BR.md)**

---

## Table of Contents
1. [Why this guide?](#why-this-guide)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [Configuration](#configuration)
5. [Running the Server](#running-the-server)
6. [Auto-start on Boot (systemd)](#auto-start-on-boot-systemd)
7. [Installing Mods](#installing-mods)
8. [Server Management](#server-management)
9. [Troubleshooting](#troubleshooting)
10. [FAQ](#faq)
11. [Acknowledgements](#acknowledgements)
12. [License](#license)

---

## Why this guide?

Most tutorials for hosting a Project Zomboid server on Linux skip important details like RAM allocation, firewall rules, or mod management. This guide was built from real experience hosting private servers and covers:

- ✅ Full installation from scratch on a fresh Ubuntu VPS
- ✅ Firewall (UFW) configuration to avoid connection issues
- ✅ SteamCMD setup and anonymous login
- ✅ RAM tuning via `ProjectZomboid64.json`
- ✅ Importing server settings from a local Windows machine
- ✅ Running the server in the background with `screen`
- ✅ Starting the server automatically on boot with a tested `systemd` service
- ✅ Installing workshop mods via SCP or SFTP (FileZilla)
- ✅ Common errors and how to fix them

---

## Prerequisites

Before you begin, make sure you have:

- A VPS or dedicated machine running **Ubuntu 22.04 or 24.04 LTS (64-bit)**. Other Debian-based distros likely work too
- At least **4 GB RAM** (8 GB recommended for a stable experience with mods)
- `sudo` privileges on the server
- Basic knowledge of terminal / Linux commands
- **Project Zomboid** purchased on Steam (required for mod access; the server itself is free)
- An SSH client (e.g., PuTTY on Windows, built-in terminal on macOS/Linux)

---

## Installation

### 1. Update the system and configure the firewall

```bash
sudo apt-get update && sudo apt-get upgrade -y
```

Enable UFW (firewall):
```bash
sudo ufw enable
```

> ⚠️ **Important:** If you are connected via SSH, allow your SSH port **before** enabling the firewall, otherwise you will lose access:

```bash
sudo ufw allow 22        # SSH (default port, change if you use a custom port)
```

Allow the Project Zomboid server ports:
```bash
sudo ufw allow 16261/udp  # Main game port (UDP)
sudo ufw allow 16262/udp  # Direct connection port (UDP)
sudo ufw reload
```

Verify the rules are active:
```bash
sudo ufw status
```

You should see `16261` and `16262` listed as `ALLOW`.

---

### 2. Create a dedicated user for Steam

It is best practice to run game servers under a separate non-root user:

```bash
sudo adduser steam
sudo usermod -aG sudo steam
sudo chown steam:steam /home/steam/ -R
sudo chmod -R 755 /home/steam/
```

---

### 3. Enable 32-bit architecture support and install SteamCMD

Switch to the steam user's directory:
```bash
cd /home/steam
```

Enable the multiverse repository and 32-bit support (required by SteamCMD):
```bash
sudo add-apt-repository multiverse
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install steamcmd -y
```

---

### 4. Download the Project Zomboid Dedicated Server

Switch to the steam user:
```bash
su - steam
cd ~
steamcmd
```

Inside SteamCMD, run these commands:
```
force_install_dir /home/steam/pzsteam
login anonymous
app_update 380870 validate
exit
```

> `380870` is the Steam App ID for the **Project Zomboid Dedicated Server**. It is free and can be downloaded without owning the game.

---

## Configuration

### 1. Set the RAM allocation

Navigate to the server directory:
```bash
cd /home/steam/pzsteam
```

Edit the JVM configuration file:
```bash
nano ProjectZomboid64.json
```

Find the `-Xmx` parameter and set it to the amount of RAM you want to dedicate:
- `-Xmx4g` → 4 GB RAM
- `-Xmx8g` → 8 GB RAM (recommended for most servers)
- `-Xmx16g` → 16 GB RAM (for large modpacks or many players)

![RAM configuration example](https://github.com/Bobagi/Zomboid-Ubuntu-Server/assets/45888141/e945f3f0-156c-448f-b62f-6e0332ba98f2)

---

### 2. Import server settings from your local machine (optional but recommended)

The easiest way to configure game settings (map, loot, difficulty, sandbox) is to:

1. Open Project Zomboid on your **local Windows PC**
2. Create and configure a server through the in-game **"Host"** menu
3. Navigate to the settings folder on Windows:
   ```
   C:\Users\<YourUsername>\Zomboid\Server\
   ```
4. Copy these three files:
   - `<servername>.ini`
   - `<servername>_SandboxVars.lua`
   - `<servername>_spawnregions.lua`

5. Upload them to your Linux server at:
   ```
   /home/steam/Zomboid/Server/
   ```

   Using SCP:
   ```bash
   scp C:\Users\<YourUsername>\Zomboid\Server\<servername>* steam@<your-vps-ip>:/home/steam/Zomboid/Server/
   ```

   Or use a GUI tool like [FileZilla](https://filezilla-project.org/) (connect via SFTP on port 22).

---

## Running the Server

### 1. Start a persistent screen session

`screen` keeps the server running after you disconnect from SSH:

```bash
screen -S zomboid
```

### 2. Start the server

```bash
cd /home/steam/pzsteam
./start-server.sh -servername <yourservername>
```

Replace `<yourservername>` with the name of your `.ini` config file (without the `.ini` extension).

### 3. Detach from screen (keep server running in background)

Press `Ctrl + A`, then `D`.

### 4. Re-attach to check the server console

```bash
screen -r zomboid
```

### 5. Stop the server gracefully

Re-attach with `screen -r zomboid`, then type:
```
quit
```

Wait for the world save to complete before closing the session.

---

## Auto-start on Boot (systemd)

The `screen` method above requires you to log in over SSH and start the server by hand.
If the machine reboots (power loss, kernel update, `sudo reboot`), the server stays down
until someone starts it again.

A `systemd` service fixes that: the server starts at boot, restarts if it crashes, and
`systemctl stop` shuts it down **using the same `quit` command** documented above, so the
world is always saved. The interactive console keeps working exactly as before with
`screen -r zomboid`.

### 1. Create the service file

```bash
sudo nano /etc/systemd/system/zomboid.service
```

Paste the following, replacing `<yourservername>` with the name of your `.ini` file
(without the extension):

```ini
[Unit]
Description=Project Zomboid Dedicated Server
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=steam
Group=steam
WorkingDirectory=/home/steam/pzsteam
Environment=HOME=/home/steam

ExecStart=/usr/bin/screen -DmS zomboid /home/steam/pzsteam/start-server.sh -servername <yourservername>
ExecStop=/bin/bash -c 'screen -S zomboid -p 0 -X stuff "quit\n" || exit 0; while kill -0 $MAINPID 2>/dev/null; do sleep 2; done'

Restart=always
RestartSec=15
TimeoutStopSec=300

[Install]
WantedBy=multi-user.target
```

A copy of this file is in [`misc/zomboid.service`](misc/zomboid.service).

Why it is written this way (each line below was verified on a real server, not assumed):

- **`screen -DmS`** starts the session *without forking*, so systemd tracks the real
  process. Plain `screen -dmS` forks away and systemd loses track of it.
- **`ExecStop` types `quit` into the console**, which is exactly what the guide tells you
  to do by hand. Without it, systemd would signal the JVM directly.
- **`ExecStop` then waits for the server to exit.** This half matters just as much. A
  one-line `ExecStop` that only injects `quit` returns instantly, systemd concludes the
  stop is finished and signals the server *in the middle of the save*.
- **`Restart=always`, not `on-failure`.** `start-server.sh` ends with `exit 0` even when
  the game is killed, so systemd always sees a successful exit and `on-failure` would
  never fire. A manual `systemctl stop` is not treated as a failure, so it does not
  restart the server.
- **`TimeoutStopSec=300`** bounds the whole stop, including the save. An empty world saves
  in about 10 seconds; a large one with players takes longer.

### 2. Make sure nothing is already running

Do not run a `screen` copy and a systemd copy against the same world. If you started the
server manually, re-attach and type `quit` first:

```bash
screen -r zomboid
```

### 3. Enable and start it

```bash
sudo systemctl daemon-reload
sudo systemctl enable zomboid
sudo systemctl start zomboid
```

### 4. Check that it worked

```bash
sudo systemctl status zomboid          # should say "active (running)"
sudo -u steam screen -r zomboid        # the console, same as before
```

The server takes a minute or two to load before players can join. Watch for
`*** SERVER STARTED ***` in the console.

### Day-to-day commands

| Task | Command |
|---|---|
| Start | `sudo systemctl start zomboid` |
| Stop (saves the world) | `sudo systemctl stop zomboid` |
| Restart | `sudo systemctl restart zomboid` |
| Status | `sudo systemctl status zomboid` |
| Open the console | `sudo -u steam screen -r zomboid` |
| Leave the console running | `Ctrl + A`, then `D` |
| Disable auto-start | `sudo systemctl disable zomboid` |

> ⚠️ **Stop the server with `systemctl stop`, not by typing `quit` in the console.**
> With `Restart=always`, systemd sees a manual `quit` as an unexpected exit and starts the
> server again 15 seconds later.

> **Stopping with players online is safe.** The shutdown runs `Saving players` before anyone
> is disconnected, so connected characters are written to `players.db` first and the players
> are dropped afterwards. Still, warn them: from their side the server simply goes away.

> **Where are the logs?** `journalctl -u zomboid` only shows systemd's own messages,
> because the game console lives inside `screen`. The real server output is in
> `/home/steam/Zomboid/server-console.txt` and `/home/steam/Zomboid/Logs/`.

### Verifying it yourself

The repository ships an automated test that starts the service, checks the ports, stops it,
confirms the world was saved with no forced kill, restarts it, confirms the save was
reloaded, and kills the process to check crash recovery:

```bash
sudo ./misc/test-zomboid-service.sh
```

Run it with **no players connected** - it stops and starts the server several times.

---

## Installing Mods

### Method 1: Upload mod files via SCP / SFTP

1. Download mods from the [Steam Workshop](https://steamcommunity.com/app/108600/workshop/) on your local PC
2. Locate the downloaded mod folder on Windows:
   ```
   C:\Users\<YourUsername>\Zomboid\mods\
   ```
3. Upload the mod folder to your VPS:
   ```bash
   scp -r "C:\Users\<YourUsername>\Zomboid\mods\<ModName>" steam@<your-vps-ip>:/home/steam/Zomboid/mods/
   ```
   Or use [FileZilla](https://filezilla-project.org/) via SFTP.

4. Add the mod IDs to your server `.ini` file:
   ```ini
   Mods=<ModID>;<AnotherModID>
   WorkshopItems=<WorkshopID>;<AnotherWorkshopID>
   ```

> Mod IDs and Workshop IDs are found on the mod's Steam Workshop page URL and inside the mod's `mod.info` file.

### Method 2: Download Workshop mods via SteamCMD

Inside SteamCMD (logged in as anonymous):
```
workshop_download_item 108600 <WorkshopID>
```

Mods download to `/home/steam/.steam/steamapps/workshop/content/108600/<WorkshopID>/`.  
Copy or symlink them to `/home/steam/Zomboid/mods/`.

---

## Server Management

### Check if the server is running

```bash
screen -ls
```

### Update the server to the latest version

```bash
steamcmd
login anonymous
app_update 380870 validate
exit
```

Then restart the server.

### View server logs

```bash
ls -lt /home/steam/Zomboid/Logs/     # find the latest log file
cat /home/steam/Zomboid/Logs/<latest>.txt | tail -100
```

### Backup your server world

```bash
cp -r /home/steam/Zomboid/Saves/ /home/steam/Zomboid/Saves_backup_$(date +%Y%m%d)/
```

---

## Troubleshooting

### ❌ "Connection failed" / Cannot connect to the server

- Check ports are open: `sudo ufw status`, look for `16261` and `16262`
- Confirm the server is running: `screen -ls`
- Check your **VPS provider's cloud firewall / security group**: many providers have a separate firewall that also needs UDP 16261 a 16262 opened
- Verify your server IP: `curl ifconfig.me`

### ❌ Server crashes on startup

- Check available RAM: `free -h`, reduce `-Xmx` in `ProjectZomboid64.json` if needed
- Read the latest log: `ls -lt /home/steam/Zomboid/Logs/` then `cat` the most recent file
- Validate server files: re-run `app_update 380870 validate` in SteamCMD

### ❌ "Failed to set thread priority" warning

This is a harmless warning on most Linux VPS environments. The server runs normally.

### ❌ Mods not loading

- Confirm both `Mods=` and `WorkshopItems=` are set correctly in the `.ini` file
- Verify the mod folder exists at `/home/steam/Zomboid/mods/<ModID>/`
- Restart the server after any mod changes

### ❌ SteamCMD error: `0x202` or `0x212`

Steam network timeout. Wait a few minutes and retry. If persistent:
```bash
rm -rf /home/steam/.steam/steamcmd/appcache
steamcmd +login anonymous +app_update 380870 +quit
```

### ❌ `su - steam` asks for a password you don't know

Reset it:
```bash
sudo passwd steam
```

### ❌ Port 16261 is open in UFW but players still can't connect

Your VPS provider likely has a separate cloud-level firewall (Hostinger hPanel, DigitalOcean Firewall, AWS Security Groups). Log into your provider dashboard and add UDP rules for ports 16261 and 16262 there too.

---

## FAQ

**Q: Does running the server require owning Project Zomboid on Steam?**  
A: No. The dedicated server (App ID 380870) is free and downloads anonymously via SteamCMD. Only the players connecting need to own the game.

**Q: How many players can the server support?**  
A: Officially up to 32 players. With 8 GB RAM and a modern CPU, 8 a 16 simultaneous players is very comfortable.

**Q: Which Ubuntu version should I use?**  
A: **Ubuntu 22.04 LTS** or **24.04 LTS**. Avoid non-LTS releases for production servers.

**Q: Can I run this on a Raspberry Pi or ARM machine?**  
A: No. The Project Zomboid dedicated server is x86-64 only, ARM is not supported.

**Q: My server IP keeps changing. How do I get a static IP?**  
A: All major VPS providers give you a static public IP by default. If hosting at home, use a DDNS (Dynamic DNS) service.

**Q: How do I set a server admin password?**  
A: The server prompts you on first startup. To reset it later, edit `<servername>.ini` and update the `AdminPassword=` field.

**Q: Can I run the server without `screen`, using systemd instead?**  
A: Yes. See [Auto-start on Boot (systemd)](#auto-start-on-boot-systemd) for a ready-made service file. It runs the server *inside* `screen`, so the console stays available and `systemctl stop` still saves the world with the documented `quit` command.

**Q: What VPS provider is recommended?**  
A: **Hetzner** (Europe/US) and **Vultr** offer great price/performance. **Hostinger** is budget-friendly. **DigitalOcean** has excellent documentation. Choose the datacenter closest to your players for lowest ping.

**Q: The server starts but nobody can join, what should I check first?**  
A: In order: (1) Cloud firewall in your VPS provider dashboard, (2) UFW rules with `sudo ufw status`, (3) correct IP address, (4) server console for errors via `screen -r zomboid`.

---

## Acknowledgements

- [Project Zomboid Wiki · Dedicated Server](https://pzwiki.net/wiki/Dedicated_Server) · official documentation
- [Valve SteamCMD Documentation](https://developer.valvesoftware.com/wiki/SteamCMD) · SteamCMD reference
- [r/projectzomboid](https://www.reddit.com/r/projectzomboid/) · community tips and feedback
- Everyone who opened issues and contributed improvements to this repository ❤️

---

## 💖 Support this project

If this guide saved you time, consider giving the repo a ⭐, it helps others find it!

[![PayPal](https://img.shields.io/badge/PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://www.paypal.com/donate?hosted_button_id=23PAVC8AMJGYW)
[![Donate with PayPal](https://www.paypalobjects.com/en_US/i/btn/btn_donate_LG.gif)](https://www.paypal.com/donate?hosted_button_id=23PAVC8AMJGYW)

---

## Contact & Contributing

Found a bug in the guide or have a tip to add?  
👉 **[Open an issue](https://github.com/Bobagi/Project-Zomboid-Ubuntu-Server/issues/new)**, all feedback is welcome.

Pull requests are also welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## License

This project is open-source under the [MIT License](LICENSE).
