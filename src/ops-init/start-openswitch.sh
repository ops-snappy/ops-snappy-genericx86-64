#!/bin/bash

# Slow down startup so can see what's happening easier
STARTDELAY=0

# Setup OpenSwitch environment variables
source $SNAP/usr/sbin/openswitch-env

# Setup netop and opsadmin users
if [ -e /var/lib/extrausers ] ; then
    EXTRA=--extrausers
fi
addgroup $EXTRA ops_admin > /dev/null 2>&1 || true
addgroup $EXTRA ops_netop > /dev/null 2>&1 || true
addgroup $EXTRA ovsdb-client > /dev/null 2>&1 || true
useradd $EXTRA -m -G -p '$6$JYV2DfTJ$djhTyj2L/VqWjQR2T15s/ndfS0jQl0N/.OtFUUtT0/oQOwmIJqJyVgWMflB71aH9mWZ.Tdbjud/FCycBSA3Vk0' netop > /dev/null 2>&1 || true
useradd $EXTRA -m -p '$6$KbOFlyzh$DdxoPRI4a41GfKxJpXIZoOuuSv7wamj2qkZw8Z/R18hhDpF5NBEHzykP819/1DnjZkbxaSYMyuvAzVb/OjRYt/' opsadmin > /dev/null 2>&1 || true
adduser $EXTRA netop ops_netop > /dev/null 2>&1 || true
adduser $EXTRA netop ovsdb-client > /dev/null 2>&1 || true
adduser $EXTRA opsadmin ops_admin > /dev/null 2>&1 || true
adduser $EXTRA opsadmin ops_netop > /dev/null 2>&1 || true
adduser $EXTRA opsadmin ovsdb-client > /dev/null 2>&1 || true

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

#
# Appliance
#
if [ -f $OPTSBINDIR/ovsdb-server ] ; then
    /usr/bin/test -d $SIMDBDIR || mkdir -p $SIMDBDIR
    /usr/bin/test -f $SIMDBDIR/ovsdb.db || $BINDIR/ovsdb-tool create $SIMDBDIR/ovsdb.db $OPTSCHEMADIR/vswitch.ovsschema
    /usr/bin/test -f $SIMDBDIR/vtep.db || $BINDIR/ovsdb-tool create $SIMDBDIR/vtep.db $OPTSCHEMADIR/vtep.ovsschema
    echo STARTING: $OPTSBINDIR/ovsdb-server --remote=punix:$SIMDBDIR/db.sock --detach --no-chdir --pidfile=$PIDDIR/ovsdb-server-sim.pid --unixctl=$CTLDIR/ovsdb-server-sim.ctl $LOGDEFAULT $SIMDBDIR/ovsdb.db $SIMDBDIR/vtep.db
    cd $SIMDBDIR && $OPTSBINDIR/ovsdb-server --remote=punix:$SIMDBDIR/db.sock --detach --no-chdir --pidfile=$PIDDIR/ovsdb-server-sim.pid --unixctl=$CTLDIR/ovsdb-server-sim.ctl $LOGDEFAULT $SIMDBDIR/ovsdb.db $SIMDBDIR/vtep.db
    if (( "$STARTDELAY" > "0" )) ; then
        sleep $STARTDELAY
    fi
fi
if [ -f $OPTSBINDIR/ovs-vswitchd-sim ] ; then
    SWITCH_DAEMONS="ovs-vswitchd-sim ops-switchd"
else
    SWITCH_DAEMONS="ops-switchd bufmond"
fi

# Start the NTP server
# echo STARTING: NTP client daemon...
# ntp &

NOT_YET=""
OPENSWITCH_DAEMONS="ops-sysd ops_cfgd ops-passwd-srv $SWITCH_DAEMONS ops-classifierd ops-fand ops-intfd ops-lacpd ops-ledd ops_mgmtintfcfg ops-pmd ops-powerd ops-tempd ops-portd ops-vland ops-stpd ops_aaautilspamcfg ops-udpfwd restd ops-arpmgrd ops_ntpd ops-lldpd ops-bgpd ops-ospfd ops-zebra"
for i in $OPENSWITCH_DAEMONS ; do
    daemon_loc=$BINDIR
    daemon_args="--detach --no-chdir --pidfile=$PIDDIR/$i.pid"
    daemon_log=$LOGDEFAULT
    daemonize="no"
    working_dir=$DBDIR
    case $i in
        ops_cfgd|ops_aaautilspamcfg|ops_ntpd)
            daemon_args="$daemon_args $daemon_log --database=$DBDIR/db.sock"
            ;;
        restd)
            daemon_args=""
            daemonize="yes"
            ;;
        ops-switchd)
            daemon_args="$daemon_args $daemon_log --unixctl=$CTLDIR/$i.ctl"
            daemon_loc=$SBINDIR
            ;;
        ovs-vswitchd-sim)
            daemon_loc=$OPTSBINDIR
            working_dir=$SIMDBDIR
            ;;
        ops_mgmtintfcfg)
            daemon_args="--detach --pidfile=$PIDDIR/$i.pid $daemon_log"
            ;;
        ops-lldpd|ops-bgpd|ops-ospfd|ops-zebra)
            daemon_loc=$SBINDIR
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
