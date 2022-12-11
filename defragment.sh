#!/bin/bash
set -eu
sudo btrfs filesystem defragment -rvf $1
