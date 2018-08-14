# Smith Sync

### Description 

This project contains general purpose BTRFS sync tools which are built with [aktos-bash-lib](https://github.com/aktos-io/aktos-bash-lib). Scripts are intended to be 
* small 
* readable 
* extendable 


### Rationale

Backup operations involve many actions, such as attaching physical disk(s),
decrypting and/or mounting partitions, sending changes, generating logs, generating restoration scripts, cleaning up,
etc... That's why every backup procedure will eventually vary greatly.

This leads the system admins to write their own scripts around the general purpose tool they choose. Problem is that the surrounding script would be highly complex and hard to maintain.

This project is filling the gap by providing high level Bash functions for backup tasks (BTRFS in mind, but will fit for any scenario) in order to keep "surrounding scripts" very simple, easily costumizable, maintainable.

# Disclaimer

Although I use these tools in my everyday backup tasks, you **MUST** take appropriate actions (eg. multiple offline backups) in order not to loose/destroy your backups and even your operating system. In other words, use at your own risk.

# Available Tools

### `sync`

Shell scrip to sychronize source and destination in the same hierarchy.

```console
./sync /path/to/source/snapshots /path/to/dest/snapshots
```

# Intended Usage

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

See [erik-sync](https://github.com/ceremcem/erik-sync) for an example usage. 
