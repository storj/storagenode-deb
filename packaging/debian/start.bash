#!/bin/bash

pidfile="/var/run/storagenode/storagenode.pid"

/var/storagenode/storagenode run $@ &

pid=$!
echo $pid > $pidfile

wait $pid
exitcode=$?

rm $pidfile
exit $exitcode
