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
It is the debhelper version. 12 should be kept.

### `rules`
This file is the script ran to build the package. When building a classic debian package from source, this is where the compilation process occurs. It is executed in a chroot environment. Typically, when binaries need to be included in a package, this file is used to control the source compilation process.

You can see which steps will be performed by running 'dh binary --no-act' in the packaging directory.

A directive 'dh_name' can be overriden by defining the 'override_dh_name' directive in the rules file.
In our case, we define the 'override_dh_auto_install'. We create the directory that will be used for the binaries.

#### `override_dh_auto_install`
```make
override_dh_auto_install:
# downloaded binaries directory
	mkdir -p ${PKGDIR}/var/lib/storagenode
	mkdir -p ${PKGDIR}/etc/storagenode/identity
```

Overrides default `dh_auto_install` target creating directories for config `/etc/storagenode` and binaries `/var/lib/storagenode`.
Actual storage data is put to `/var/lib/storagenode/storage`.

#### `override_dh_installsystemd`
```make
override_dh_installsystemd:
	dh_installsystemd --name=storagenode
	dh_installsystemd --name=storagenode-updater
```

Overrides default `override_dh_installsystemd` to install both `storagenode` and `storagenode-updater` services.

Be careful, rules is not the right place to make changes to the user config. These steps are not run on the user machine.
They are only performed when building the package.

### `preinst`
This is the script that will be run before the installation process has completed.
It takes as an argument the operation that is being performed ('install', 'install <old-version>', 'upgrade <new-version>',
'abort-upgrade <new-version>').

- Check if host architecture is supported. `supported archs`: `amd64 armhf arm64`

### `postinst`
This is the script that will be run after the installation process has completed.
It takes as an argument the operation that is being performed ('configure', 'abort-upgrade', 'abort-remove', 'abort-deconfigure').

In our case, we perform the following operations:
- retrieve the user configuration using debconf
- download the binaries for host architecture
- add a user in the system that will run the services
- copy identity to `/etc/storagenode/identity` if none
- setup storagenode if it hasn't been setup yet
- change ownership of `/var/lib/storagenode` and `/etc/storagenode` directories

### `prerm`
This file contains the steps to be run before removing the package.

### `postrm`
This file contains the steps to be run after removing the package. Removes storagenode and storagenode-updater binaries.

### `storagenode.service` and `storagenode-updater.service`
These are the services that will be installed and which will run the binaries.

#### `storagenode` service unit file
```service
# This is a SystemD unit file for the Storage Node
# To configure:
# - Update the user and group that the service will run as (User & Group below)
# - Ensure that the Storage Node binary is in /usr/local/bin and is named storagenode (or edit the ExecStart line
#   below to reflect the name and location of your binary
# - Ensure that you've run setup and have edited the configuration appropriately prior to starting the
#   service with this script
# To use:
# - Place this file in /etc/systemd/system/ or wherever your SystemD unit files are stored
# - Run systemctl daemon-reload
# - To start run systemctl start storagenode

[Unit]
Description  = Storage Node service
After        = syslog.target network.target

[Service]
Type         = simple
User         = storj-storagenode
Group        = storj-storagenode
ExecStart    = /var/lib/storagenode/storagenode run --config-dir "/etc/storagenode"
Restart      = on-failure
NotifyAccess = main

[Install]
Alias        = storagenode
WantedBy     = multi-user.target
```

#### `storagenode-updater` service unit file
```service
# To configure:
# - Update the user and group that the service will run as (User & Group below)
# - Ensure that the Storage Node binary is in /usr/local/bin and is named storagenode (or edit the ExecStart line
#   below to reflect the name and location of your binary
# - Ensure that you've run setup and have edited the configuration appropriately prior to starting the
#   service with this script
# To use:
# - Place this file in /etc/systemd/system/ or wherever your SystemD unit files are stored
# - Run systemctl daemon-reload
# - To start run systemctl start storagenode

[Unit]
Description  = Storage Node Updater service
After        = syslog.target network.target

[Service]
Type         = simple
User         = storj-storagenode
Group        = storj-storagenode
ExecStart    = /var/lib/storagenode/storagenode-updater run --config-dir "/etc/storagenode" --binary-location "/var/lib/storagenode/storagenode"
Restart      = on-failure
NotifyAccess = main

[Install]
Alias        = storagenode-updater
WantedBy     = multi-user.target
```

#### `Unit` section
##### `Description=`
Description of the service run by service unit file.

##### `After=`
Requires a certain target/service to be running before starting the current unit. `syslog.target` first creates
the socket /dev/log and then starts the syslog daemon.

#### `Service` section
##### `Type=`
Configures the process start-up type for this service unit. One of `simple`, `exec`, `forking`, `oneshot`, `dbus`,
`notify` or `idle`.

`Simple`: (the default if `ExecStart=` is specified but neither `Type=` nor `BusName=` are), the service manager will consider
the unit started immediately after the main service process has been forked off. It is expected that the process
configured with `ExecStart=` is the main process of the service. In this mode, if the process offers functionality to other
processes on the system, its communication channels should be installed before the service is started up (e.g. sockets
set up by `systemd`, via socket activation), as the service manager will immediately proceed starting follow-up units, right
after creating the main service process, and before executing the service's binary.

##### `User=`, `Group=`
Set the UNIX user or group that the processes are executed as, respectively. Takes a single user or
group name, or a numeric ID as argument.

##### `ExecStart=`
Commands with their arguments that are executed when this service is started.

##### `Restart=`
Configures whether the service shall be restarted when the service process exits, is killed, or a timeout is
reached. The service process may be the main service process, but it may also be one of the processes specified with
`ExecStartPre=`, `ExecStartPost=`, `ExecStop=`, `ExecStopPost=`, or `ExecReload=`.

Takes one of `no`, `on-success`, `on-failure`, `on-abnormal`, `on-watchdog`, `on-abort`, or `always`.

If set to `on-failure`, the service will be restarted when the process exits with a non-zero exit code, is terminated by a
signal (including on core dump, but excluding the aforementioned four signals), when an operation (such as service reload)
times out, and when the configured watchdog timeout is triggered.

##### `NotifyAccess=`
Controls access to the service status notification socket, as accessible via the sd_notify(3) call. Takes one of `none`
(the default), `main`, `exec` or `all`. If `none`, no daemon status updates are accepted from the service processes, all status
update messages are ignored.

`main` - only service updates sent from the main process of the service are accepted.

#### `Install` section
##### `Alias=`
A space-separated list of additional names this unit shall be installed under. The names listed here must have the same
suffix (i.e. type) as the unit filename. This option may be specified more than once, in which case all listed names are
used. At installation time, `systemctl` enable will create symlinks from these names to the unit filename. Note that not
all unit types support such alias names, and this setting is not supported for them. Specifically, `mount`, `slice`, `swap`,
and `automount` units do not support aliasing.

##### `WantedBy=`
This option may be used more than once, or a space-separated list of unit names may be given. A symbolic link is created
in the `.wants/` or `.requires/` directory of each of the listed units when this unit is installed by `systemctl` enable.
This has the effect that a dependency of type `Wants=` or `Requires=` is added from the listed unit to the current unit.
The primary result is that the current unit will be started when the listed unit is started.

After running `systemctl enable`, a `symlink /etc/systemd/system/multi-user.target.wants/{storagenode,storagenode-updater}.service`
linking to the actual unit will be created. It tells `systemd` to pull in the unit when starting multi-user.target.
The inverse `systemctl` disable will remove that symlink again.

### Debconf
#### `templates` file
It contains the values to be asked to the user and their description. 

#### `storagenode.config` file
The checks on the value provided by the user should be done in this file.

## Reprepro


