# Smith Sync

Backup systems requires many actions, starting from attaching physical disk(s),
decrypting and/or mounting partitions, sending changes, generating logs, cleanup,
etc...

There are lots of tools (especially the ones that are specialized for BTRFS filesystems) which are
designed for a very specific use case, probably that fits the toolset author's case. Any system admin may require different ways to make backups, where they would likely
end up writing their own wrapper scripts around these tools to make their tasks done.

This library is intended to provide API first and then some specific tools that
fits **only my own use case**, which will provide enough API functions in order to let anyone write their own tools

![image](https://user-images.githubusercontent.com/6639874/27219245-ad96ae66-5289-11e7-804f-61696e89a32f.png)

# Disclaimer

Although I use these tools in my everyday backup tasks, this library and tools are in a very early stage and you **SHOULD** take appropriate actions (eg. multiple offline backups) in order not to loose/destroy your backups and even your operating system. 
