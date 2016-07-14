# Simple makefile for building and cleaning snaps. Whenever special steps are needed
# (or strongly suggested), please update this Makefile as required.

snap:
	snapcraft

clean:
	snapcraft clean
	rm -rf parts/openswitch
	rm -rf parts/ops-init
	rm -f *.snap
