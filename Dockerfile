# vim:ft=dockerfile
ARG OS_RELEASE=7
FROM centos:${OS_RELEASE}
LABEL maintainer="DevOps <ops@bevc.net>"

ARG USR=builder
ARG UID=1001
ARG GID=1001

#COPY ./packaging/*.pem /etc/pki/ca-trust/source/anchors/
#RUN update-ca-trust extract
#COPY ./packaging/*.repo /etc/yum.repos.d/

RUN yum install -y \
    gcc gcc-c++ \
    libtool libtool-ltdl zlib-devel \
    make cmake \
    epel-release \
    git \
    pkgconfig \
    sudo \
    automake autoconf \
    yum-utils rpm-build rpmdevtools
RUN yum install -y \
    curl \
    && yum clean all

RUN groupadd -g $GID $USR
RUN useradd $USR -u $UID -m -g $USR -G users,wheel && \
    echo "$USR ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    echo "# macros"                      >  /home/$USR/.rpmmacros && \
    echo "%_topdir    /home/$USR/rpm"    >> /home/$USR/.rpmmacros && \
    echo "%_sourcedir %{_topdir}"        >> /home/$USR/.rpmmacros && \
    echo "%_builddir  %{_topdir}"        >> /home/$USR/.rpmmacros && \
    echo "%_specdir   %{_topdir}"        >> /home/$USR/.rpmmacros && \
    echo "%_rpmdir    %{_topdir}/pkg"    >> /home/$USR/.rpmmacros && \
    echo "%_srcrpmdir %{_topdir}"        >> /home/$USR/.rpmmacros && \
    echo "%debug_package %{nil}"         >> /home/$USR/.rpmmacros && \
    echo "%_build_name_fmt %%{NAME}-%%{VERSION}-%%{RELEASE}.%%{ARCH}.rpm" >> /home/$USR/.rpmmacros && \
    mkdir -p /home/$USR/rpm/pkg && \
    chown -R $USR /home/$USR

COPY ./packaging/*.sh /usr/local/bin/
RUN chmod 0755 /usr/local/bin/docker-*.sh

#USER $USR
WORKDIR /src
ENV FLAVOR=rpmbuild DIST=el7
ENTRYPOINT ["/usr/local/bin/docker-init.sh"]
#CMD ["/usr/local/bin/docker-init.sh"]
