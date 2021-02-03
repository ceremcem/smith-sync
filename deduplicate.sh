#!/bin/bash
set -u
sudo rmlint --types="duplicates" \
    -g --config=sh:handler=clone $1
