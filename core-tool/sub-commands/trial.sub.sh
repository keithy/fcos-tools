#!/usr/bin/env bash 
$DEBUG && echo "${dim}${BASH_SOURCE}${reset}"

RELEASEVER=$(grep -e '^VERSION_ID=.*' /etc/os-release | cut -d '=' -f2)

command="trial"
description="testing out layered chrooted environments"
usage="Demonstration of support for some systemd directives.
- Basically this demonstrates a systemd \"portable\" with a \"default\" profile.
- It runs directly from the command-line (without portablectl tooling etc.)

You will be presented with a shell that can be used to run: curl agnus.defensec.nl

$breadcrumbs --new                            # start afresh
$breadcrumbs --clobber                        # delete all files
$breadcrumbs --build <pkg1> [<pkg2>...]       # build packages
$breadcrumbs --clean       					  # clean up after build
$breadcrumbs --run                            # run environment  
$breadcrumbs --name=<name>                    # named (default 'example')
$breadcrumbs --releasever=${RELEASEVER}                  # (default ${RELEASEVER})  
$breadcrumbs --dest=<dir>                     # (default '/root') 
$breadcrumbs --help                           # this message"

$SHOWHELP && executeHelp 
$METADATAONLY && return

$DEBUG && echo "Command: '$command'"

SHOWHELP=true
MAKE_NEW=false
ENV_NAME="example"
CLOBBER=false
DNF_BUILD=false
DNF_CLEAN=false
SYSTEMD_RUN=false
DEST_DIR="/root"
PKG_LIST=()

### Options and Parameters
#
for arg in "$@"
do
    case "$arg" in
        --new)
            MAKE_NEW=true
            CLOBBER=true
            SHOWHELP=false
        ;;
        --name=*)
            ENV_NAME="${arg##--name=}"
        ;;
        --clobber)
            CLOBBER=true
            SHOWHELP=false
        ;;
        --build)
            DNF_BUILD=true
            SHOWHELP=false
        ;;
        --run)
            SYSTEMD_RUN=true
            SHOWHELP=false
        ;;
        --releasever=*)
            RELEASEVER="${arg##--releasever=}"
        ;;
        --dest=*)
            DEST_DIR="${arg##--dest=}"
            [[ "$DEST_DIR" =~ (^/$|\.\.|^/[^/]+$|^/bin/|^/lib/) ]] \
                && echo "Greater love hath no script... I died to save you!" && exit 1
        ;;
        -*)
        # ignore other options
        ;; 
        ?*)
        	PKG_LIST+=("$arg")
        ;;
    esac
done

### Pre-requisites
#
[[ ! $UID == 0 ]] || [[ ! `secon -r` == 'unconfined_r' ]] 	&& echo "needs root/sysadm.role" 	&& exit 1
[[ ! -e /usr/bin/systemd-run ]] 							&& echo "need /usr/bin/systemd-run" && exit 1

_need()
{
   [[ ! -e "$1" ]] && echo "need $1" && exit 1 || return 0
}

if $CLOBBER
then
    $LOUD && echo "Clobbering $DEST_DIR/$ENV_NAME"
	if [[ -e "$DEST_DIR/$ENV_NAME" ]]; then
	    \rm -rf "$DEST_DIR/$ENV_NAME" 
    	\rm -f "/var/lib/${ENV_NAME}" || true
    	\rm -rf "/var/lib/private/$ENV_NAME"
    fi
fi

if $MAKE_NEW
then
    $LOUD && echo "Making new $DEST_DIR/$ENV_NAME"
    [[ -d "$DEST_DIR/$ENV_NAME" ]]          && echo "$DEST_DIR/$ENV_NAME should not exist"          && exit 1
    [[ -e "/var/lib/${ENV_NAME}"  ]]        && echo "/var/lib/${ENV_NAME} should not exist"         && exit 1
	[[ -e "/var/lib/private/${ENV_NAME}" ]] && echo "/var/lib/private/${ENV_NAME} should not exist" && exit 1

	retval=1

	mkdir -p "$DEST_DIR/$ENV_NAME/etc"            && \
    touch "$DEST_DIR/$ENV_NAME/etc/machine-id"    && \
    touch "$DEST_DIR/$ENV_NAME/etc/resolv.conf"   && \
    mkdir -p "$DEST_DIR/$ENV_NAME/var/lib/example"
   
    retval=$?

    if [[ ! $retval == 0 ]]
    then
        echo '"bind read-only paths" mountpoint creation failed'
        exit 1
    fi
fi

if $DNF_BUILD
then
    _need "/usr/bin/dnf"    
    $LOUD && echo "Making new $DEST_DIR/$ENV_NAME"

    retval=1
    
    touch "$DEST_DIR/$ENV_NAME/etc/machine-id"    && \
    touch "$DEST_DIR/$ENV_NAME/etc/resolv.conf"   && \
    mkdir "$DEST_DIR/$ENV_NAME/etc"               && \
    mkdir "$DEST_DIR/$ENV_NAME/var/lib/example"
	retval=$?
 
	echo /usr/bin/dnf -y "--releasever=$RELEASEVER" "--installroot=$DEST_DIR/$ENV_NAME"

    retval=1
    /usr/bin/dnf -y "--releasever=$RELEASEVER" "--installroot=$DEST_DIR/$ENV_NAME" \
                 --disablerepo='*' --enablerepo=fedora --enablerepo=updates \
                 --setopt=install_weak_deps=0 --setopt=tsflags=nocontexts \
                 --nodocs install glibc-langpack-en ${PKG_LIST[*]} --nogpgcheck

    retval=$?

    if [[ ! $retval == 0 ]]
    then
        echo '"dnf install ${PKG_LIST[*]}" failed (use --clobber to clear up)'
        exit 1
    fi
fi

if $DNF_CLEAN
then
    retval=1

    dnf -y "--releasever=$RELEASEVER" "--installroot=$DEST_DIR/$ENV_NAME" clean all

    retval=$?

    if [[ ! $retval == 0 ]]
    then
        echo '"dnf clean all" failed (use --clobber to clear up)'
        exit 1
    fi
fi

if $SYSTEMD_RUN
then

  if [[ ! -e "$DEST_DIR/$ENV_NAME" ]]
  then
		echo "${bold}${DEST_DIR}/${ENV_NAME}${reset} does not exist"
		echo
		executeHelp 
		exit 1
  fi

  systemd-run \
    -p Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    -p Environment=HOME=/var/lib/example \
    -p RootDirectory=/root/example \
    -p MountAPIVFS=yes \
    -p TemporaryFileSystem=/run \
    -p BindReadOnlyPaths='/run/systemd/notify /dev/log /run/systemd/journal/socket /run/systemd/journal/stdout /etc/machine-id /etc/resolv.conf /run/dbus/system_bus_socket' \
    -p RemoveIPC=yes \
    -p RuntimeDirectory=example \
    -p StateDirectory=example \
    -p PrivateTmp=yes \
    -p PrivateUsers=yes \
    -p ProtectHome=yes \
    -p ProtectKernelTunables=yes \
    -p ProtectKernelModules=yes \
    -p ProtectControlGroups=yes \
    -p ProtectHostname=yes \
    -p LockPersonality=yes \
    -p RestrictRealtime=yes \
    -p ProtectSystem=strict \
    -p SystemCallArchitectures=native \
    -p SystemCallErrorNumber=EPERM \
    -p MemoryDenyWriteExecute=yes \
    -p RestrictNamespaces=yes \
    -p PrivateDevices=yes \
    -p User=example \
    -p DynamicUser=yes \
    -p CapabilityBoundingSet='CAP_CHOWN CAP_DAC_OVERRIDE CAP_DAC_READ_SEARCH CAP_FOWNER CAP_FSETID CAP_IPC_LOCK CAP_IPC_OWNER CAP_KILL CAP_MKNOD CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_BROADCAST CAP_SETGID CAP_SETPCAP CAP_SETUID CAP_SYS_ADMIN CAP_SYS_CHROOT CAP_SYS_NICE CAP_SYS_RESOURCE' \
    -p RestrictAddressFamilies='AF_UNIX AF_NETLINK AF_INET AF_INET6' \
    -t /bin/bash
#     -p IPAccounting=yes \
#     -p IPAddressDeny=any \
#     -p IPAddressAllow=2001:985:d55d::711 \
#     -p IPAddressAllow=80.100.19.56 \
#     -p IPAddressAllow=${_DNS1} \
#     -p IPAddressAllow=${_DNS2} \
#     -p IPAddressAllow=127.0.0.0/8 \
#     -p MemoryHigh=10M \
#     -p MemoryMax=15M \
#     -p CPUQuota=20% \
#     -p TasksMax=10 \
#     -p SELinuxContext='sys.id:sys.role:example.subj:s0' \

    
    exit 0
fi

if $SHOWHELP; then
	executeHelp
	echo
	echo "${bold}No Action Given${reset}"
fi
	exit 0
fi
