#!/bin/bash

#
# Openswitch Environment Settings
#

# Syslog settings
LOGSYSLOG="SYSLOG"
LOGCONSOLE="CONSOLE"
LOGLVLDBG="DBG"
LOGLVLINFO="INFO"
SYSLOGDBG="-v${LOGSYSLOG}:${LOGLVLDBG}"
SYSLOGINFO="-v${LOGSYSLOG}:${LOGLVLINFO}"
CONSDBG="-v${LOGCONSOLE}:${LOGLVLDBG}"
CONSINFO="-v${LOGCONSOLE}:${LOGLVLINFO}"
LOGDEFAULT=${CONSINFO}

# Required directories
DBDIR=$SNAP_DATA/run/openvswitch
LOGDIR=$SNAP_DATA/var/log/openvswitch
VTEPDBDIR=$SNAP_DATA/var/local/openvswitch
PIDDIR=$DBDIR
CTLDIR=$PIDDIR
BINDIR=$SNAP/usr/bin
SBINDIR=$SNAP/usr/sbin
SCHEMADIR=$SNAP/usr/share/openvswitch
CFGDIR=$SNAP_DATA/etc/openswitch
OPTSBINDIR=$SNAP/opt/openvswitch/sbin
OPTSCHEMADIR=$SNAP/opt/openvswitch/share/openvswitch
SIMDBDIR=$SNAP_DATA/run/openvswitch-sim

# Override the default dir locations in ops-openvswitch
export OVS_SYSCONFDIR=$SNAP/etc
export OVS_PKGDATADIR=$SCHEMADIR
export OVS_RUNDIR=$DBDIR
export OVS_LOGDIR=$LOGDIR
export OVS_DBDIR=$DBDIR

# Override the default install_path and data_path in OpenSwitch
export OPENSWITCH_INSTALL_PATH=$SNAP
export OPENSWITCH_DATA_PATH=$SNAP_DATA
