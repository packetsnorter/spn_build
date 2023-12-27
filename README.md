## **Summary:**
This repo contains the files I use to build Safing's SPN Connunity nodes on my VPS providers' hosts.

## **Build Script**
The build script is build for Ubuntu 22.04, and contains several additional OS packages for my needs.

In addition, it installs NTOPNG so that I can monitor the network traffic to ensure that the node is functioning properly.  This does **NOT** allow me to see the encrypted SPN traffic.

The script also sets up the following:
  - Fail2Ban
  - IPTables / IP6Tables
  - Crontab for updates and cleanup.
  - An unprivilege user w/ pubic key SSH, SUDOERS, preferred UMASK, and corrected file permissions.
  - Safing SPN Community Node.

## **sshd_config:**

Replace /etc/ssh/sshd_config with this one for hardened, non-root login SSHD.
