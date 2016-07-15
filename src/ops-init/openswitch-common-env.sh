#!/bin/bash

#
# Openswitch Common Environment Settings
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
LOGDEFAULT=${SYSLOGINFO}

# Required directories
PASSWDDIR=$SNAP_DATA/var/run/ops-passwd-srv
CFGDIR=$SNAP_DATA/etc/openswitch

# Override the default install_path and data_path in OpenSwitch
export OPENSWITCH_INSTALL_PATH=$SNAP
export OPENSWITCH_DATA_PATH=$SNAP_DATA
