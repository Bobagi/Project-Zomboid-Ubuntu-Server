# Zomboid Server on Ubuntu 23.04

This repository contains scripts, configuration files, and documentation to help you set up a Project Zomboid server on an Ubuntu 23.04 64-bit VPS hosted with Hostinger. This is a personal project designed to create a private server for playing with friends. 

## Table of Contents
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

## Installation

1. Update your system's package list:

    ```
    sudo apt update
    ```

2. Install the required dependencies:

    ```
    sudo apt install openjdk-11-jre-headless screen
    ```

3. Create a user for running the server (for security purposes):

    ```
    sudo adduser pzserver
    ```

4. Switch to the new user:

    ```
    su - pzserver
    ```

5. Download and extract the Project Zomboid Dedicated Server files:

    ```
    wget LINK_TO_ZOMBOID_SERVER_FILES
    tar -xzvf FILE_NAME.tar.gz
    ```

    (Replace `LINK_TO_ZOMBOID_SERVER_FILES` and `FILE_NAME.tar.gz` with the appropriate download link and file name.)

## Configuration

1. Navigate to the server files directory:

    ```
    cd path/to/server/files
    ```

2. Edit the server settings as per your requirements. You can use `nano` or any other text editor:

    ```
    nano ServerSettings.ini
    ```

3. Save the changes and exit the text editor.

## Running the Server

1. Start a `screen` session:

    ```
    screen -S zomboid-server
    ```

2. Navigate to the server files directory and run the server:

    ```
    cd path/to/server/files
    ./start-server.sh
    ```

3. To detach from the screen session (and keep the server running in the background), press `Ctrl + A`, then `D`.

## Installing Mods

1. Download the mods you wish to install to your local computer.
2. Use `scp` or any other file transfer method to upload the mods to your VPS:

    ```
    scp /path/to/mods pzserver@your_vps_ip:/home/pzserver/Zomboid/mods/
    ```

    (Replace `/path/to/mods`, `pzserver`, `your_vps_ip` with the appropriate paths, username, and IP address.)

3. Once uploaded, add the mods to your `ServerSettings.ini` file under the `Mods` section.

## License

This project is open-source and available under the MIT License. See the [LICENSE](LICENSE) file for more information.

## Contact

If you have any questions, suggestions, or issues, please open an issue in the repository.

## Acknowledgements

- Thanks to the Project Zomboid team for creating an awesome game.
- Thanks to Hostinger for providing the VPS hosting services.
- Thanks to all contributors and players.

Please note that you need to replace placeholder text such as file paths, IP addresses, and download links with actual values according to your setup.
