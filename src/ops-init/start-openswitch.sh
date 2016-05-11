#!/bin/bash

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
DBDIR=$SNAP_DATA/var/run/openvswitch
LOGDIR=$SNAP_DATA/var/log/openvswitch
VTEPDBDIR=$SNAP_DATA/var/local/openvswitch
PIDDIR=$DBDIR
CTLDIR=$PIDDIR
BINDIR=$SNAP/usr/bin
SBINDIR=$SNAP/usr/sbin
SCHEMADIR=$SNAP/usr/share/openvswitch
CFGDIR=$SNAP_DATA/etc/openswitch

# Override the default dir locations in ops-openvswitch
export OVS_SYSCONFDIR=$SNAP/etc
echo  OVS_SYSCONFDIR=$SNAP/etc
export OVS_PKGDATADIR=$SCHEMADIR
echo OVS_PKGDATADIR=$SCHEMADIR
export OVS_RUNDIR=$DBDIR
echo OVS_RUNDIR=$DBDIR
export OVS_LOGDIR=$LOGDIR
echo OVS_LOGDIR=$LOGDIR
export OVS_DBDIR=$DBDIR
echo OVS_DBDIR=$DBDIR

# Override the default install_path and data_path in OpenSwitch
export OPENSWITCH_INSTALL_PATH=$SNAP
export OPENSWITCH_DATA_PATH=$SNAP_DATA

# Make sure the directories exist
for i in $DBDIR $VTEPDBDIR $PIDDIR $CTLDIR $CFGDIR ; do
    /usr/bin/test -d $i || mkdir -p $i
done

# Create the network namespaces
$SBINDIR/ops-init

# Create the databases if they don't exist.
echo OUTDIR=$SNAP_DATA
echo STARTING $BINDIR/ovsdb-tool
echo ==========================================================
ls -l $BINDIR/ovsdb-tool
echo ==========================================================
echo file $BINDIR/ovsdb-tool
file $BINDIR/ovsdb-tool
echo ==========================================================
echo objdump -p $BINDIR/ovsdb-tool
objdump -p $BINDIR/ovsdb-tool
echo ==========================================================
echo ldd -v $BINDIR/ovsdb-tool
ldd -v $BINDIR/ovsdb-tool
echo ==========================================================
ls -l $SCHEMADIR/vswitch.ovsschema
ls -l $SCHEMADIR/vtep.ovsschema
ls -l $SCHEMADIR/dhcp_leases.ovsschema
ls -l $SCHEMADIR/configdb.ovsschema
echo ==========================================================
echo strace $BINDIR/ovsdb-tool create $DBDIR/ovsdb.db $SCHEMADIR/vswitch.ovsschema
strace -f -x -s 256 -o/home/ubuntu/strace.out $BINDIR/ovsdb-tool create $DBDIR/ovsdb.db $SCHEMADIR/vswitch.ovsschema
echo ==========================================================
/usr/bin/test -f $DBDIR/ovsdb.db || $BINDIR/ovsdb-tool create $DBDIR/ovsdb.db $SCHEMADIR/vswitch.ovsschema
/usr/bin/test -f $VTEPDBDIR/vtep.db || $BINDIR/ovsdb-tool create $VTEPDBDIR/vtep.db $SCHEMADIR/vtep.ovsschema
/usr/bin/test -f $DBDIR/dhcp_leases.db || $BINDIR/ovsdb-tool create $DBDIR/dhcp_leases.db $SCHEMADIR/dhcp_leases.ovsschema
/usr/bin/test -f $DBDIR/config.db || $BINDIR/ovsdb-tool create $DBDIR/config.db $SCHEMADIR/configdb.ovsschema

# OVSDB Server
# TODO - By default, the unix control socket is located at
#        /var/run/openvswitch/<name>.<pid>.ctl.  Can't dynamically
#        assign the assign the pid if we are specifying a noncase 
#        location for the pid.
$SBINDIR/ovsdb-server --remote=punix:$DBDIR/db.sock --detach --no-chdir --pidfile=$PIDDIR/ovsdb-server.pid --unixctl=$CTLDIR/ovsdb-server.ctl $LOGDEFAULT $DBDIR/ovsdb.db $DBDIR/config.db $DBDIR/dhcp_leases.db

NOT_YET="ops-arpmgrd ops-intfd"
OPENSWITCH_DAEMONS="ops-sysd ops_cfgd ops_aaautilspamcfg restd ops-tempd ops-fand ops-powerd ops-pmd ops-ledd ops-vland ops-portd"
for i in $OPENSWITCH_DAEMONS ; do
    daemon_loc=$BINDIR
    daemon_args="--detach --no-chdir --pidfile=$PIDDIR/$i.pid"
    daemon_log=$LOGDEFAULT
    case $i in
        ops_cfgd|ops_aaautilspamcfg)
            daemon_args="$daemon_args $daemon_log --database=$DBDIR/db.sock"
            ;;
        restd)
            daemon_args=""
            ;;
        *)  daemon_args="$daemon_args $daemon_log --unixctl=$CTLDIR/$i.ctl"
            ;;
    esac
    echo STARTING: $daemon_loc/$i $daemon_args
    $daemon_loc/$i $daemon_args
    sleep 1
done
