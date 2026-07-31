#!/bin/sh
# mv_cmd — build the UniData binary package (prebuilt BASIC objects).
# Copyright (C) 2026 Gordon Heydon.  GPL-2.0-only (see LICENSE).
#
# Runs INSIDE the udt-builder container (see mv-package-registry/builder): make
# a scratch UniData account, compile BP/CMD.* to objects, and assemble an
# objects-only package — the prebuilt _objects plus the manifest, no source.
# MVPKG-udt installs it by cataloging the objects with no BASIC/compiler
# (LISTSRC/DOCAT detect the _objects).  Validated on UniData 8.3.2.
#
#   BASE=mv-lang_cmd-<ver>-udt-linux-<arch>-<endian>  sh build-udt.sh
# writes ./$BASE.tar.gz.
set -e
: "${UDTHOME:?UDTHOME must be set (run inside the udt-builder container)}"
: "${BASE:?set BASE to the asset base name}"
SRC="$(cd "$(dirname "$0")" && pwd)"
ACCT="${ACCT:-/tmp/cmdbuild}"

# A UniData account (VOC etc.).  newacct is interactive; drive it with expect,
# matching on the prompts so the answer order does not matter.  Owner login
# 'root' and group 'unidata' both exist in the builder image.
command -v expect >/dev/null 2>&1 || dnf -y install expect >/dev/null 2>&1 \
  || microdnf -y install expect >/dev/null 2>&1 || true
rm -rf "$ACCT"; mkdir -p "$ACCT"
cat > /tmp/mkacct.exp <<EXP
set timeout 60
log_user 0
cd "$ACCT"
spawn $UDTHOME/bin/newacct
expect {
  -re {(?i)login name}          { send "root\r";    exp_continue }
  -re {(?i)group name}          { send "unidata\r"; exp_continue }
  -re {(?i)another .*name.*y/n} { send "n\r";       exp_continue }
  -re {(?i)continue.*y/n}       { send "y\r";        exp_continue }
  -re {\(y/n\)}                 { send "y\r";        exp_continue }
  timeout {} eof {}
}
EXP
expect -f /tmp/mkacct.exp
[ -d "$ACCT/VOC" ] || { echo "build-udt: newacct did not create a VOC" >&2; exit 1; }

# Compile the three programs -> BP/_CMD.* objects.
cp "$SRC/BP/CMD.INIT" "$SRC/BP/CMD.ADD" "$SRC/BP/CMD.RUN" "$ACCT/BP/"
( cd "$ACCT" && printf 'BASIC BP CMD.INIT CMD.ADD CMD.RUN\nQUIT\n' | udt )
for o in _CMD.INIT _CMD.ADD _CMD.RUN; do
  [ -f "$ACCT/BP/$o" ] || { echo "build-udt: object $o missing (compile failed)" >&2; exit 1; }
done

# Objects-only package: prebuilt _objects + manifest, no source records.
DIST="$SRC/dist/$BASE"; rm -rf "$DIST"; mkdir -p "$DIST/BP"
cp "$ACCT/BP/_CMD.INIT" "$ACCT/BP/_CMD.ADD" "$ACCT/BP/_CMD.RUN" "$DIST/BP/"
cp "$SRC/PKG" "$SRC/mvpkg.json" "$SRC/LICENSE" "$SRC/README.md" "$DIST/"
tar czf "$SRC/$BASE.tar.gz" -C "$SRC/dist" "$BASE"
echo "build-udt: wrote $BASE.tar.gz"
