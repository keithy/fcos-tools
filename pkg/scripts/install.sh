PKG="$1"

set -a
sudo ${PKG}/core-tool/core self-install /usr/local/bin --link --confirm

sudo rm -f /usr/local/bin/layer-shell
sudo ln -s "${PKG}/core-tool/sub-commands/layer-shell.sh" /usr/local/bin/layer-shell



