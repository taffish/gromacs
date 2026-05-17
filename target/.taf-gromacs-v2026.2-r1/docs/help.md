taf-gromacs 2026.2-r1

TAFFISH wrapper for GROMACS, a molecular dynamics simulation and analysis
suite.

Usage:
  taf-gromacs [TAF-APP-OPTION]
  taf-gromacs [IN-CONTAINER-COMMAND] [ARGS...]

TAF app options:
  -h, --help       Show this help text
  -v, --version    Show package and command version
  --compile        Print generated shell code instead of running it
  --               Stop parsing TAFFISH wrapper options

Recommended commands:
  taf-gromacs --help
  taf-gromacs --version
  taf-gromacs gmx --version
  taf-gromacs gmx help commands
  taf-gromacs gmx pdb2gmx -h
  taf-gromacs gmx grompp -h
  taf-gromacs gmx mdrun -h
  taf-gromacs gmx editconf -f input.gro -o output.pdb
  taf-gromacs gmx grompp -f md.mdp -c conf.gro -p topol.top -o topol.tpr
  taf-gromacs gmx mdrun -deffnm md -ntmpi 1 -ntomp 4

Command-mode note:
  This app exposes the upstream gmx executable. Because TAFFISH command mode
  treats the first non-option argument as the in-container executable, call
  GROMACS subcommands as:

    taf-gromacs gmx mdrun ...
    taf-gromacs gmx grompp ...

  Do not use taf-gromacs mdrun ... as the normal form; mdrun is a subcommand
  of gmx, not a separate executable in this build.

Build profile:
  version:      GROMACS 2026.2
  precision:    mixed / single
  parallelism:  thread-MPI + OpenMP
  FFT:          FFTW3 single precision
  SIMD:         None / portable scalar
  GPU:          off
  external MPI: off
  PLUMED:       mdrun -plumed option enabled; no standalone PLUMED package

Common GROMACS workflow:
  1. Prepare topology and coordinates:
       taf-gromacs gmx pdb2gmx -f protein.pdb -o processed.gro -p topol.top
       taf-gromacs gmx editconf -f processed.gro -o boxed.gro -c -d 1.0 -bt cubic
       taf-gromacs gmx solvate -cp boxed.gro -cs spc216.gro -o solvated.gro -p topol.top

  2. Build run input:
       taf-gromacs gmx grompp -f minim.mdp -c solvated.gro -p topol.top -o em.tpr

  3. Run simulation:
       taf-gromacs gmx mdrun -deffnm em -ntmpi 1 -ntomp 4

  4. Analyze trajectories:
       taf-gromacs gmx energy -f em.edr -o energy.xvg
       taf-gromacs gmx trjconv -s md.tpr -f md.xtc -o centered.xtc
       taf-gromacs gmx rms -s md.tpr -f md.xtc -o rmsd.xvg

Included:
  - gmx command-line executable
  - GROMACS shared libraries
  - standard force-field and topology data
  - CPU mdrun support through thread-MPI and OpenMP
  - upstream mdrun -plumed option
  - preparation and analysis subcommands listed by gmx help commands

Not included in this baseline image:
  - CUDA, SYCL, HIP, OpenCL, or other GPU acceleration
  - external MPI, CUDA-aware MPI, NVSHMEM, or cuFFTMp
  - standalone PLUMED tooling or custom PLUMED-patched GROMACS variants
  - gmxapi / nblib developer API packaging
  - third-party analysis programs such as MDAnalysis, VMD, MDTraj, or PyMOL

High-performance note:
  This release is the portable CPU baseline. It is suitable for preparation,
  analysis, teaching, testing, and modest CPU-only runs. For long production
  simulations, users often need a hardware-tuned GROMACS build with CUDA, HIP,
  SYCL, external MPI, GPU-aware MPI, or optimized SIMD settings.

  If you need that, build GROMACS from the official upstream instructions for
  your own hardware or watch for future TAFFISH variants such as gromacs-cuda,
  gromacs-hip, gromacs-sycl, or gromacs-mpi. These are separate by design
  because GROMACS GPU and cluster builds are driver-, compiler-, and
  site-policy-dependent.

Container:
  image: ghcr.io/taffish/gromacs:2026.2-r1
  supported backends: apptainer, podman, docker
  supported platforms: linux/amd64, linux/arm64

Upstream:
  project: GROMACS
  homepage: https://www.gromacs.org/
  source: https://gitlab.com/gromacs/gromacs
  documentation: https://manual.gromacs.org/2026.2/
  download: https://ftp.gromacs.org/gromacs/gromacs-2026.2.tar.gz
  license: LGPL-2.1-or-later
  software doi: 10.5281/zenodo.20037885
  related citation: Abraham et al. 2015, doi:10.1016/j.softx.2015.06.001
