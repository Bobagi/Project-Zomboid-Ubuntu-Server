# :zombie: Zomboid Server on Ubuntu 23.04

This repository contains scripts, configuration files, and documentation to help you set up a Project Zomboid server on an Ubuntu 23.04 64-bit VPS hosted with Hostinger. This is a personal project designed to create a private server for playing with friends. 

## :bookmark_tabs: Table of Contents
1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Running the Server](#running-the-server)
5. [Installing Mods](#installing-mods)
6. [License](#license)
7. [Contact](#contact)
8. [Acknowledgements](#acknowledgements)

## Prerequisites

Before you begin, ensure you have met the following requirements:

- A VPS running Ubuntu 23.04 64-bit
- sudo privileges on the VPS
- Basic knowledge of terminal and Linux commands
- Project Zomboid game purchased on a platform like Steam

Sure, I can help you format the installation instructions more clearly:

## Installation

1. Update and upgrade your system:

   ```
   sudo apt-get update && sudo apt-get upgrade -y
   ```
   ```
   sudo ufw allow 16261
   ```
    ```
   sudo ufw allow 16262
   ```

2. Add a new user named "steam":

   ```
   sudo adduser steam
   ```
   ```
   usermod -aG sudo steam
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

14. Once you have configured the settings as you like, navigate to the following folder on your Windows machine if you already have a server:

    ```
    C:\Users\yourusername\Zomboid\Server
    ```

15. In that folder, copy the following files:

    - yourservername.ini
    - yourservername_spawnregions.lua
    - yourservername_SandboxVars.lua

16. In the PZ server directory on your Linux server paste these files:

    ```
    /home/steam/Zomboid/Server
    ```
   
   And change the file called `ProjectZomboid64.json` in the Xmx parameters, to specify the correct RAM dedicated to server.

17. Start your Project Zomboid server with the desired server name (replace "pzOlimpoServer" with your desired server name):

    ```
    ./start-server.sh -servername yourservername
    ```

These steps should help you install and configure your Project Zomboid server. Make sure to replace "yourservername" and "yourusername" with the appropriate values for your setup.
## Configuration

1. Navigate to the server files directory:

    ```
    cd home/steam/pzserver
    ```

2. Edit the server settings as per your requirements. You can use `nano` or any other text editor:

    ```
    nano ServerSettings.ini
    ```

3. Save the changes and exit the text editor.

## Running the Server

1. Start a `screen` session:

    ```
    screen -S zomboid
    ```

2. Navigate to the server files directory and run the server:

    ```
    cd home/steam/pzserver
    ./start-server.sh -servername yourservername
    ```

3. To detach from the screen session (and keep the server running in the background), press `Ctrl + A`, then `D`.

## Installing Mods

1. Download the mods you wish to install to your local computer.
2. Use `scp` or any other file transfer method to upload the mods to your VPS:

    ```
    scp /path/mods pzserver@your_vps_ip:/home/pzserver/Zomboid/mods/
    ```

    (Replace `/path/to/mods`, `pzserver`, `your_vps_ip` with the appropriate paths, username, and IP address.)
   
   Or use another method to paste the mods folder in the server, as Filezilla.

3. Once uploaded, add the mods to your `ServerSettings.ini` file under the `Mods` section.

## License

This project is open-source and available under the MIT License. See the [LICENSE](LICENSE) file for more information.

## :mailbox_with_mail: Contact

If you have any questions, suggestions, or issues, please open an issue in the repository.

## Acknowledgements

- Thanks to the Project Zomboid team for creating an awesome game.
- Thanks to Hostinger for providing the VPS hosting services.
- Thanks to all players.
