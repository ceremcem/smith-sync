# Smith Sync

Backup systems requires many actions, starting from attaching physical disk(s),
decrypting and/or mounting partitions, sending changes, generating logs, cleanup,
etc...

There are lots of tools (especially the ones that are specialized for BTRFS filesystems) which are
designed for a very specific use case, probably that fits the toolset author's case. Any system admin may require different ways to make backups, where they would likely
end up writing their own wrapper scripts around these tools to make their tasks done.

This library is intended to provide API first and then some specific tools that
fits **only my own use case**, which will provide enough API functions in order to let anyone write their own tools

![image](https://user-images.githubusercontent.com/6639874/27061927-4cd8615a-4ff0-11e7-8dd0-c26238bb50e8.png)

# Disclaimer

Althoug I use these tools in my everyday backup tasks, this library and tools are in very early stage and you **SHOULD** take appropriate actions in order not to loose/destroy your backups and even your operating system. 

**DO NOT USE THESE TOOLS UNLESS YOU READ AND UNDERSTAND THEM!**
