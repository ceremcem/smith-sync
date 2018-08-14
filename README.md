# Smith Sync

> TL;DR; <br />
> Contains general purpose tools which are built with [aktos-bash-lib](https://github.com/aktos-io/aktos-bash-lib)


### Rationale

Backup systems requires many actions, starting from attaching physical disk(s),
decrypting and/or mounting partitions, sending changes, generating logs, cleanup,
etc...

There are lots of tools (especially the ones that are specialized for BTRFS filesystems) which are
designed for a very specific use case, probably that fits the toolset author's case. Any system admin may require different ways to make backups, where they would likely
end up writing their own wrapper scripts around these tools to make their tasks done.

This library is intended to provide API first and then some specific tools.


# Disclaimer

Although I use these tools in my everyday backup tasks, this library and tools are in a very early stage and you **SHOULD** take appropriate actions (eg. multiple offline backups) in order not to loose/destroy your backups and even your operating system.

# Available Tools

### `sync`

Shell scrip to sychronize target and destination in the same hierarchy.

```console
$ ./sync /path/to/source/snapshots /path/to/dest/snapshots
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

3. Use tools with relative paths
4. Use functions available in `smith-sync/lib/all.sh`

# Example Toolset

TODO: Add erik toolset as an example 
