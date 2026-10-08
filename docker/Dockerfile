ARG DEBIAN_VERSION=13-slim@sha256:a99cfc517144bc59b1978475ec53b46ecabec7e43635402ee5b77cc54cd1b20a
ARG GROMACS_VERSION=2026.4
ARG GROMACS_SHA256=58eda60979b124fcf9dff8b1b63cedfbc72fdb36d99e921dc1bdc310571098b6
ARG DEBIAN_MIRROR=http://deb.debian.org/debian
ARG DEBIAN_SECURITY_MIRROR=http://deb.debian.org/debian-security

FROM debian:${DEBIAN_VERSION} AS builder

ARG GROMACS_VERSION
ARG GROMACS_SHA256
ARG BUILD_JOBS=4
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
      -DGMX_NNPOT=OFF \
      -DGMX_SIMD=None \
      -DGMX_USE_RDTSCP=OFF \
      -DGMX_FFT_LIBRARY=fftw3 \
      -DGMX_DOUBLE=OFF \
      -DGMXAPI=OFF \
      -DGMX_INSTALL_NBLIB_API=OFF \
      -DBUILD_TESTING=OFF \
      -DGMX_BUILD_UNITTESTS=OFF \
      -DREGRESSIONTEST_DOWNLOAD=OFF; \
    cmake --build build --parallel "${BUILD_JOBS}"; \
    cmake --install build; \
    /opt/gromacs/bin/gmx --version > /tmp/gromacs-version.txt; \
    awk -v version="${GROMACS_VERSION}" '$1 == "GROMACS" && $2 == "version:" && $3 == version { found=1 } END { exit !found }' /tmp/gromacs-version.txt; \
    mkdir -p /opt/gromacs/share/licenses; \
    cp COPYING AUTHORS /opt/gromacs/share/licenses/; \
    rm -rf /opt/gromacs/include /opt/gromacs/lib/cmake /opt/gromacs/lib/pkgconfig /opt/gromacs/share/gromacs/template

RUN set -eux; \
    find src/external -type f \( -iname '*license*' -o -iname '*copying*' -o -iname '*notice*' \) \
      -exec cp --parents '{}' /opt/gromacs/share/licenses/ \;

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
COPY docker/gromacs-smoke /usr/local/bin/gromacs-smoke

ENV PATH=/opt/gromacs/bin:${PATH}
ENV LD_LIBRARY_PATH=/opt/gromacs/lib
ENV GMXDATA=/opt/gromacs/share/gromacs

RUN ln -sf /opt/gromacs/bin/gmx /usr/local/bin/gmx; \
    chmod 755 /usr/local/bin/gromacs-smoke

RUN set -eux; \
    gromacs-smoke version; \
    gromacs-smoke help; \
    ldd "$(command -v gmx)" | grep -F "libfftw3f" >/dev/null; \
    ldd "$(command -v gmx)" | grep -F "libgomp" >/dev/null

RUN gromacs-smoke convert

WORKDIR /tmp

ENV TAFFISH_ENV=TAFFISH
ENV TAFFISH_NAME=gromacs
