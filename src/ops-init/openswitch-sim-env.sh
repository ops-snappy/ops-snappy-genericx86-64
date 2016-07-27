#!/bin/bash

#
# Openswitch Environment Settings
#
source $SNAP/usr/sbin/openswitch-common-env

# Required directories
BINDIR=$SNAP/opt/openvswitch/bin
SBINDIR=$SNAP/opt/openvswitch/sbin
DBDIR=$SNAP_DATA/var/run/openvswitch-sim
LOGDIR=$SNAP_DATA/var/log/openvswitch-sim
SCHEMADIR=$SNAP/opt/openvswitch/share/openvswitch
PIDDIR=$DBDIR
CTLDIR=$PIDDIR

# Override the default dir locations in ops-openvswitch
export OVS_SYSCONFDIR=$SNAP/etc
export OVS_PKGDATADIR=$SCHEMADIR
export OVS_RUNDIR=$DBDIR
export OVS_LOGDIR=$LOGDIR
export OVS_DBDIR=$DBDIR
