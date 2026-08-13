#!/bin/sh
# mv_cmd — build the UniData binary package (prebuilt BASIC objects) and stage it.
# Copyright (C) 2026 Gordon Heydon.  GPL-2.0-only (see LICENSE).
#
# Runs INSIDE the udt-builder container (driven by the udt-build action's
# build-release.sh / udt-run): make a scratch UniData account, compile BP/CMD.*
# to objects, and stage an objects-only package — the prebuilt _objects plus the
# manifest, no source — into the directory given as $1.  MVPKG-udt installs it by
# cataloging the objects with no BASIC/compiler (LISTSRC/DOCAT detect the
# _objects).  Validated on UniData 8.3.2.  The action tars $1 as
# mvx-lang_cmd-<ver>-udt-<os>-<arch>-<endian>.tar.gz and chowns it back.
#
#   sh build-udt.sh <stagedir>
set -e
STAGE="${1:?usage: build-udt.sh <stagedir>}"
: "${UDTHOME:?UDTHOME must be set (run inside the udt-builder container)}"
SRC="$(cd "$(dirname "$0")" && pwd)"
ACCT="${ACCT:-/tmp/cmdbuild}"

# A UniData account (VOC etc.).  In the container there is no controlling
# terminal, so newacct reads its answers from stdin — feed the owner login
# ('root') and group ('unidata'), both present in the builder image, plus the
# continue confirmation.  Its transcript is echoed so a bad prompt order is
# visible in the CI log.
rm -rf "$ACCT"; mkdir -p "$ACCT"
echo "build-udt: creating a UniData account with newacct"
( cd "$ACCT" && printf 'y\nroot\nunidata\ny\ny\n' | "$UDTHOME/bin/newacct" 2>&1 ) \
  | sed 's/^/  newacct| /' || true
[ -e "$ACCT/VOC" ] || { echo "build-udt: newacct did not create a VOC (see transcript above)" >&2; exit 1; }

# Provision the shared platform header this account compiles against
# (`$INCLUDE MVPKG.INC PLATFORM.H` — the $DEFINE MV / $DEFINE UDT vendor defines).
# `MVPKG init` lays it down; mvpkg is installed in the udt-builder image.
echo "build-udt: MVPKG init (provisions MVPKG.INC/PLATFORM.H)"
( cd "$ACCT" && printf 'MVPKG init -y\nQUIT\n' | udt 2>&1 ) | sed 's/^/  mvpkg| /' | grep -iE "initialised|include:|error" || true
[ -f "$ACCT/MVPKG.INC/PLATFORM.H" ] || {
  echo "build-udt: MVPKG init did not provision MVPKG.INC/PLATFORM.H — is mvpkg installed in the builder image?" >&2; exit 1; }

# Compile EVERY program in BP/ -> BP/_CMD.* objects.  Derived from the source
# directory, never a hardcoded list: a hardcoded one silently drops a newly added
# program from the udt artifact (CMD.FLAG was missing from 1.1.0 this way, so
# `GIT` — which dispatches through it — failed with "Cannot find CMD.FLAG").
# One BASIC per program: a bulk `BASIC BP <many>` can segfault udt.
# Files only: BP/ can also hold a generated include DIRECTORY (BP/MVPKG.INC,
# written by mkpkg beside the sources), which is not a program to compile.
PROGS="$(cd "$SRC/BP" && for f in *; do [ -f "$f" ] && printf '%s ' "$f"; done)"
echo "build-udt: compiling $PROGS"
for p in $PROGS; do
  cp "$SRC/BP/$p" "$ACCT/BP/"
  ( cd "$ACCT" && printf 'BASIC BP %s\nQUIT\n' "$p" | udt )
  [ -f "$ACCT/BP/_$p" ] || { echo "build-udt: object _$p missing (compile failed)" >&2; exit 1; }
done

# Stage the objects-only package (contents at the root): prebuilt _objects +
# manifest, no source records.
mkdir -p "$STAGE/BP"
for p in $PROGS; do cp "$ACCT/BP/_$p" "$STAGE/BP/"; done
cp "$SRC/PKG" "$SRC/mvpkg.json" "$SRC/LICENSE" "$SRC/README.md" "$STAGE/"
echo "build-udt: staged the objects-only package"
