# Guide to Host Server Setup 

1. Setup hardware (with BTRFS, preferably) 

    1. See https://seravo.fi/2016/perfect-btrfs-setup-for-a-server
    
3. Install toolset:

       apt-get install lxc tmux git 
  
2. Install LXC
    1. Apt-get install LXC
    2. Install [LXC-to-the-Future](https://github.com/aktos-io/lxc-to-the-future)
    3. Make [LXC port forwardings](https://github.com/aktos-io/lxc-to-the-future/blob/master/network-configuration.md#1-setup-nat-connection)
    4. Restore (or make from scratch) the container settings in `/var/lib/lxc/*/config`
    
