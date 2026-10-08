#!/bin/sh
# 在候选镜像内执行；故障注入不修改安装树，也不进入 build-time 自检。
# 从宿主将本文件送入断网、只读根容器的 sh -s energy 或 sh -s trjconv。
set -eu
phase=${1:-energy}
case "$phase" in energy|trjconv) ;; *) exit 2 ;; esac
export GROMACS_AUDIT_FAIL_PHASE="$phase"
d=$(mktemp -d /tmp/gromacs-diagnostics.XXXXXXXX)
trap 'rm -rf -- "$d"' EXIT
mkdir "$d/bin"
printf '#!/bin/sh\nif [ "${1-}" = "$GROMACS_AUDIT_FAIL_PHASE" ]; then echo "injected-$GROMACS_AUDIT_FAIL_PHASE-failure-37" >&2; exit 37; fi\nexec /opt/gromacs/bin/gmx "$@"\n' > "$d/bin/gmx"
chmod 755 "$d/bin/gmx"
status=0
PATH="$d/bin:$PATH" TMPDIR="$d" gromacs-smoke simulate > "$d/observed.log" 2>&1 || status=$?
cat "$d/observed.log"
test "$status" = 37
grep -F "injected-$phase-failure-37" "$d/observed.log" >/dev/null
test -z "$(find "$d" -name 'gromacs-smoke.*' -print)"
if grep -F 'gromacs-smoke: simulate PASS' "$d/observed.log" >/dev/null; then exit 1; fi
grep -F "failed at $phase (exit 37)" "$d/observed.log" >/dev/null
printf 'smoke-diagnostics: %s PASS\n' "$phase"
