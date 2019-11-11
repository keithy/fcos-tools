PKG="$1"

set -a

${PKG}/fcos self-install --link --confirm
${PKG}/fcos layer install-shell --confirm

# Install toolbox if it has been downloaded into the inbox but not installed
if [[ ! -e /usr/local/bin/toolbox]] && [[-e "$PKG"/../toolbox/toolbox ]]; then
 ln -s "$PKG"/../toolbox/toolbox /usr/local/bin/toolbox
fi
