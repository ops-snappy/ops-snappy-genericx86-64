#!/bin/bash

# Slow down startup so can see what's happening easier
STARTDELAY=2

# Setup OpenSwitch environment variables
source $SNAP/usr/sbin/openswitch-env

# Make sure the directories exist
for i in $DBDIR $VTEPDBDIR $PIDDIR $CTLDIR $CFGDIR ; do
    /usr/bin/test -d $i || mkdir -p $i
done

# Create the network namespaces
$SBINDIR/ops-init

# Create the databases if they don't exist.
/usr/bin/test -f $DBDIR/ovsdb.db || $BINDIR/ovsdb-tool create $DBDIR/ovsdb.db $SCHEMADIR/vswitch.ovsschema
/usr/bin/test -f $VTEPDBDIR/vtep.db || $BINDIR/ovsdb-tool create $VTEPDBDIR/vtep.db $SCHEMADIR/vtep.ovsschema
/usr/bin/test -f $DBDIR/dhcp_leases.db || $BINDIR/ovsdb-tool create $DBDIR/dhcp_leases.db $SCHEMADIR/dhcp_leases.ovsschema
/usr/bin/test -f $DBDIR/config.db || $BINDIR/ovsdb-tool create $DBDIR/config.db $SCHEMADIR/configdb.ovsschema

# OVSDB Server
# TODO - By default, the unix control socket is located at
#        /var/run/openvswitch/<name>.<pid>.ctl.  Can't dynamically
#        assign the assign the pid if we are specifying a noncase 
#        location for the pid.
echo STARTING: $SBINDIR/ovsdb-server --remote=punix:$DBDIR/db.sock --detach --no-chdir --pidfile=$PIDDIR/ovsdb-server.pid --unixctl=$CTLDIR/ovsdb-server.ctl $LOGDEFAULT $DBDIR/ovsdb.db $DBDIR/config.db $DBDIR/dhcp_leases.db
$SBINDIR/ovsdb-server --remote=punix:$DBDIR/db.sock --detach --no-chdir --pidfile=$PIDDIR/ovsdb-server.pid --unixctl=$CTLDIR/ovsdb-server.ctl $LOGDEFAULT $DBDIR/ovsdb.db $DBDIR/config.db $DBDIR/dhcp_leases.db
if (( "$STARTDELAY" > "0" )) ; then
    sleep $STARTDELAY
fi

NOT_YET=""
OPENSWITCH_DAEMONS="ops-sysd ops-arpmgrd restd ops-intfd ops_cfgd ops_aaautilspamcfg ops-tempd ops-fand ops-powerd ops-pmd ops-ledd ops-vland ops-portd"
for i in $OPENSWITCH_DAEMONS ; do
    daemon_loc=$BINDIR
    daemon_args="--detach --no-chdir --pidfile=$PIDDIR/$i.pid"
    daemon_log=$LOGDEFAULT
    daemonize="no"
    case $i in
        ops_cfgd|ops_aaautilspamcfg)
            daemon_args="$daemon_args $daemon_log --database=$DBDIR/db.sock"
            ;;
        restd)
            daemon_args=""
            daemonize="yes"
            ;;
        *)  daemon_args="$daemon_args $daemon_log --unixctl=$CTLDIR/$i.ctl"
            ;;
    esac
    echo STARTING: $daemon_loc/$i $daemon_args
    if [ $daemonize="yes" ] ; then
        $daemon_loc/$i $daemon_args &
    else
        $daemon_loc/$i $daemon_args
    fi
    if (( "$STARTDELAY" > "0" )) ; then
        sleep $STARTDELAY
    fi
done
