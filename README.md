# :zombie: Project Zomboid Server on Ubuntu 22.04 and 23.04

This repository contains scripts, configuration files, and documentation to help you set up a Project Zomboid server on an Ubuntu 23.04 64-bit VPS hosted with Hostinger and on a server on an Ubuntu 22.04 64-bit VPS hosted with Hostzone. This is a personal project designed to create a private server for playing with friends.

The Hostzone VPS was essentially double the price, but the ping was much better.

Any suggestion on how to check other host services pings

![Steam](https://img.shields.io/badge/steam-%23000000.svg?style=for-the-badge&logo=steam&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)

## :bookmark_tabs: Table of Contents
1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Running the Server](#running-the-server)
5. [Installing Mods](#installing-mods)
6. [License](#license)
7. [Acknowledgements](#acknowledgements)

## :desktop_computer: Prerequisites

Before you begin, ensure you have met the following requirements:

- A VPS running Ubuntu (tested in 22.04 and 23.04 64-bit)
- sudo privileges on the VPS
- Basic knowledge of terminal and Linux commands
- Project Zomboid game purchased on a platform like Steam


## :cd: Installation

1. Update and upgrade your system:

    ```
    sudo apt-get update && sudo apt-get upgrade -y
    ```
    ```
    sudo ufw enable
    ```

    IMPORTANT:
    If you're connecting via SSH, you need to allow the port you are using; otherwise, you won't be able to connect via SSH as you are currently doing:

    ```
    sudo ufw allow 22
    ```

    In my case, my port to SSH is 22

    Then allow the ports used by the game Server:
    ```
    sudo ufw allow 16261
    ```
    ```
    sudo ufw allow 16262
    ```
    ```
    sudo ufw reload
    ```

    Then i recommend to check if the ports are really open:

    ```
    sudo ufw status
    ```

    Look if all the ports you have opened are listed.

2. Add a new user named "steam" (or whatever name you want):

    ```
    sudo adduser steam
    ```
    ```
    usermod -aG sudo steam
    ```
    
    Give user permissions:

    ```
    sudo chown steam:steam /home/steam/ -R
    ```
    ```
    sudo chmod -R 755 /home/steam/
    ```

3. Change to the "steam" user's home directory:

    ```
    cd /home/steam
    ```

4. Enable the multiverse repository:

    ```
    sudo add-apt-repository multiverse
    ```

5. Enable the i386 architecture:

    ```
    sudo dpkg --add-architecture i386
    ```

6. Update your package list:

    ```
    sudo apt update
    ```

7. Install SteamCMD:

    ```
    sudo apt install steamcmd
    ```

8. Switch to the "steam" user:

    ```
    su - steam
    ```

9. Change to the home directory of the "steam" user:

    ```
    cd
    steamcmd
    ```

10. Create a directory for your Project Zomboid server installation:

    ```
    force_install_dir /home/steam/pzsteam
    ```

11. Log in to SteamCMD anonymously:

    ```
    login anonymous
    ```

12. Update and validate the Project Zomboid server files:

    ```
    app_update 380870 validate
    ```

13. Exit SteamCMD:
   
    ```
    exit
    ```

## :gear: Configuration

1. Change the Xmx parameter, to specify the correct amount of gb RAM you would like to be dedicated to Zomboid:

    ```
    cd /home/steam/pzsteam
    ```

    Then change the file called `ProjectZomboid64.json` in the Xmx parameters, to specify the correct RAM dedicated to server.

    ```
    sudo nano ProjectZomboid64.json
    ```

    ![image](https://github.com/Bobagi/Zomboid-Ubuntu-Server/assets/45888141/e945f3f0-156c-448f-b62f-6e0332ba98f2)
    In that case, i'm using 8g of RAM.
    
2. Once you have configured the settings as you like, you need to create a server, in your local machine to make the configurations you want, and then navigate to the following folder on your Windows machine if you already have a server:

    ```
    C:\Users\yourusername\Zomboid\Server
    ```

3. In that folder, copy the following files:

    - yourservername.ini
    - yourservername_spawnregions.lua
    - yourservername_SandboxVars.lua

4. In the PZ server directory on your Linux server paste these files:

    ```
    /home/steam/Zomboid/Server
    ```

These steps should help you install and configure your Project Zomboid server. Make sure to replace "yourservername" and "yourusername" with the appropriate values for your setup.

## :joystick: Running the Server

1. Start a `screen` session:

    ```
    screen -S zomboid
    ```

2. Navigate to the server files directory and run the server:

    ```
    cd /home/steam/pzsteam
    ```

    ```    
    ./start-server.sh -servername yourservername
    ```

3. To detach from the screen session (and keep the server running in the background), press `Ctrl + A`, then `D`.

4. To attach it again:

    ```
    screen -r zomboid
    ```

## :godmode: Installing Mods

1. Download the mods you wish to install to your local computer. (https://steamcommunity.com/app/108600/discussions/0/3428846977656275044/)

2. Use `scp` or any other file transfer method to upload the mods to your VPS:

    ```
    scp /path/mods pzserver@your_vps_ip:/home/pzserver/Zomboid/mods/
    ```

    (Replace `/path/to/mods`, `pzserver`, `your_vps_ip` with the appropriate paths, username, and IP address.)
   
   Or use another method to paste the mods folder in the server, as Filezilla.

3. Once uploaded, add the mods to your `ServerSettings.ini` file under the `Mods` section.

## :scroll: License

This project is open-source and available under the MIT License. See the [LICENSE](LICENSE) file for more information.

## 🥫❤️ Buy me a dog food can

![PayPal](https://img.shields.io/badge/PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white)
[![Donate with PayPal](https://www.paypalobjects.com/en_US/i/btn/btn_donate_LG.gif)](https://www.paypal.com/donate?hosted_button_id=23PAVC8AMJGYW)

## :mailbox_with_mail: Contact

If you have any questions, suggestions, or issues, please open an issue in the repository.
