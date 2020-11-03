#!/bin/bash


file=$1
if [ ! -f $file]; then
    echo "$file not found"
    exit 1
fi
echo "Generating manpage from file $file"
usage=$(awk '/Usage:/{flag=1; next} /Flags:/{flag=0} flag' $file)
flags=$(awk '/Flags/{flag=1; next} /ENDFILE/{flag=0} flag' $file)
awk -v r="$usage" '{gsub(/storagenode-usage/,r)}1' storagenode.1.template > storagenode.1.tmp
awk -v r="$flags" '{gsub(/storagenode-flags/,r)}1' storagenode.1.tmp > storagenode.1
rm storagenode.1.tmp

