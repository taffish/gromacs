# taf-gromacs

TAFFISH command wrapper for [GROMACS](https://www.gromacs.org/) molecular
dynamics preparation, CPU simulation and trajectory analysis.

| Package | Value |
| --- | --- |
| Version | `2026.4-r1` |
| Command | `taf-gromacs` |
| Image | `ghcr.io/taffish/gromacs:2026.4-r1` |
| Native platforms | `linux/amd64`, `linux/arm64` |
| Profile | CPU, mixed precision, thread-MPI/OpenMP, FFTW3, portable scalar SIMD |

This successor updates 2026.3 to the official 2026.4 source without changing
upstream algorithms. It is a portable baseline, not a hardware-tuned HPC build.
RDTSCP timing is disabled explicitly: some virtual CPUs mask that instruction,
and upstream otherwise refuses to start mdrun even with scalar SIMD selected.

## Install and get started

After this candidate is published and indexed:

```sh
taf update
taf install gromacs 2026.4-r1
taf-gromacs --help
taf-gromacs --version
taf-gromacs gmx --version
taf-gromacs gmx help commands
taf-gromacs gmx mdrun -h
```

Always include `gmx` before its subcommand. `taf-gromacs mdrun` would request
an executable called `mdrun`, not `gmx mdrun`. Wrapper `--help` and
`--version` describe the package; `gmx -h` and `gmx --version` describe upstream.
Option-leading arguments can also use `taf-gromacs -- --version`.

Choose one backend; commands below then remain the same:

```sh
export TAFFISH_CONTAINER_BACKEND=docker
# or:
export TAFFISH_CONTAINER_BACKEND=podman
# or, on native Linux with Apptainer:
export TAFFISH_CONTAINER_BACKEND=apptainer
```

## Common tasks, inputs and outputs

Use a writable project directory. The wrapper mounts the current directory;
keep input paths within it, or explicitly mount external resources as below.
These are command patterns, not a validated scientific simulation protocol.

```sh
taf-gromacs gmx pdb2gmx -f protein.pdb -o processed.gro -p topol.top -ff amber99sb-ildn -water tip3p
taf-gromacs gmx editconf -f processed.gro -o boxed.gro -c -d 1.0 -bt cubic
taf-gromacs gmx solvate -cp boxed.gro -cs spc216.gro -o solvated.gro -p topol.top
taf-gromacs gmx grompp -f md.mdp -c solvated.gro -p topol.top -o md.tpr
taf-gromacs gmx mdrun -deffnm md -ntmpi 1 -ntomp 4
printf 'Potential\n0\n' | taf-gromacs gmx energy -f md.edr -o potential.xvg -xvg none
printf '0\n' | taf-gromacs gmx trjconv -s md.tpr -f md.xtc -o frames.pdb
```

Coordinates use PDB/GRO; topology uses TOP/ITP; run settings use MDP;
`grompp` writes a binary TPR. `mdrun -deffnm md` writes `md.log`,
`md.edr`, `md.gro`, checkpoints, and trajectories according to the MDP.
Analyses write XVG text, structures or matrices. Inspect group/energy names
for your own system instead of assuming the example selections.

Existing outputs normally become numbered upstream backups. Use distinct
output prefixes for independent runs; do not use `-maxwarn` to bypass unexplained
preprocessing warnings. Scientific force-field, protonation, water model,
equilibration, convergence and sampling choices remain the user's responsibility.
Do not treat `GMX_MAXBACKUP=0` as an overwrite guard: the 2026.4 implementation
disables backups and can overwrite outputs, despite the environment-variable
manual describing zero as a refusal mode. This upstream behavior is preserved
and tested; use a new output directory/prefix instead.

For a path containing spaces, preserve quotes through the current wrapper:

```sh
taf-gromacs gmx editconf -f "'water input.gro'" -o "'water output.pdb'"
```

Use uncompressed input for this path; upstream compressed-input subprocesses
have a separate shell-quoting limitation.

## Resources and administrator-once sharing

**Bundled small resources:** the exact source archive contains the standard
force fields, solvent coordinates and topology tables, installed read-only at
`/opt/gromacs/share/gromacs/top`. They are already reusable by all container
users; no model/database download or first-use cache is required.
AMBER14SB/19SB data and their citations remain intact.

**Project/site resources:** user-selected force fields, ligand parameters,
TOP/ITP, MDP and reference coordinates are scientific project inputs. This
profile has no fixed external catalog or upstream downloader. It therefore
does not invent an automatic installer for arbitrary third-party force fields.
Acquire any additional parameter set from its author, retain its version,
checksum, license/citation and suitability review; check redistribution rights
separately from GROMACS. Small bundled resources and project-specific inputs
make download/resume/atomic resource-helper gates N/A, not the mount/reuse gates.

An administrator can prepare a versioned directory once, for example
`/srv/taffish/db/gromacs/site-v1`, containing selected `*.ff` trees and/or
ITP files. Keep an inventory and SHA256 manifest with the source citations,
finish preparation before making the directory available, and keep it
immutable. Give ordinary users read/search access, never world-write access.
A personal directory such as `$HOME/.local/share/taffish/db/gromacs/site-v1`
uses the same read-only bind mechanism. No root permission is needed at run time.

Run the following from your separate writable project directory. The example
assumes the administrator has prepared the resource directory and your TOP
references a member of it:

```sh
TAFFISH_CONTAINER_BACKEND=docker \
TAFFISH_DOCKER_RUN_ARGS="-v /srv/taffish/db/gromacs/site-v1:/gromacs-library:ro" \
  taf-gromacs env GMXLIB=/gromacs-library gmx grompp -f md.mdp -c conf.gro -p topol.top -o md.tpr

TAFFISH_CONTAINER_BACKEND=podman \
TAFFISH_PODMAN_RUN_ARGS="-v /srv/taffish/db/gromacs/site-v1:/gromacs-library:ro" \
  taf-gromacs env GMXLIB=/gromacs-library gmx grompp -f md.mdp -c conf.gro -p topol.top -o md.tpr

TAFFISH_CONTAINER_BACKEND=apptainer \
TAFFISH_APPTAINER_RUN_ARGS="--bind /srv/taffish/db/gromacs/site-v1:/gromacs-library:ro" \
  taf-gromacs env GMXLIB=/gromacs-library gmx grompp -f md.mdp -c conf.gro -p topol.top -o md.tpr
```

Replace only the host directory for a personal or different site root.
Docker/Podman VM hosts must first expose that host path to their VM.
There is **no automatic host-library mount**. `GMXLIB` adds a search path;
the current directory and built-in library can still supply files. It is not
a scientific force-field selector or a fail-closed replacement of built-ins.
Select the intended field explicitly with `pdb2gmx -ff`; avoid duplicate names.
To disable additional sharing, omit the bind and `env GMXLIB=...`.
Neither resource lookup nor a missing member triggers a network download.

## Capability and backend boundaries

| Surface | Docker | Podman | Apptainer |
| --- | --- | --- | --- |
| CPU CLI, files in cwd | Same wrapper commands | Same | Same on native Linux |
| External library | `-v host:/gromacs-library:ro` | Same | `--bind host:/gromacs-library:ro` |
| GPU / external MPI | Not built; use site-tuned GROMACS | Same | Same |
| Desktop / automatic `-w` viewing | Not provided; export files to a separate viewer | Same | Same |
| VMD interactive MD / PLUMED runtime / neural-network potentials | Outside this baseline's validated surface | Same | Same |

No app-intrinsic runtime arguments are required. Optional bind/CPU policy belongs
in the selected backend's run arguments. Native platforms are distinct from
backends; an untested architecture/backend combination is not a PASS.

The official visualization guide recommends independent VMD, PyMOL, RasMol,
Chimera and Grace installations. The 2026.4 CLI source has no bundled desktop
or browser UI to expose. Its optional `-w` opener forks external
`xmgrace`, `ghostview`, ImageMagick `display` or `rasmol` using DISPLAY.
This CPU/headless package deliberately does not embed that multi-application
desktop stack or a noVNC service: retain XVG/PDB/EPS output and open it with a
separately installed viewer. This is a documented composition boundary, not
a claim that all official optional integrations are packaged. Do not use `-w`
here. Exported XVG is data, not a self-contained interactive report.

External MPI, GPU/driver stacks, gmxapi/nblib developer APIs, VMD plugins and
PyTorch/NNP model loading need a different build/dependency contract.
`GMX_NNPOT=OFF` makes the existing no-Libtorch boundary explicit.
The upstream Colvars support and PLUMED interface remain compiled; an exposed
`-plumed` option alone does not provide the PLUMED kernel. VMD IMD is also an
optional interface, not an included viewer or a validated network service.
No ports are opened by ordinary CLI runs. Use a dedicated site build for these
integrations rather than assuming this baseline is a tuned production-MD stack.

Hidden dependency review covered shared libraries, compressed-file subprocesses,
`trjconv -exec`, `tune_pme` launchers, visualization openers and plugin loading.
Gzip provides `gunzip`/`uncompress`; custom `-exec` programs must be supplied
explicitly. Use uncompressed input for paths containing spaces: upstream
compressed-input shell commands do not quote every path. Standard GROMACS
trajectory readers do not require VMD plugins.

## Build, provenance and verification

From this app's root, matching canonical Action `context: .`:

```sh
taf check
docker build --platform linux/arm64 -f docker/Dockerfile -t ghcr.io/taffish/gromacs:2026.4-r1 .
# On a native amd64 host, substitute --platform linux/amd64.
taf run -b docker -- gmx --version
taf build
TAFFISH_CONTAINER_BACKEND=docker target/taf-gromacs-v2026.4-r1 gmx --version
```

The Dockerfile pins the Debian 13-slim multi-platform digest and verifies official
source SHA256 `58eda60979b124fcf9dff8b1b63cedfbc72fdb36d99e921dc1bdc310571098b6`.
A multi-stage build excludes the compiler/source tree; unused headers and
developer CMake/pkg-config/template files are removed before the runtime copy.
Force fields, runtime libraries, upstream licenses and CLI help are retained.
Bundled component LICENSE/COPYING/NOTICE files are preserved under
`/opt/gromacs/share/licenses/src/external/`; their presence does not imply that
every optional component was compiled into this CPU build.
Build-time checks are lightweight version/help/conversion only, with no timing,
floating-point equality, browser, GPU or large simulation assertion.

The eight independent smoke cases cover exact version/profile, help, coordinate
conversion, solvent/preparation, two-step MD plus energy/trajectory outputs,
library search, a 100,000-line skipped preprocessor block, and missing-input
failure. Each creates a private scratch directory and reports stage/exit/log
tail on failure. They are engineering checks, not scientific accuracy validation.
Interactive smoke selections use private input files so the failure-stage marker
stays in the parent shell. `tests/smoke-diagnostics.sh` injects an exit-37 error
into energy or trjconv and checks the actual stage, original status, log replay,
absence of a success marker and scratch cleanup. This negative regression runs
inside the candidate runtime, separately from lightweight build-time checks.

Candidate runtime verification (2026-10-03):

| Evidence axis | Result |
| --- | --- |
| Native arm64 Docker | Root-context build; 22 normal/read-only exact probes; 34 wrapper checks: PASS |
| Native amd64 Docker | Root-context build; 22 exact probes; 34 wrapper checks: PASS |
| Native amd64 Podman | Same OCI content; 22 exact probes; 32 wrapper checks: PASS |
| Native amd64 Apptainer | Same OCI converted to actual read-only SIF; 11 exact probes; 32 wrapper checks: PASS |
| arm64 Podman / Apptainer combinations | Not separately validated; see boundary below |

Total after the diagnostic repair: 77 exact probes, 132 wrapper checks, four
diagnostic/compression suites and eight energy/trjconv fault-injection cases.
Direct probes are fresh and offline with no production bind; wrapper
tests separately verify actual read-only library mounts, ordinary-user output
ownership, another UID reusing resources, quoted paths, stdin and expected
failures. The native-platform and backend axes are both covered, not every
Cartesian combination. Local Podman keyring was 184/200, so no environment
restart/quota change was attempted. Podman was fully tested on xjp amd64;
there is no arm64 Apptainer runner here. Resource text files have no
architecture-specific format or runtime-argument coupling, so these untested
combinations are disclosed without claiming a combination PASS or a backend
exception. Real site deployment and production MD accuracy are not claimed.

Runtime images are 143,706,970 bytes (arm64) and 126,928,428 bytes (amd64).
GROMACS is about 30 MB including about 8.2 MB of standard data on arm64;
compiler/source, headers and developer build payload are excluded. Small
upstream manpages and auxiliary metadata are retained. Image inspect/history,
directory profiles and missing-library checks were recorded for both platforms.
`taf check`, documentation review, upstream no-write check and remote-checked
publish dry-run passed. Final target cleanup is recorded separately in the
maintainer handoff. This is a publish-ready candidate, not an actual publication.

## License and upstream

The TAFFISH wrapper repository is Apache-2.0. GROMACS and bundled distribution
material retain their upstream LGPL-2.1-or-later and component notices;
third-party scientific parameter sets require their own license review.

- [2026.4 manual](https://manual.gromacs.org/2026.4/)
- [Release notes](https://manual.gromacs.org/2026.4/release-notes/2026/2026.4.html)
- [Official source](https://ftp.gromacs.org/gromacs/gromacs-2026.4.tar.gz)
- [Visualization guidance](https://manual.gromacs.org/2026.4/how-to/visualize.html)
- Software DOI: `10.5281/zenodo.23102386` (2026.4 CITATION.cff).
- Abraham et al. 2015: `10.1016/j.softx.2015.06.001`.
