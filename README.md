# Smith Sync

## Description 

This project contains general purpose tools for backup purposes which are built with [aktos-bash-lib](https://github.com/aktos-io/aktos-bash-lib). Scripts are intended to be 
* small 
* readable 
* extendable 
* portable


### Rationale

Backup operations involve many actions, such as attaching physical disk(s),
decrypting and/or mounting partitions, sending changes, generating logs, generating restoration scripts, cleaning up,
etc... That's why full backup operations are not simple and every backup procedure will be diverged eventually.

This leads the system admins to write their own scripts around the general purpose tool they choose. Problem arises here: the surrounding script would be highly complex and hard to maintain.

This project is filling the gap by providing high level Bash functions for backup tasks (BTRFS in mind, but will fit for any scenario) in order to keep "surrounding scripts" very simple, easily customizable, maintainable.

## Disclaimer

Although I use these tools in my everyday backup tasks, you **MUST** take appropriate actions (eg. multiple offline backups) in order not to loose/destroy your backups and even your operating system. In other words, use at your own risk.

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

# Intended Usage

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

# Example Toolset

See [erik-sync](https://github.com/ceremcem/erik-sync) for an example usage. `erik-sync` is my current, everyday backup toolset. 

# Helper HOWTOs

(See [doc](./doc))
