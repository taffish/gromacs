# taf-gromacs

TAFFISH wrapper for [GROMACS](https://www.gromacs.org/), a molecular dynamics
simulation and analysis suite for biomolecules, polymers, liquids, and other
molecular systems.

This TAFFISH app packages GROMACS `2026.2` as a CPU-only container build and
exposes the upstream `gmx` command through the versioned `taf-gromacs` wrapper.

Release `2026.2-r2` is a help-only TAFFISH update. It keeps the upstream
software, Dockerfile, runtime dependencies, smoke tests, and command behavior
unchanged from `2026.2-r1`, and refreshes the terminal `taf-gromacs --help`
text.

## Build Profile

This release is intentionally a portable baseline build:

```text
GROMACS version: 2026.2
precision: mixed / single
parallelism: thread-MPI + OpenMP
GPU support: off
external MPI: off
FFT library: FFTW3 single precision
SIMD: None / portable scalar
PLUMED interface: enabled in gmx mdrun; no standalone PLUMED package
```

The goal is to provide a reliable default app for system preparation, small to
medium CPU simulations, and trajectory analysis. It intentionally avoids
CPU-specific SIMD assumptions; users who need maximum performance should build
a site-local SIMD/GPU/MPI tuned variant. GPU, CUDA-aware MPI, SYCL, OpenCL,
HIP, NVSHMEM, and external-MPI cluster builds are important GROMACS
configurations, but they are hardware and site dependent. Those should be
handled by a separate TAFFISH app variant, a site-local image, or explicit
runtime policy rather than being hidden inside this baseline image.

## Installation

Install from the public TAFFISH Hub index:

```sh
taf update
taf install gromacs
```

Install the exact release:

```sh
taf install gromacs 2026.2-r2
```

For local testing before publication:

```sh
taf install --from .
```

## Usage

Show TAFFISH app help:

```sh
taf-gromacs --help
```

Show the TAFFISH package version:

```sh
taf-gromacs --version
```

Show upstream GROMACS version information:

```sh
taf-gromacs gmx --version
```

List upstream commands:

```sh
taf-gromacs gmx help commands
```

Show help for a specific GROMACS command:

```sh
taf-gromacs gmx mdrun -h
taf-gromacs gmx grompp -h
taf-gromacs gmx pdb2gmx -h
```

Because this app uses TAFFISH command mode, the first non-option argument is
treated as the command to run inside the container. Since GROMACS itself is
subcommand-driven, the clearest and recommended form is:

```sh
taf-gromacs gmx <gromacs-subcommand> [options...]
```

For example:

```sh
taf-gromacs gmx pdb2gmx -f protein.pdb -o processed.gro -p topol.top
taf-gromacs gmx editconf -f processed.gro -o boxed.gro -c -d 1.0 -bt cubic
taf-gromacs gmx solvate -cp boxed.gro -cs spc216.gro -o solvated.gro -p topol.top
taf-gromacs gmx grompp -f minim.mdp -c solvated.gro -p topol.top -o em.tpr
taf-gromacs gmx mdrun -deffnm em -ntmpi 1 -ntomp 4
taf-gromacs gmx trjconv -s md.tpr -f md.xtc -o centered.xtc
```

Do not write `taf-gromacs mdrun ...` for normal use. In command mode, `mdrun`
would be interpreted as an executable inside the container, not as a subcommand
of `gmx`.

For option-leading arguments to the default `gmx` command, use `--`:

```sh
taf-gromacs -- --version
taf-gromacs -- -h
```

## Included Functionality

The image includes the upstream `gmx` executable, GROMACS shared libraries, the
standard GROMACS data directory, and built-in force-field/topology data under
`/opt/gromacs/share/gromacs`.

Common command groups include:

```text
system preparation:  pdb2gmx, editconf, solvate, genion, make_ndx
run input:           grompp, convert-tpr
simulation:          mdrun
trajectory tools:    trjconv, trjcat, trjorder, check
analysis tools:      energy, rms, rmsf, gyrate, hbond, distance, rdf, sasa
format/report tools: dump, report-methods, xpm2ps
```

Use `taf-gromacs gmx help commands` for the full command list for this build.
`gmx mdrun -h` also exposes the upstream `-plumed` option in this build, but
the image does not package a separate `plumed` executable or a custom
PLUMED-patched GROMACS variant.

## Boundaries

This baseline app does not include:

```text
CUDA, SYCL, HIP, OpenCL, or other GPU acceleration
external MPI or GPU-aware MPI
NVSHMEM or cuFFTMp
standalone PLUMED tooling or custom PLUMED-patched GROMACS variants
gmxapi / nblib developer API packaging
third-party analysis suites such as MDAnalysis, VMD, MDTraj, or PyMOL
```

These are not missing hidden runtime dependencies for the standard `gmx`
command. They are alternate build modes, site-specific accelerator stacks, or
separate tools that should be composed explicitly.

## High-Performance Needs

Use this release when you want a portable GROMACS environment for preparation,
analysis, teaching, testing, or modest CPU-only runs. For long production MD
simulations, GPU acceleration and hardware-tuned builds are often important.

Users with high-performance needs should either build GROMACS from the official
instructions for their own hardware or watch for future TAFFISH variants that
may target specific accelerator stacks, for example:

```text
gromacs-cuda   NVIDIA CUDA builds
gromacs-hip    AMD ROCm/HIP builds
gromacs-sycl   Intel/AMD SYCL builds
gromacs-mpi    external-MPI or cluster-oriented builds
```

Those variants are intentionally not folded into `taf-gromacs` because one
GROMACS build can only target one GPU backend, and accelerator/MPI stacks depend
on drivers, compilers, cluster policy, and the target hardware. A site-local
image built from the official GROMACS documentation may be the best option for
production HPC environments.

## Package

```text
name: gromacs
command: taf-gromacs
version: 2026.2-r2
kind: tool
image: ghcr.io/taffish/gromacs:2026.2-r2
```

## Container

The container is built from `docker/Dockerfile`. It starts from
`debian:13-slim`, downloads the official `gromacs-2026.2.tar.gz` source
archive, verifies its SHA256 checksum, compiles with CMake and Ninja, installs
to `/opt/gromacs`, and keeps only runtime libraries in the final image.

The image is intended for native:

```text
linux/amd64
linux/arm64
```

The smoke metadata checks:

```text
exist: gmx
test:  gmx reports version 2026.2
test:  command list and mdrun help are available
test:  editconf converts a minimal GRO file to PDB
test:  grompp builds a tiny water TPR and mdrun runs a zero-step simulation
```

Smoke tests validate installation, force-field data access, basic file
conversion, run-input generation, and a minimal CPU `mdrun` path. They do not
replace scientific validation of molecular dynamics protocols.

## Upstream

- Homepage: <https://www.gromacs.org/>
- Source and releases: <https://gitlab.com/gromacs/gromacs>
- Public GitHub mirror: <https://github.com/gromacs/gromacs>
- Documentation: <https://manual.gromacs.org/2026.2/>
- Download: <https://ftp.gromacs.org/gromacs/gromacs-2026.2.tar.gz>
- License: LGPL-2.1-or-later
- Software DOI: `10.5281/zenodo.20037885`
- Related citation: Abraham et al. 2015, doi:`10.1016/j.softx.2015.06.001`
