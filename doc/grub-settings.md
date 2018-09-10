# GRUB2 Keyboard

Generate keyboard layout file:

    ckbcomp -layout tr -variant f | grub-mklayout -o /media/ceremcem/cca-boot/grub/trf.gkb

add to grub.cfg: 

    terminal_input at_keyboard
    keymap it


