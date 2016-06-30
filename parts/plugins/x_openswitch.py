import snapcraft
import os
import re
import glob
import logging
import shutil
import subprocess

from snapcraft.internal import common, sources

logger = logging.getLogger(__name__)

class XOpenSwitchPlugin(snapcraft.BasePlugin):
    @classmethod
    def schema(cls):
        schema = super().schema()
        schema['properties']['platform'] = {
            'type': 'string',
        }
        schema['properties']['linuxheaders'] = {
            'type': 'string',
        }
        schema['properties']['cdppart'] = {
            'type': 'string',
        }
        schema['required'].append('platform')
        schema['pull-properties'].extend(
            ['cdppart'])
        return schema

    def __init__(self, name, options, project):
        super().__init__(name, options, project)

        self.build_packages.extend(['make', 'patchelf'])

        if self.options.cdppart:
            self.cdpdir = os.path.join(project.parts_dir, self.options.cdppart + '/build')
            if self.options.linuxheaders:
                self.headersdir = self.options.linuxheaders
            else:
                raise ValueError('CDP requires linuxheaders')
        else:
            self.cdpdir = None
            self.headersdir = None

    """ Debugging information requires special handling for snappy.  The
    debug info files (symbols, source paths, etc) need to be located in
    the executable path rather than in a fixed global debug info dir.
    This is because gdb uses the executable path to build the path to
    the debug info.  Since the executable path is not determined until
    installation, we can't anticipate the proper location for the debug
    information in the global debug dir ahead of time.  The easiest
    solution is to locate the debug information relative to the
    execution path where gdb automatically searches.
    """
    def _relocate_debug_info(self,debug_info):
        if not os.path.exists(debug_info):
            return
        for root, dirs, files in os.walk(debug_info):
            for dname in dirs:
                dsrc = os.path.join(root, dname)
                ddst = os.path.join(dsrc.replace('/usr/lib/debug', '', 1), '.debug')
                if not os.path.exists(ddst):
                    os.makedirs(ddst)
                for fname in glob.glob(os.path.join(dsrc, '*.debug')):
                    shutil.copy2(fname, ddst)
        shutil.rmtree(debug_info)

    def _set_interpreter(self, new_interpreter):
        pattern = re.compile(".*ELF.*interpreter /lib/ld-linux-x86-64\.so\.2.*")
        for root, dirs, files in os.walk(self.installdir):
            for fname in files:
                """ Don't mess with debug info files.  They look like
                    executables, but they contain debug info extracted
                    from the actual executable.  These are checksummed,
                    so changing the contents breaks debugging.
                """
                if fname.endswith('.debug'):
                    continue
                path = os.path.join(root, fname)
                if os.access(path, os.X_OK):
                    fout = subprocess.check_output(['file', path]).decode("utf-8")
                    if pattern.match(fout):
                        self.run(['patchelf', '--set-interpreter', new_interpreter, path])

    def build(self):

        command = ['make']

        """ Since we are pre-building, builddir simply links to sourcedir
        """
        if os.path.exists(self.build_basedir):
            if not os.path.islink(self.build_basedir):
                logger.info('build override link ' + self.build_basedir + ' ==> ' + self.sourcedir)
                shutil.rmtree(self.build_basedir)
                os.symlink(self.sourcedir, self.build_basedir)

        """Make sure the pre-built image was configured as expected.
        """
        with open(os.path.join(self.sourcedir, '.platform'), 'r') as platformfile:
            configuredplatform = platformfile.read().replace('\n','');
        if self.options.platform != configuredplatform:
            raise ValueError('Source is configured for ' + configuredplatform + '; expected ' + self.options.platform)

        """Must rebuild the opennsl for the target system
        """
        if self.cdpdir != None:
                self.run(['make', 'host-opennsl', 'CDPDIR=' + self.cdpdir, 'LINUX_SRC=' + self.headersdir, 'LINUX_KBUILD=' + self.headersdir])

        """ Since we are pre-building, just have to install into installdir
        """
        if self.cdpdir != None:
            self.run(command + ['install-snappy', 'DESTDIR=' + self.installdir, 'CDPDIR=' + self.cdpdir])
        else:
            self.run(command + ['install-snappy', 'DESTDIR=' + self.installdir])

        """ The OpenSwitch/OpenEmbedded/BitBake toolchain sets the interpreter on
            executables to /lib/ld-linux-x86-64.so.2.  Ubuntu-core locates the
            interpreter at /lib64/ld-linux-x86-64.so.2.  So, change all executables'
            interpreter location to /lib64/ld-linux-x86-64.so.2.
        """
        self._set_interpreter('/lib64/ld-linux-x86-64.so.2');

        """ Reorganize debug info to make it snappy-friendly
        """
        self._relocate_debug_info(self.installdir + '/usr/lib/debug')

    def clean_build(self):

        """ Since we are pre-building, just unlink build_basedir
        """
        if os.path.islink(self.build_basedir):
            logger.info('unlink ' + self.build_basedir)
            os.remove(self.build_basedir)
        if os.path.exists(self.build_basedir):
            shutil.rmtree(self.build_basedir)

        if os.path.exists(self.installdir):
            shutil.rmtree(self.installdir)
