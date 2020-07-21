# Storage Node Debian Package Contributor Guide

## Dependencies
To build the package, you will need the debian packaging tools: build-essential, devscripts and debhelper.

## Build the package
Once they are installed, go to the 'packaging' directory and run the following command:
`
dpkg-buildpackage -us -uc -b
`
If successful, it should create a storagenode-version.deb file. You can install it on a debian system using the following command:
`
dpkg -i storagenode-version.deb
`

## Structure

### `control`
This file contains the information about the package: its name, its description, its dependencies (here debhelper >= 10 is necessary for installing the systemd services easily),
the architecture it is made for and infos about the maintainer.

### `compat`
It is the debhelper version. 10 should be kept.

### `rules`
This file is the script ran to build the package. When building a classic debian package from source, this is where the compilation process occurs. It is executed in a chroot environment. Typically, when binaries need to be included in a package, this file is used to control the source compilation process.

You can see which steps will be performed by running 'dh binary --no-act' in the packaging directory.

A directive 'dh_name' can be overriden by defining the 'override_dh_name' directive in the rules file.
In our case, we define the 'override_dh_auto_install'. We create the directory that will be used for the binaries.

Be careful, rules is not the right place to make changes to the user config. These steps are not run on the user machine. They are only performed when building the package.

### `postinst`
This is the script that will be run after the installation process has completed. It takes as an argument the operation that is being performed ('configure', 'abort-upgrade', 'abort-remove', 'abort-deconfigure').

In our case, we perform the following operations:
- retrieve the user configuration using debconf
- download the binaries
- add a user in the system that will run the services

### `prerm`
This file contains the steps to be run when removing the package.

### `storagenode.service` and `storagenode-updater.service`
These are the services that will be installed and which will run the binaries.

### Debconf
#### `templates` file
It contains the values to be asked to the user and their description. 

#### `storagenode.config` file
The checks on the value provided by the user should be done in this file.

## Reprepro


