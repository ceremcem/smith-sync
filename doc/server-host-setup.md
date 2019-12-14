# Guide to Container Host Server Setup 

1. Setup hardware (with BTRFS, preferably) 

    1. See https://seravo.fi/2016/perfect-btrfs-setup-for-a-server
    
2. Install toolset:

       apt-get install lxc tmux git
       
3. Configure `tmux`: 

    1. https://stackoverflow.com/a/42201167/1952991
  
4. Configure LXC
    1. Install [LXC-to-the-Future](https://github.com/aktos-io/lxc-to-the-future)
    2. Make [LXC port forwardings](https://github.com/aktos-io/lxc-to-the-future/blob/master/network-configuration.md#1-setup-nat-connection)
    3. Prepare a base container
    4. Restore (or make from scratch) the container settings in `/var/lib/lxc/*/config`
    5. Start the containers with a 30 second delay just in case.
    
5. Install `watch-ip-change` to update public IP periodically.

6. Monitor the disk health: https://github.com/ceremcem/monitor-btrfs-disk

7. Prepare for switching between master and slave modes:

    * In slave (backup) mode:
        1. CouchDB should run as normal. It will be in sync every time.
        2. Git server, file server and other servers should `rsync` periodically.
        3. LXC container settings from master server should also be synced:
            1. LXC Port forwardings
            2. Container configurations 
    * Switching to master mode:
        > Deciding if the node is master: 
        > 1. Poll `dig +s master.example.com`
        > 2. Compare with node's own public IP 
        > 3. If matches, this node is now master.
        
        1. Stop slave mode sync
        2. Update `example.com` IP
        
8. Be prepared for disk failures:

    1. TODO: Prepare a script to re-format, encrypt, set up RAID-1 and sync when a disk fails.
    
9. Monitor for intrusions:

    1. Fail-to-ban
        

