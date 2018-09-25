# Status 

WIP: 

1. https://unix.stackexchange.com/questions/471247/how-to-add-ssmtp-into-initramfs
2. http://jurjenbokma.com/ApprenticesNotes/getting_statlinked_binaries_on_debian.xhtml

# Adding binaries to initramfs

Scripts in `/usr/share/initramfs-tools/hooks` are executed on `update-initramfs`.


### Adding files:

1. Get the binary:

    1. Either install/compile a statically linked binary.
    2. Or add dynamically linked binaries with dependencies: `ldd /path/to/binary`

            mkdir tmp && cd tmp 
            cp `which ssmtp` . 
            `which ssmtp` | grep '=>' | awk '{print $3}' | xargs -i cp {} .
            `which ssmtp` | grep -v '=>' | awk '{print $1}' | # <-------------- how to get them?
  
2. Add hook script. 
3. Update initramfs.

Create the hook script in `/usr/share/initramfs-tools/hooks/ssmtp`:

```bash
#!/bin/sh
PREREQ=""
prereqs()
{
     echo "$PREREQ"
}

case $1 in
prereqs)
     prereqs
     exit 0
     ;;
esac

# End of template. Append your procedure after this line
# ------------------------------------------------------

source /usr/share/initramfs-tools/hook-functions      #provides copy_exec
rm -f ${DESTDIR}/bin/ssmtp                            #copy_exec won't overwrite an existing file
copy_exec /sbin/ssmtp.static /bin/ssmtp              #Takes location in filesystem and location in initramfs as arguments
```

Make the hook executable: 

```console
chmod +x /usr/share/initramfs-tools/hooks/ssmtp
```

Update initramfs: 

```
update-initramfs -u 
```
