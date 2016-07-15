SBIN:=$(DESTDIR)/usr/sbin

all:

install:
	install -d $(SBIN)
	install -m 755 openswitch-common-env.sh $(SBIN)/openswitch-common-env
	install -m 755 openswitch-env.sh $(SBIN)/openswitch-env
	install -m 755 openswitch-sim-env.sh $(SBIN)/openswitch-sim-env
	install -m 755 start-openswitch.sh $(SBIN)/start-openswitch
	install -m 755 stop-openswitch.sh $(SBIN)/stop-openswitch
	install -m 755 start-vtysh.sh $(SBIN)/start-vtysh
