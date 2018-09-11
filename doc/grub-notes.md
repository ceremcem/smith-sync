# GRUB2 Keyboard

### Status 

To be tested properly

### Objective

Generate keyboard layout file:

    ckbcomp -layout tr -variant f | grub-mklayout -o /media/ceremcem/cca-boot/grub/trf.gkb

add to grub.cfg: 

    terminal_input at_keyboard
    keymap it


