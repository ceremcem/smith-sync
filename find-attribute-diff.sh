#!/bin/bash
_sdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

usage() { echo $@ >&2; echo "Usage: $0 <older-snapshot> <newer-snapshot>" >&2; exit 1; }

[ $# -ge 2 ] || usage "Incorrect invocation";
SNAPSHOT_OLD=$1;
SNAPSHOT_NEW=$2;

[[ $(whoami) = "root" ]] || { sudo $0 "$@"; exit 0; }

[ -d $SNAPSHOT_OLD ] || usage "$SNAPSHOT_OLD does not exist";
[ -d $SNAPSHOT_NEW ] || usage "$SNAPSHOT_NEW does not exist";

shift
shift

>&2 echo "INFO: Getting utimes changes"

changed_utime=$(btrfs send -q --no-data -p "$SNAPSHOT_OLD" "$SNAPSHOT_NEW" \
    | sudo btrfs receive --dump \
    | grep ^utimes \
    | awk '{print $2}' \
    | sort \
    | uniq)

>&2 echo "INFO: Examining $(echo "$changed_utime" | wc | awk '{print $1}') files"

while read -r _f; do
    file=$(echo $_f | cut -d'/' -f3-)
    [[ -z $file ]] && continue
    _old=$SNAPSHOT_OLD/$file
    _new=$SNAPSHOT_NEW/$file
    [ \( -d "$_old" -o -f "$_old" \) -a ! -L "$_old" ] || continue
    [ \( -d "$_new" -o -f "$_new" \) -a ! -L "$_new" ] || continue
    old_attr=$(lsattr -d $_old | awk '{print $1}')
    new_attr=$(lsattr -d $_new | awk '{print $1}')
    [[ "$old_attr" != "$new_attr" ]] && echo "$old_attr    $new_attr    $file"
done <<< "$changed_utime"
