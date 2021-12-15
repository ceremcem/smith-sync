# Smith Sync

## Where does the name come from?

![smith-sync](https://user-images.githubusercontent.com/6639874/107101402-40330c80-6828-11eb-9165-7cf84ee74f9d.gif)

Your backups should be **exact copy** of your main system. Taking backups should be easy.  

## Rationale 

Backup operations involve many actions, such as attaching physical disk(s) (decrypting/opening/mounting multiple levels of layers and multiple partitions), sending changes, generating logs, generating restoration scripts, cleaning up, etc... That's why full backup operations are not simple and every backup procedure will be diverged eventually.

This leads the system admins to write their own scripts around the general purpose tools they choose. Problem arises here: the surrounding scripts would be highly complex and hard to maintain.

This project is filling the gap by providing high level Bash functions and scripts for backup tasks (BTRFS in mind, but will fit for any scenario) in order to keep "surrounding scripts" very simple, easily customizable, maintainable.

## Focus

This project describes a "backup" as "the exact copy of your whole main hard disk". You should grab your backup disk, boot your (or an equivalent) computer and continue your work where you left. Your backup tool (that you built on smith-sync) will have the following properties: 

* Backup disks are kept ready to boot the computer from the latest snapshot. 
* Backup procedure should not consume more than a few minutes for detecting the changes for 1 TB of real world data.
* Backup disks should be tested with an hypervisor (eg. VirtualBox) to prove that they are always ready to boot.
* Main system should keep snapshots of previous states and ready to rollback at any time.
* Backup (or main) disks should be prepared for theft. No data should be extracted from a stolen backup disk (or computer). 

This project provides the necessary tools to satisfy above requirements.

# Example

See [erik-sync](https://github.com/ceremcem/erik-sync) for an example usage. `erik-sync` is my current, everyday backup toolset. 

# Recommended Layout

Even though the available tools are standalone, it's highly encouraged to build your own toolset around smith-sync:

1. Create your own toolset

    ```console
    git init mybackupsystem
    cd mybackupsystem
    ```

2. Add `smith-sync` as a submodule

    ```console
    git submodule add https://github.com/ceremcem/smith-sync
    git submodule update --recursive
    ```

3. Create a script for each task (attach, detach, sync, take-snapshot, ...)
    1. Use `smith-sync` tools with relative paths
    2. Use functions available in `smith-sync/lib`

# Helper HOWTOs

(See [doc](./doc))

# Available Tools

## `btrfs-sync`

Shell scrip to synchronize source and destination with the same hierarchy.

```console
./btrfs-sync /path/to/source/snapshots /path/to/dest/snapshots
```

## `rsync.sh`

Same as `rsync` but uses a default [`exclude-list.txt`](./exclude-list.txt) which is optimized for rootfs backups. 

```console
./rsync.sh /path/to/source/ /path/to/dest/
```

# Disclaimer

Although I use these tools in my everyday backup tasks, you **MUST** take appropriate actions (eg. multiple offline backups) in order not to loose/destroy your backups and even your operating system. In other words, use at your own risk.

