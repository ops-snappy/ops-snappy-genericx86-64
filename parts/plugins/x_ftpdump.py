import os
import logging
import urllib.request
import snapcraft.sources
import snapcraft.plugins.dump

logger = logging.getLogger(__name__)

class XFtpDumpPlugin(snapcraft.plugins.dump.DumpPlugin):
    # Snapcraft standard 'pull' does not support FTP servers yet.
    # This plugin can go away once FTP support is added for source.
    # Reference:  gttps://bugs.launchpad.net/snapcraft/+bug/1602323
    def pull(self):
        if not self.options.source.startswith('ftp://'):
            logger.warn('Using super pull for ' +  self.options.source)
            super().pull()
        else:
            tarball = os.path.join(self.sourcedir, os.path.basename(self.options.source))
            urllib.request.urlretrieve(self.options.source, tarball)

        # The contents of the tarball have to end up in a platform-specific
        # directory of the form..
        # ./src/opennsl-<version>-cdp-<platform>
        tardir = os.path.join(self.sourcedir, os.path.basename(self.options.source).split('-amd64', 1)[0])
        if os.path.exists(tardir):
            shutil.rmtree(tardir)
        os.makedirs(tardir)
        snapcraft.sources.Tar(self.options.source, self.sourcedir).provision(tardir)
