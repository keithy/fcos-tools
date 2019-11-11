# Scripts for working with Fedora CoreOS - "fcos"

A project for collating tools/scripts that can be deployed to CoreOS as
a single deliverable (via ignition).

#Included So Far

## Sensible 

Sensible (pun intended) is a self-deployment tool, configure a list of hosts and deploy/update
this tool (and the scripts within) directly to them. Sensible also supports remote execution capabilities.
 
## Layerbox

[Layerbox](https://gitlab.com/keithy/layerbox) is a reimagining of [toolbox](https://github.com/coreos/toolbox) to use chroot environments layered over the OS as
an alternative to toolbox (which uses containers via podman.)

## Toolbox Installer (interim)

The fcos installer is invoked automatically by `coreos-install-pkg.sh` (see below) 
Since toolbox has no self-installation capability "fcos" will use its own to 
install toolbox if it has been downloaded via ignition to the packages "inbox". 
Saving the need for a separate toolbox-installation unit.

## Groan

FCOS and LayerBox are constructed with [groan](https://github.com/keithy/groan) a framework for assembling scripts and tools in any languages
into a single hierarchical tool that may be deployed as a single deliverable.

# Deployment via Ignition

Add the following items to the `ignition.yaml` provisioning script.

Use ignition to download fcos tools into the packages "inbox"
```
    - path: /opt/inbox/package/core/fcos-tools_v0.1.tar.gz
      mode: 0644
      contents:
        source: https://gitlab.com/keithy/fcos-tools/-/archive/master/fcos-tools-master.tar.gz
```
The following Unit processes the "inbox" using a universal installation script 
```
    - name: install-pkgs.service
      enabled: true
      contents: |
        [Unit]
        Description=Install Packages & Attach Portable Services
        ConditionFirstBoot=yes
        After=multi-user.target
        Before=boot-complete.target
        [Service]
        Type=oneshot
        ExecStartPre=setenforce Permissive
        ExecStart=-find /opt/inbox -mindepth 3 -maxdepth 3 -name "*.tar.[xg]z" -exec sh /usr/libexec/coreos-install-pkg.sh {} \;
        [Install]
        WantedBy=multi-user.target
        RequiredBy=boot-complete.target    
```
This universal installer script is for packages and portable services
```
    - path: /usr/libexec/coreos-install-pkg.sh
      mode: 0755
      user:
        id: 0
      group:
        id: 0
      contents:
        inline: |
          set -a
          PACKAGES="/usr/local/lib"
          TAR_PATH="$1"
          IFS=/ read -r a b c PROFILE USER ARCHIVE <<< "$TAR_PATH"
          PKG="${ARCHIVE%.tar.[xg]z}"
          PKG_NAME=${PKG%_*}
          mkdir -p "$PACKAGES/$PKG"
          tar xvzf "$TAR_PATH" --strip-components 1 -C $PACKAGES/$PKG && \
            ln -s "$PACKAGES/$PKG" "$PACKAGES/$PKG_NAME"
          INSTALL_SH="$PACKAGES/$PKG/pkg/scripts/install.sh"
          [[ -e "$INSTALL_SH" ]] && su -m "$USER" "$INSTALL_SH" "$PACKAGES/$PKG_NAME" || true
          METADATA="$PACKAGES/$PKG/pkg/pkg-release"
          portablectl attach --no-reload --copy=symlink "--profile=$PROFILE" "$PACKAGES/$PKG" && \
            systemctl enable $(grep "^UNITS_ENABLE=" "$METADATA" | cut -d '=' -f2) && \
            systemctl start $(grep "^UNITS_START=" "$METADATA" | cut -d '=' -f2) || true
          echo "Finished installing $PACKAGES/$PKG"        
```

