FROM {{BASE_IMAGE}}
LABEL maintainer "{{MAINTAINER}}"

ENV PKG_PATH "$JULIA_PKGDIR/$JULIA_PKGVER/{{PKGNAME}}"

# Note: The "/etc/yum/protected.d/*.conf" contains the names of packages which are
# protected by yum and should not be removed. Protecting packages is necessary as
# this avoids the problem of accidentally removing a dependency of a package which
# is a runtime requirement.

# Get security updates
RUN yum -y update-minimal && \
    yum -y clean all

# Install the current repo as a Julia package
COPY . $PKG_PATH
WORKDIR $PKG_PATH

# Record SHA of the revision the git repo. Note that the repo may not have been in
# a clean repo which makes the SHA the last known commit.
RUN REF=$(cat .git/HEAD | cut -d' ' -f2) && \
    SHA=$(cat .git/$REF 2>/dev/null || echo $REF) && \
    echo $SHA > REVISION && echo "Revision: $SHA" && \
    rm -rf .git

# Install system requirements.
{{#!system}}# {{/!system}}ENV PKGS $(cat ./system-pkgs.txt)
{{#!system}}# {{/!system}}RUN yum -y install $PKGS && \
{{#!system}}# {{/!system}}    echo $PKGS | tr -s '\t ' '\n' > /etc/yum/protected.d/system-pkgs.conf && \
{{#!system}}# {{/!system}}    yum -y clean all

# Install Python requirements. Using the latest version of pip to avoid issues with
# outdated system versions. Note most pip installations will use wheels which don't require
# any compilation but if we need to compile a package from source additional requirements
# may be needed. For example "pandas" requires: python27-devel, python27-Cython, gcc,
# gcc-c++, and gcc-gfortran to be compiled from source.
{{#!python}}# {{/!python}}ENV PKGS \
{{#!python}}# {{/!python}}    python27-devel \
{{#!python}}# {{/!python}}    python27-Cython \
{{#!python}}# {{/!python}}    gcc \
{{#!python}}# {{/!python}}    gcc-c++ \
{{#!python}}# {{/!python}}    gcc-gfortran
{{#!python}}# {{/!python}}ENV PINNED_PKGS \
{{#!python}}# {{/!python}}    python27
{{#!python}}# {{/!python}}RUN yum -y install $PKGS $PINNED_PKGS && \
{{#!python}}# {{/!python}}    echo $PINNED_PKGS | tr -s '\t ' '\n' > /etc/yum/protected.d/python.conf && \
{{#!python}}# {{/!python}}    curl https://bootstrap.pypa.io/get-pip.py | python && \
{{#!python}}# {{/!python}}    pip install -r ./requirements.txt && \
{{#!python}}# {{/!python}}    yum -y autoremove $PKGS && \
{{#!python}}# {{/!python}}    yum -y clean all


# Add and build the all of the required Julia packages. In order to allow the use of
# BinDeps.jl we need to temporarily install additional system packages.
#
# - BinDeps.jl runtime requirements: sudo, make, gcc, unzip, bzip2, xz, unzip
#
#   BinDeps runtime requirements are only used while other packages are being built which
#   makes them safe to only be temporarily installed. When installing system libraries 
#   BinDeps always uses "sudo" to install system packages and waits for user confirmation
#   before installing a package. We'll both install "sudo" and always supply the `-y` flag
#   to ensure that BinDeps installations work automatically. A good test to make sure
#   BinDeps is setup correctly is to run `Pkg.add("Cairo"); Pkg.test("Cairo")`
#
# - HDF5.jl requires the EPEL repo to install hdf5 automatically through BinDeps
#   (https://aws.amazon.com/premiumsupport/knowledge-center/ec2-enable-epel/)
# - yum-config-manager is installed by: yum-utils
ENV PKGS \
    sudo \
    make \
    gcc \
    gcc-c++ \
    bzip2 \
    xz \
    unzip \
    epel-release \
    yum-utils
RUN yum -y install $PKGS && \
    yum-config-manager --setopt=assumeyes=1 --save > /dev/null && \
    yum-config-manager --enable epel > /dev/null && \
    yum list installed | tr -s ' ' | cut -d' ' -f1 | sort > /tmp/pre_state && \
    update-metadata && julia -e 'Pkg.update(); Pkg.resolve(); Pkg.build("{{PKGNAME}}")' && \
    yum list installed | tr -s ' ' | cut -d' ' -f1 | sort > /tmp/post_state && \
    comm -3 /tmp/pre_state /tmp/post_state | grep $'\t' | sed 's/\t//' | sed 's/\..*//' > /etc/yum/protected.d/julia-pkgs.conf && \
    rm /tmp/pre_state /tmp/post_state && \
    yum-config-manager --disable epel > /dev/null && \
    for p in $PKGS; do yum -y autoremove $p &>/dev/null && echo "Removed $p" || echo "Skipping removal of $p"; done && \
    yum -y clean all

# Improve the startup time of packages by pre-compiling {{PKGNAME}} and its dependencies
# into the default system image.
# Note: Need to have libc to avoid "/usr/bin/ld: cannot find crti.o: No such file or directory"
{{#!userimg}}# {{/!userimg}}ENV PKGS \
{{#!userimg}}# {{/!userimg}}    gcc
{{#!userimg}}# {{/!userimg}}ENV PINNED_PKGS \
{{#!userimg}}# {{/!userimg}}    glibc
{{#!userimg}}# {{/!userimg}}RUN yum -y install $PKGS $PINNED_PKGS && \
{{#!userimg}}# {{/!userimg}}    cd $JULIA_PATH/base && \
{{#!userimg}}# {{/!userimg}}    source $JULIA_PATH/Make.user && \
{{#!userimg}}# {{/!userimg}}    $JULIA_PATH/julia -C $MARCH --output-o $JULIA_PATH/userimg.o --sysimage $JULIA_PATH/usr/lib/julia/sys.so --startup-file=no -e "using {{PKGNAME}}" && \
{{#!userimg}}# {{/!userimg}}    cc -shared -o $JULIA_PATH/userimg.so $JULIA_PATH/userimg.o -ljulia -L$JULIA_PATH/usr/lib && \
{{#!userimg}}# {{/!userimg}}    mv $JULIA_PATH/userimg.o $JULIA_PATH/usr/lib/julia/sys.o && \
{{#!userimg}}# {{/!userimg}}    mv $JULIA_PATH/userimg.so $JULIA_PATH/usr/lib/julia/sys.so && \
{{#!userimg}}# {{/!userimg}}    yum -y autoremove $PKGS && \
{{#!userimg}}# {{/!userimg}}    yum -y clean all
