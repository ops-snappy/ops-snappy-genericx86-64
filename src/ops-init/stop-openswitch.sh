#!/usr/bin/env bash

# Setup OpenSwitch environment variables
source $SNAP/usr/sbin/openswitch-common-env
source $SNAP/usr/sbin/openswitch-env

DBSVR="ovsdb-server.pid"

for i in $PIDDIR/*.pid ; do
    pid=`cat $i`
    if [ -z "${i##*$DBSVR}" ] ; then
        dbsvrpid=$pid
    else
        kill -9 $pid
    fi
done

if [ ! -z "$dbsvrpid" ] ; then
    sleep 1
    kill -9 $dbsvrpid
fi

rm -f  $PIDDIR/*.pid
rm -f  $CTLDIR/*.ctl

# Delete the Appliance/Simulator
source $SNAP/usr/sbin/openswitch-sim-env
for i in $PIDDIR/*.pid ; do
    pid=`cat $i`
    kill -9 $pid
done
rm -f  $PIDDIR/*.pid
rm -f  $CTLDIR/*.ctl

# Delete namespaces. This avoids errors when restarting the snap.
ip netns delete swns > /dev/null 2>&1 || true
ip netns delete nonet > /dev/null 2>&1 || true
