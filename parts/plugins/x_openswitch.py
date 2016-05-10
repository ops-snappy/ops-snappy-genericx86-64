import snapcraft
import os
import glob
import logging
import shutil

from snapcraft.internal import common, sources

logger = logging.getLogger(__name__)

class XOpenSwitchPlugin(snapcraft.BasePlugin):
    @classmethod
    def schema(cls):
        schema = super().schema()
        schema['properties']['platform'] = {
            'type': 'string',
        }
        schema['properties']['headerspart'] = {
            'type': 'string',
        }
        schema['properties']['cdppart'] = {
            'type': 'string',
        }
        schema['required'].append('platform')
        return schema

    def __init__(self, name, options, project):
        super().__init__(name, options, project)

        """ With pre-built, make sure configured platform matches yaml file.
        """
        self.build_packages.append('make')

        if self.options.cdppart:
            self.cdpdir = os.path.join(project.parts_dir, self.options.cdppart)
            if self.options.headerspart:
                self.headersdir = os.path.join(project.parts_dir, self.options.headerspart)
                """ TODO - extract kernel version from headers part
                """
                self.kernelversion = '4.4.0-21-generic'
            else:
                raise ValueError('CDP requires headerspart')
        else:
            self.cdpdir = None
            self.headersdir = None
            self.kernelversion = None

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
            self.run(['make', 'host-opennsl', 'CDPDIR=' + self.cdpdir, 'LINUX_HEADERS=' + self.headersdir, 'KERNEL_VERSION=' + self.options.kernelversion])

        """ Since we are pre-building, just have to install into installdir
        """
        if self.cdpdir != None:
            self.run(command + ['install-snappy', 'DESTDIR=' + self.installdir, 'CDPDIR=' + self.cdpdir])
        else:
            self.run(command + ['install-snappy', 'DESTDIR=' + self.installdir])

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
