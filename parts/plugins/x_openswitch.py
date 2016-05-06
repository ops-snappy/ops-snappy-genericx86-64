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
        schema['properties']['kernelversion'] = {
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

        self.downloaddir = os.path.join(self.partdir, 'download')
        self.headersdir = os.path.join(self.downloaddir, 'linux-headers')
        if self.options.cdppart:
            self.cdpdir = os.path.join(project.parts_dir, self.options.cdppart)
            if self.options.kernelversion:
                self.downloaddir = os.path.join(self.partdir, 'download')
                self.headersdir = os.path.join(self.downloaddir, 'linux-headers')
            else:
                raise ValueError('CDP requires kernelversion')
        else:
            self.cdpdir = None
                

    def pull(self):
        super().pull()
        if self.cdpdir != None:
            if os.path.exists(self.downloaddir):
                shutil.rmtree(self.downloaddir)
            os.mkdir(self.downloaddir)
            os.mkdir(self.headersdir)
            self.run(['apt', 'download', 'linux-headers-' + self.options.kernelversion], cwd=self.downloaddir)
            debfiles = glob.glob(os.path.join(self.downloaddir, '*.deb'))
            self.run(['dpkg', '-x'] + debfiles + [self.headersdir])
            self.run(['rm', '-f'] + debfiles)

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
        if os.path.exists(self.downloaddir):
            shutil.rmtree(self.downloaddir)
