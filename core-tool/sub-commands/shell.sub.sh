$DEBUG && echo "${dim}${BASH_SOURCE}${reset}"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

command="shell"
description="start a psuedo-root shell in a LAYER"
usage="usage:
$breadcrumbs shell"

$SHOWHELP && executeHelp
$METADATAONLY && return

$LOUD && echo testing mantle-shell
$LOUD && echo "USER: $USER HOME: $HOME ScriptDir: $scriptDir"

temp_file=$(mktemp -p "$DIR")
trap "rm -f $temp_file" EXIT SIGINT SIGQUIT SIGKILL SIGTERM

# For debugging purposes this allows us to write scripts with extra comments 
# in multi-line bash statements
grep -v ^# "$scriptDir/layer-shell.sh" > $temp_file
 
source $temp_file
 