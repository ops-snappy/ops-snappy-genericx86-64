#!/bin/bash

#
# Openswitch Common Environment Settings
#

# Syslog settings
LOGSYSLOG="SYSLOG"
LOGCONSOLE="CONSOLE"
LOGLVLDBG="DBG"
LOGLVLINFO="INFO"
LOGLVLERR="ERR"
SYSLOGDBG="-v${LOGSYSLOG}:${LOGLVLDBG}"
SYSLOGINFO="-v${LOGSYSLOG}:${LOGLVLINFO}"
SYSLOGERR="-v${LOGSYSLOG}:${LOGLVLERR}"
CONSDBG="-v${LOGCONSOLE}:${LOGLVLDBG}"
CONSINFO="-v${LOGCONSOLE}:${LOGLVLINFO}"
CONSERR="-v${LOGCONSOLE}:${LOGLVLERR}"
LOGDEFAULT=${SYSLOGINFO}

# Required directories
PASSWDDIR=$SNAP_DATA/var/run/ops-passwd-srv
CFGDIR=$SNAP_DATA/etc/openswitch

# Override the default install_path and data_path in OpenSwitch
export OPENSWITCH_INSTALL_PATH=$SNAP
export OPENSWITCH_DATA_PATH=$SNAP_DATA
export PATH=/snap/openswitch-appliance/x1/sbin:/snap/openswitch-appliance/x1/usr/sbin:$PATH
