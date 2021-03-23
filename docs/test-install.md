## Pre-installation

1. Visit the [Releases](https://github.com/storj/storj/releases) page and download archives with binaries for your architecture.

   You need one of the 

   **storagenode_linux_amd.zip \ storagenode_linux_arm.zip \ storagenode_linux_arm64.zip**

   and one of the 

   **storagenode-updater_linux_amd.zip \ storagenode-updater_linux_arm.zip \ storagenode-updater_linux_arm64.zip**

   place this files to some folder, f.e. **home/{user}/storagenode-binaries**

2. install needed software for debian packaging - https://www.debian.org/doc/manuals/maint-guide/start.en.html#needprogs

   as for me - i needed only to install **debhelper** on my ubuntu 20

   `sudo apt-get update`

   `sudo apt-get install debhelper`

3. install [git](https://git-scm.com/downloads) and clone [repository](https://github.com/storj/storagenode-deb) with storage node debian package

   f.e. `git clone git@github.com:storj/storagenode-deb.git`

   lets assume that you clone this repo to **home/{user}/storagenode-deb**

4.  generate [identity](https://documentation.storj.io/dependencies/identity). 

   lets assume that you place identity to **home/{user}/storagenode-identity**

5. setup [port-forwarding](https://documentation.storj.io/dependencies/port-forwarding)

  

## Build package

lets build package 

`cd home/{user}/storagenode-deb/packaging`

`dpkg-buildpackage -us -uc -b`

you should see a lot of logs, smth like:

`dpkg-buildpackage: info: source package storagenode`
`dpkg-buildpackage: info: source version 1.0.0`
`dpkg-buildpackage: info: source distribution unstable`
`dpkg-buildpackage: info: source changed by Storj <storj@storj.io>`
`dpkg-buildpackage: info: host architecture amd64`
 `dpkg-source --before-build .`
`dpkg-source: info: using options from packaging/debian/source/options: --tar-ignore=.git`
 `fakeroot debian/rules clean`

`...`

`...`

`...`

`dpkg-deb: building package 'storagenode' in '../storagenode_1.0.0_all.deb'.`
 `dpkg-genbuildinfo --build=binary`
 `dpkg-genchanges --build=binary >../storagenode_1.0.0_amd64.changes`
`dpkg-genchanges: info: binary-only upload (no source code included)`
 `dpkg-source --after-build .`
`dpkg-source: info: using options from packaging/debian/source/options: --tar-ignore=.git`
`dpkg-buildpackage: info: binary-only upload (no source included)`



as a result we will receive **storagenode_1.0.0_all.deb, storagenode_1.0.0_amd64.buildinfo, storagenode_1.0.0_amd64.changes** files in

**home/{user}/storagenode-deb** directory.

## Storage node installation

1. `cd home/{user}/storagenode-deb/packaging/debian`

2. now we have to edit postinst file. 

   During installation process we will download binaries (that you have already downloaded and placed to 

   folder **home/{user}/storagenode-binaries**) from the binaries server. 

   But now we should use own solution to get this binaries.

   To specify url for this server lets open **postinst** file and change

3. `cd home/{user}/storagenode-deb`

4. `sudo dpkg -i storagenode_1.0.0_all.deb`

   after calling this command you should see installation menu.

   **Directory holding the identity credentials:** - enter **home/{user}/storagenode-identity**

   **Storj payout address (ERC20-compatible):** - enter your ethereum wallet

   **External address/port (<ip>:<port>):** - here you should write your external address with :28967

   Before this step you should have configured port forwarding.

   You can check your external address and that your port is opened with this [tool](https://www.yougetsignal.com/tools/open-ports/)

   **Allocated disk space:** - here you can enter any number with G or T suffix.



## Deleting storagenode

1. remove folder with config and identity - `sudo rm -rf /etc/storagenode/`
2. remove storage folder - `sudo rm -rf /var/lib/storagenode/`
3. remove package - `sudo dpkg --purge remove storagenode`
4. delete user (with appropriate group) - `sudo userdel storj-storagenode`

