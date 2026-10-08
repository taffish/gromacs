taf-gromacs 2026.4-r1
Prepare molecular systems, run CPU molecular dynamics and analyse trajectories.
CLI/headless only: export XVG/PDB/EPS for a separately installed viewer.

Usage:
  taf-gromacs gmx COMMAND [OPTIONS...]
  taf-gromacs --help                 Installed-wrapper help
  taf-gromacs --version              Package version
  taf-gromacs --compile              Show generated command
  taf-gromacs gmx --version          Upstream version and build profile
  taf-gromacs gmx help commands      List upstream commands
  taf-gromacs gmx mdrun -h           Command-specific help

Always include gmx before a subcommand, not "taf-gromacs mdrun ...".
Use "taf-gromacs -- --version" for option-leading default-command arguments.

Select one backend:
  export TAFFISH_CONTAINER_BACKEND=docker
  export TAFFISH_CONTAINER_BACKEND=podman
  export TAFFISH_CONTAINER_BACKEND=apptainer
Apptainer requires native Linux. Use a writable project directory; files in
the current directory are accessible to the wrapper. Commands below are shared.

Prepare and run (supply scientifically appropriate structures and md.mdp):
  taf-gromacs gmx pdb2gmx -f protein.pdb -o conf.gro -p topol.top -ff amber99sb-ildn -water tip3p
  taf-gromacs gmx editconf -f conf.gro -o boxed.gro -c -d 1.0 -bt cubic
  taf-gromacs gmx solvate -cp boxed.gro -cs spc216.gro -o solvated.gro -p topol.top
  taf-gromacs gmx grompp -f md.mdp -c solvated.gro -p topol.top -o md.tpr
  taf-gromacs gmx mdrun -deffnm md -ntmpi 1 -ntomp 4
Use -ff/-water to select compatible parameters and -ntomp for available CPUs.
Do not bypass unexplained grompp warnings with -maxwarn.

Analyse and export:
  printf 'Potential\n0\n' | taf-gromacs gmx energy -f md.edr -o potential.xvg -xvg none
  printf '0\n' | taf-gromacs gmx trjconv -s md.tpr -f md.xtc -o frames.pdb
Select group/energy names appropriate to your system. Key outputs: TPR run
input, GRO coordinates, EDR energies, LOG, checkpoints and configured trajectories.
Use distinct output prefixes; upstream normally backs up existing output files.
GMX_MAXBACKUP=0 can overwrite files; it is not an overwrite guard in this version.

Additional shared force fields/topologies:
Built-in force fields need no download. For extra site files, first ask the
administrator to prepare /srv/taffish/db/gromacs/site-v1 with read/search access.
Run from a separate writable project; choose the matching backend command:

  TAFFISH_CONTAINER_BACKEND=docker TAFFISH_DOCKER_RUN_ARGS="-v /srv/taffish/db/gromacs/site-v1:/gromacs-library:ro" taf-gromacs env GMXLIB=/gromacs-library gmx grompp -f md.mdp -c conf.gro -p topol.top -o md.tpr
  TAFFISH_CONTAINER_BACKEND=podman TAFFISH_PODMAN_RUN_ARGS="-v /srv/taffish/db/gromacs/site-v1:/gromacs-library:ro" taf-gromacs env GMXLIB=/gromacs-library gmx grompp -f md.mdp -c conf.gro -p topol.top -o md.tpr
  TAFFISH_CONTAINER_BACKEND=apptainer TAFFISH_APPTAINER_RUN_ARGS="--bind /srv/taffish/db/gromacs/site-v1:/gromacs-library:ro" taf-gromacs env GMXLIB=/gromacs-library gmx grompp -f md.mdp -c conf.gro -p topol.top -o md.tpr

Replace the host path for a personal library. On VM backends expose it to the VM.
GMXLIB adds a search path; cwd and built-ins remain available. Avoid duplicate
force-field names. Omit the bind and env assignment to disable extra sharing.
No automatic host-library mount or missing-resource download is performed.

Limits and troubleshooting:
  CPU only; GPU/external MPI/NNP models need a separately configured site build.
  Desktop/-w viewing is not provided on Docker, Podman or Apptainer:
  save outputs and open them in an external viewer instead.
  PLUMED/VMD interfaces do not include their external runtimes.
  For spaces, use uncompressed input and preserve literal quotes:
  taf-gromacs gmx editconf -f "'water input.gro'" -o "'water output.pdb'"
  Choose output directories you can write; keep shared resources read-only.
  Tiny examples do not validate a scientific MD protocol.

More: https://manual.gromacs.org/2026.4/
Resource preparation, build profile and detailed limits: app README.
