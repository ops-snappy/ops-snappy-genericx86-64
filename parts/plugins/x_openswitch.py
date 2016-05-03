import snapcraft
import snapcraft.common
import os
import logging
import shutil

logger = logging.getLogger(__name__)

class XOpenSwitchPlugin(snapcraft.BasePlugin):
    @classmethod
    def schema(cls):
        schema = super().schema()
        schema['properties']['platform'] = {
            'type': 'string',
            'default': 'as6712',
        }
        return schema

    def __init__(self, name, options, project):
        super().__init__(name, options, project)
        logger.info('__init__ override...')
        self.build_packages.append('make')

    def clean_pull(self):
        logger.info('clean_pull override NOP')
        """ Don't clean the source dir for now since we are pre-building.
        """

    def build(self):

        command = ['make']

        """ Since we are pre-building, builddir simply links to sourcedir
        """
        if os.path.exists(self.build_basedir):
            if not os.path.islink(self.build_basedir):
                logger.info('build override link ' + self.build_basedir + ' ==> ' + self.sourcedir)
                shutil.rmtree(self.build_basedir)
                os.symlink(self.sourcedir, self.build_basedir)

        """ Since we are pre-building, just have to install into installdir
        """
        logger.info('build override make install DESTDIR=' + self.build_basedir)
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
            logger.info('rmtree ' + self.installdir)
            shutil.rmtree(self.installdir)
