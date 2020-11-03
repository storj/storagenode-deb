#!/bin/bash

file=$1
echo "File = $file"
usage=$(awk '/Usage:/{flag=1; next} /Flags:/{flag=0} flag' $file)
flags=$(awk '/Flags/{flag=1; next} /ENDFILE/{flag=0} flag' $file)
awk -v r="$usage" '{gsub(/storagenode-usage/,r)}1' storagenode.1.template > storagenode.1.tmp
awk -v r="$flags" '{gsub(/storagenode-flags/,r)}1' storagenode.1.tmp > storagenode.1
rm storagenode.1.tmp

