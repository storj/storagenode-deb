#!/bin/bash
set -e

[[ -z "${STORJNODE_DEB_ACCESS}" ]] && echo "STORJNODE_DEB_ACCESS envar not set" &&  exit 1
[[ -z "${STORJNODE_DEB_BUCKET}" ]] && echo "STORJNODE_DEB_BUCKET envar not set" &&  exit 1

setup_uplink() {
	curl -LJ0 --output /tmp/uplink.zip https://github.com/storj/storj/releases/download/v1.28.2/uplink_linux_amd64.zip
	unzip -o /tmp/uplink.zip -d /tmp
}

setup_uplink

paths=$(find apt-repository/www -mindepth 1 -type f)

for p in ${paths[@]}; do
	echo "-> pushing ${p}"
	/tmp/uplink --access $STORJNODE_DEB_ACCESS cp ${p} sj://$STORJNODE_DEB_BUCKET/${p#apt-repository/www/}
done