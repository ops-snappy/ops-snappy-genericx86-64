#!/bin/bash

#
# Openswitch Environment Settings
#
source $SNAP/usr/sbin/openswitch-common-env

# Required directories
BINDIR=$SNAP/usr/bin
SBINDIR=$SNAP/usr/sbin
DBDIR=$SNAP_DATA/run/openvswitch
LOGDIR=$SNAP_DATA/var/log/openvswitch
VTEPDBDIR=$SNAP_DATA/var/local/openvswitch
PIDDIR=$DBDIR
CTLDIR=$PIDDIR
SCHEMADIR=$SNAP/usr/share/openvswitch

# Override the default dir locations in ops-openvswitch
export OVS_SYSCONFDIR=$SNAP/etc
export OVS_PKGDATADIR=$SCHEMADIR
export OVS_RUNDIR=$DBDIR
export OVS_LOGDIR=$LOGDIR
export OVS_DBDIR=$DBDIR
