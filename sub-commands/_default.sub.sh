# groan test.sh
#
# by Keith Hodges 2010
#
# A Dummy

$DEBUG && echo "${dim}${BASH_SOURCE}${reset}"

command="status"
description="fcos info"
usage="usage:
$breadcrumbs info"

$SHOWHELP && executeHelp
$METADATAONLY && return

echo "This is a placeholder"

exit 0

#"This Code is distributed subject to the MIT License, as in http://www.opensource.org/licenses/mit-license.php . 
#Any additional contribution submitted for incorporation into or for distribution with this file shall be presumed subject to the same license."