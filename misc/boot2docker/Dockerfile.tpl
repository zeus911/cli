# using VirtualBox version $VBOX_VERSION

FROM boot2docker/boot2docker

RUN apt-get install p7zip-full

RUN mkdir -p /vboxguest && \
    cd /vboxguest && \
    curl -L -o vboxguest.iso http://download.virtualbox.org/virtualbox/$VBOX_VERSION/VBoxGuestAdditions_$VBOX_VERSION.iso && \
    7z x vboxguest.iso -ir'!VBoxLinuxAdditions.run' && \
    sh VBoxLinuxAdditions.run --noexec --target . && \
    mkdir x86 && cd x86 && tar xvjf ../VBoxGuestAdditions-x86.tar.bz2 && cd .. && \
    mkdir amd64 && cd amd64 && tar xvjf ../VBoxGuestAdditions-amd64.tar.bz2 && cd .. && \
    cd amd64/src/vboxguest-$VBOX_VERSION && KERN_DIR=/linux-kernel/ make && cd ../../.. && \
    cp amd64/src/vboxguest-$VBOX_VERSION/*.ko $ROOTFS/lib/modules/$KERNEL_VERSION-tinycore64 && \
    mkdir -p $ROOTFS/sbin && cp x86/lib/VBoxGuestAdditions/mount.vboxsf $ROOTFS/sbin/

RUN echo "" >> $ROOTFS/etc/motd; \
    echo "  boot2docker with VirtualBox guest additions version $VBOX_VERSION" >> $ROOTFS/etc/motd; \
    echo "" >> $ROOTFS/etc/motd

# make mount permanent
RUN echo '#!/bin/sh' >> $ROOTFS/etc/rc.d/vbox-guest-additions-permanent-mount; \
    echo 'sudo modprobe vboxsf && sudo mkdir -p /mnt/host && sudo chown docker:staff /mnt/host && sudo mount.vboxsf -o umask=0022,gid=$(id -g docker),uid=$(id -u docker) visops_root /mnt/host && sudo mkdir -p /var/lib/docker/containers && sudo mount.vboxsf -o umask=0022,gid=$(id -g docker),uid=$(id -u docker) visops_containers /var/lib/docker/containers' >> $ROOTFS/etc/rc.d/vbox-guest-additions-permanent-mount
RUN chmod +x $ROOTFS/etc/rc.d/vbox-guest-additions-permanent-mount
RUN echo '/etc/rc.d/vbox-guest-additions-permanent-mount' >> $ROOTFS/opt/bootsync.sh

RUN depmod -a -b $ROOTFS $KERNEL_VERSION-tinycore64
RUN /make_iso.sh
CMD ["cat", "boot2docker.iso"]
