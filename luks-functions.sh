find_crypt_partition () {
    # returns if a luks partition exists on the device
    local device=$1
    require_device $(blkid | grep $device | grep crypto_LUKS | awk '{print $1}' | sed -e 's/://g')
}
