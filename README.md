# smith-sync

Backup systems requires many actions, starting from attaching physical disk(s),
decrypting and/or mounting partitions, sending changes, generating logs, cleanup,
etc...

There are lots of tools (especially specialized for BTRFS filesystems) which are
designed for very specific use case.

Any system admin may require different ways to make backups, where they would likely
end up writing their own wrapper scripts to make tasks done.

This library is intended to provide API first and then some specific tools that
fits **my own use case**, which will provide anyone write their own tools.
