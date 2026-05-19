taf-gromacs 2026.2-r2

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

Examples:
  taf-gromacs gmx --version
  taf-gromacs gmx help commands
  taf-gromacs gmx pdb2gmx -h
  taf-gromacs gmx grompp -h
  taf-gromacs gmx mdrun -h
  taf-gromacs gmx editconf -f input.gro -o output.pdb
  taf-gromacs gmx grompp -f md.mdp -c conf.gro -p topol.top -o topol.tpr
  taf-gromacs gmx mdrun -deffnm md -ntmpi 1 -ntomp 4
  taf-gromacs gmx energy -f em.edr -o energy.xvg
  taf-gromacs gmx trjconv -s md.tpr -f md.xtc -o centered.xtc

Command mode:
  GROMACS subcommands belong to the gmx executable. Use:

    taf-gromacs gmx mdrun ...
    taf-gromacs gmx grompp ...

  Do not use taf-gromacs mdrun ... as the normal form.

Build profile:
  GROMACS 2026.2, mixed precision, thread-MPI plus OpenMP, FFTW3 single
  precision, portable scalar SIMD, GPU off, external MPI off. The mdrun
  -plumed option is enabled, but standalone PLUMED tooling is not packaged.

Included:
  gmx executable, GROMACS shared libraries, standard force-field/topology data,
  CPU mdrun via thread-MPI/OpenMP, and preparation/analysis subcommands listed
  by gmx help commands.

Not included:
  CUDA, SYCL, HIP, OpenCL, external MPI, CUDA-aware MPI, NVSHMEM, cuFFTMp,
  standalone PLUMED tools, gmxapi/nblib developer packaging, MDAnalysis, VMD,
  MDTraj, PyMOL, or hardware-tuned production builds.

Notes:
  This is a portable CPU baseline for preparation, analysis, teaching, testing,
  and modest CPU-only runs. Long production simulations often need a
  hardware-tuned upstream build with GPU, MPI, optimized SIMD, and site policy.

Container:
  image: ghcr.io/taffish/gromacs:2026.2-r2
  platforms: linux/amd64, linux/arm64

Upstream:
  homepage: https://www.gromacs.org/
  source:   https://gitlab.com/gromacs/gromacs
  manual:   https://manual.gromacs.org/2026.2/
  license:  LGPL-2.1-or-later
  doi:      10.5281/zenodo.20037885
