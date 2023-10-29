To allow your friend SSH access to only the `steam` folder, you can set up an SFTP chroot environment. This restricts them to their assigned directory and does not give them shell access. 

Here’s how you can set it up:

### 1. Create SSH Key for Your Friend
Have your friend generate an SSH key pair and send you the public key. If they are using a Linux or macOS system, they can generate an SSH key pair with the following command:
```bash
ssh-keygen
```
The public key will be in a file with a `.pub` extension, typically located at `~/.ssh/id_rsa.pub`.

### 2. Add the Public Key to the `steam` User’s `~/.ssh/authorized_keys` File
As the `steam` user or another user with the necessary permissions, add the public key to the `~/.ssh/authorized_keys` file in the `steam` user’s home directory. If this file or the `~/.ssh` directory does not exist, you can create them with the appropriate permissions:
```bash
sudo -u steam mkdir /home/steam/.ssh
sudo -u steam touch /home/steam/.ssh/authorized_keys
sudo -u steam chmod 700 /home/steam/.ssh
sudo -u steam chmod 600 /home/steam/.ssh/authorized_keys
sudo -u steam nano /home/steam/.ssh/authorized_keys
```
Add your friend’s public key to the `authorized_keys` file.

### 3. Edit the SSHD Config File
Edit the SSHD configuration file to create a chroot environment.
```bash
sudo nano /etc/ssh/sshd_config
```
Add the following lines at the end of the file:
```bash
Match User steam
    ChrootDirectory %h
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
    PasswordAuthentication no
```
This configuration:
- Restricts the `steam` user to their home directory (`%h` is a placeholder for the user’s home directory).
- Forces the use of internal SFTP, preventing shell access.
- Disables TCP forwarding and X11 forwarding.
- Disables password authentication for the `steam` user, requiring key authentication.

### 4. Restart the SSH Service
After saving your changes to the SSHD configuration file, restart the SSH service to apply them:
```bash
sudo systemctl restart ssh
```

### 5. Test the Connection
Have your friend test the connection using SFTP:
```bash
sftp steam@your_server_ip
```
They should be able to connect and access the `/home/steam` directory, but they should not be able to navigate to any parent directories.

Please ensure that the `steam` user’s home directory is owned by `root` and has the appropriate permissions, as the chroot environment requires this for security reasons:
```bash
sudo chown root:root /home/steam
sudo chmod 755 /home/steam
```
The `steam` user should still own their subdirectories and files within `/home/steam`.

By following these steps, you should be able to provide your friend with restricted SFTP access to the `steam` user’s home directory.