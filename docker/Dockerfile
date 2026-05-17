ARG DEBIAN_VERSION=13-slim
ARG GROMACS_VERSION=2026.2
ARG GROMACS_SHA256=d27e4455e8246177952366798631a0dad9f2e1f567400a6cb854a168dcc050dd
ARG DEBIAN_MIRROR=http://deb.debian.org/debian
ARG DEBIAN_SECURITY_MIRROR=http://deb.debian.org/debian-security

FROM debian:${DEBIAN_VERSION} AS builder

ARG GROMACS_VERSION
ARG GROMACS_SHA256
ARG DEBIAN_MIRROR
ARG DEBIAN_SECURITY_MIRROR

ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    sed -i \
      -e "s|http://deb.debian.org/debian-security|${DEBIAN_SECURITY_MIRROR}|g" \
      -e "s|http://deb.debian.org/debian|${DEBIAN_MIRROR}|g" \
      /etc/apt/sources.list.d/debian.sources; \
    for attempt in 1 2 3 4 5 6; do \
      if apt-get -o Acquire::Retries=3 update \
       && apt-get -o Acquire::Retries=3 install -y --no-install-recommends \
            build-essential \
            ca-certificates \
            cmake \
            curl \
            libfftw3-dev \
            ninja-build \
            pkg-config \
            python3 \
            python3-dev; then \
        break; \
      fi; \
      if [ "$attempt" = "6" ]; then exit 1; fi; \
      apt-get clean; \
      rm -rf /var/lib/apt/lists/*; \
      sleep 5; \
    done; \
    rm -rf /var/lib/apt/lists/*; \
    cmake --version

WORKDIR /tmp/build/gromacs

RUN set -eux; \
    curl --retry 5 --retry-delay 2 --retry-all-errors -fsSL \
      "https://ftp.gromacs.org/gromacs/gromacs-${GROMACS_VERSION}.tar.gz" \
      -o gromacs.tar.gz; \
    echo "${GROMACS_SHA256}  gromacs.tar.gz" | sha256sum -c -; \
    tar -xzf gromacs.tar.gz --strip-components=1; \
    cmake -S . -B build -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/opt/gromacs \
      -DGMX_MPI=OFF \
      -DGMX_THREAD_MPI=ON \
      -DGMX_OPENMP=ON \
      -DGMX_GPU=OFF \
      -DGMX_SIMD=None \
      -DGMX_FFT_LIBRARY=fftw3 \
      -DGMX_DOUBLE=OFF \
      -DGMXAPI=OFF \
      -DGMX_INSTALL_NBLIB_API=OFF \
      -DBUILD_TESTING=OFF \
      -DGMX_BUILD_UNITTESTS=OFF \
      -DREGRESSIONTEST_DOWNLOAD=OFF; \
    cmake --build build --parallel "$(nproc)"; \
    cmake --install build; \
    /opt/gromacs/bin/gmx --version | grep -F "GROMACS version:" >/dev/null; \
    /opt/gromacs/bin/gmx --version | grep -F "${GROMACS_VERSION}" >/dev/null

FROM debian:${DEBIAN_VERSION}

ARG DEBIAN_MIRROR
ARG DEBIAN_SECURITY_MIRROR

ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    sed -i \
      -e "s|http://deb.debian.org/debian-security|${DEBIAN_SECURITY_MIRROR}|g" \
      -e "s|http://deb.debian.org/debian|${DEBIAN_MIRROR}|g" \
      /etc/apt/sources.list.d/debian.sources; \
    for attempt in 1 2 3 4 5 6; do \
      if apt-get -o Acquire::Retries=3 update \
       && apt-get -o Acquire::Retries=3 install -y --no-install-recommends \
            ca-certificates \
            libfftw3-single3 \
            libgomp1 \
            zlib1g; then \
        break; \
      fi; \
      if [ "$attempt" = "6" ]; then exit 1; fi; \
      apt-get clean; \
      rm -rf /var/lib/apt/lists/*; \
      sleep 5; \
    done; \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/gromacs /opt/gromacs

ENV PATH=/opt/gromacs/bin:${PATH}
ENV LD_LIBRARY_PATH=/opt/gromacs/lib
ENV GMXDATA=/opt/gromacs/share/gromacs

RUN ln -sf /opt/gromacs/bin/gmx /usr/local/bin/gmx

RUN set -eux; \
    gmx --version | grep -F "GROMACS version:" >/dev/null; \
    gmx --version | grep -F "2026.2" >/dev/null; \
    gmx help commands | grep -F "mdrun" >/dev/null; \
    gmx help commands | grep -F "pdb2gmx" >/dev/null; \
    gmx mdrun -h 2>&1 | grep -F "GROMACS" >/dev/null; \
    ldd "$(command -v gmx)" | grep -F "libfftw3f" >/dev/null; \
    ldd "$(command -v gmx)" | grep -F "libgomp" >/dev/null

RUN set -eux; \
    mkdir -p /tmp/gromacs-check; \
    cd /tmp/gromacs-check; \
    printf "Tiny water\n    3\n    1SOL     OW    1   0.000   0.000   0.000\n    1SOL    HW1    2   0.095   0.000   0.000\n    1SOL    HW2    3  -0.032   0.090   0.000\n   1.00000   1.00000   1.00000\n" > water.gro; \
    gmx editconf -f water.gro -o water.pdb >/dev/null 2>&1; \
    grep -F "ATOM" water.pdb >/dev/null; \
    printf '#include "oplsaa.ff/forcefield.itp"\n#include "oplsaa.ff/tip3p.itp"\n\n[ system ]\nTiny water\n\n[ molecules ]\nSOL 1\n' > topol.top; \
    printf "integrator = md\nnsteps = 0\ndt = 0.001\nnstlist = 1\ncutoff-scheme = Verlet\nrlist = 0.4\nverlet-buffer-tolerance = -1\ncoulombtype = Cut-off\nrcoulomb = 0.4\nrvdw = 0.4\npbc = xyz\nconstraints = none\ncontinuation = yes\n" > mini.mdp; \
    gmx grompp -f mini.mdp -c water.gro -p topol.top -o mini.tpr >/dev/null 2>&1; \
    test -s mini.tpr; \
    gmx mdrun -deffnm mini -ntmpi 1 -ntomp 1 >/dev/null 2>&1; \
    test -s mini.log; \
    cd /; \
    rm -rf /tmp/gromacs-check

WORKDIR /root

ENV TAFFISH_ENV=TAFFISH
ENV TAFFISH_NAME=gromacs
