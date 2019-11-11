DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

DEBUG=${DEBUG:-false}
LOUD=${LOUD:-true}

#Derived from Directory Name
#
# P_ Pkg/Portable
#
P_PATH=$(dirname $(dirname ${DIR}))
P_NAME_AND_VERSION=${PORTABLE_PATH##*/}
P_NAME=${PORTABLE_NAME_AND_VERSION%_*}
P_VERSION=${PORTABLE_NAME_AND_VERSION##*_}}

#read metadata
source ${DIR}/../pkg-release


