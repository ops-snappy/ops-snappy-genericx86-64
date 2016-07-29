#!/bin/bash
#
# Setup a machine to use a snap. Make sure all files are
# updated properly, interfaces are defined correctly, etc.

#
errorCount=0

check_eth0()
{
    ifconfig -a | grep eth0 > /dev/null 2>&1
    if [ $? -ne 0 ]; then
	echo "ERROR: You are missing eth0! Your grub file may not be setup right"
    fi
}

check_network_devices()
{
    # eth0 - eth3. These need to be defined.
    errors=0
    for i in {0..3}; do
	ifconfig eth$i > /dev/null 2>&1
	if [ $? -ne 0 ]; then
	    echo "ERROR: Missing network interface - eth$i"
	    errors=`expr $errors + 1`
	fi
    done
    if [ $errors -eq 0 ]; then
	echo "OK: All required network devices are present."
    else
	echo "ERROR: 1 or more mandatory network devices are missing "
    fi
    # eth4 - eth7. These are optional
    warnings=0
    for i in {4..7}; do
	ifconfig eth$i > /dev/null 2>&1
	if [ $? -ne 0 ]; then
	    echo "WARNING: Missing network interface - eth$i"
	    warnings=`expr $warnings + 1`
	fi
    done
    if [ $warnings -eq 0 ]; then
	echo "OK: All optional network devices are present."
    else
	echo "WARNING: 1 or more optional network devices are missing "
    fi
}

check_grub()
{
    grep GRUB_CMDLINE_LINUX= /etc/default/grub | grep net.ifnames > /dev/null 2>&1
    if [ $? -ne 0 ]; then
	echo "ERROR: Your /etc/default/grub file needs updating"
	echo "   Please edit /etc/default/grub and add this line:"
	echo '      GRUB_CMDLINE_LINUX=“net.ifnames=0 biosdevname=0”'
	echo "   Then, run this command: update-grub, then reboot";
    else
	echo "OK: Your /etc/default/grub file is updated correctly"
    fi
    

}

check_snap()
{
    snap list | grep openswitch-appliance > /dev/null 2>&1
    if [ $? -ne 0 ]; then
	echo "Error: The openswitch-appliance snap is not installed!"
	return
    else
	echo "OK: The openswitch-appliance snap is installed"
    fi

    # Make sure it's installed in devmode
    snap list | grep openswitch-appliance | grep devmode > /dev/null 2>&1
    if [ $? -ne 0 ]; then
	echo "Error: The openswitch-appliance snap is not installed in devmode!"
	return
    else
	echo "OK: The openswitch-appliance snap is installed in devmode"
    fi
}

check_interfaces()
{
    errors=0
    for i in :gsettings :network :network-bind :network-control :network-manager :network-observe :firewall-control; do
	snap interfaces | grep $i\ | grep openswitch-appliance > /dev/null 2>&1
	if [ $? -ne 0 ]; then
	    echo "ERROR: Missing interface: $i.  Fix using: "
            echo "   snap connect openswitch-appliance$i ubuntu-core$i"
	    errors=`expr $errors + 1`
	fi
    done
    if [ $errors -eq 0 ]; then
	echo "OK: All snap interfaces are in place"
    fi
}

check_global_package()
{
    installed=$(dpkg -l $1) 
    if [[ -z $installed ]] ; then
        echo "ERROR: Missing system package: fix using 'sudo apt install $1'"
	errors=`expr $errors + 1`
    else
        echo "OK: package '$1' is installed."
    fi
}

check_firewall()
{
    ufw status  | grep inactive > /dev/null 2>&1
    
    if [ $? -ne 0 ]; then
        echo "OK: The firewall is enabled."
    else
	echo "ERROR: You need to enable the firewall: fix using 'sudo ufw enable'"
    fi
}

check_kernel_modules()
{
    lsmod | grep openvswitch > /dev/null 2>&1

    if [ $? -ne 0 ]; then
	echo "ERROR: Your /etc/modules file needs updating"
	echo "   Please edit /etc/modules and add this line:"
	echo '      openvswitch'
	echo "   Then reboot";
    else
        echo "OK: The openvswitch kernel object is loaded."
    fi
}

check_grub
check_eth0
check_network_devices
check_snap
check_interfaces
check_global_package ntp
check_global_package libpam-radius-auth
check_firewall
check_kernel_modules
