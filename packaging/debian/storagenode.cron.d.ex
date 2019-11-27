#
# Regular cron jobs for the storagenode package
#
0 4	* * *	root	[ -x /usr/bin/storagenode_maintenance ] && /usr/bin/storagenode_maintenance
