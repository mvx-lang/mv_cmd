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

# Compile the three programs -> BP/_CMD.* objects.
cp "$SRC/BP/CMD.INIT" "$SRC/BP/CMD.ADD" "$SRC/BP/CMD.RUN" "$ACCT/BP/"
( cd "$ACCT" && printf 'BASIC BP CMD.INIT CMD.ADD CMD.RUN\nQUIT\n' | udt )
for o in _CMD.INIT _CMD.ADD _CMD.RUN; do
  [ -f "$ACCT/BP/$o" ] || { echo "build-udt: object $o missing (compile failed)" >&2; exit 1; }
done

# Stage the objects-only package (contents at the root): prebuilt _objects +
# manifest, no source records.
mkdir -p "$STAGE/BP"
cp "$ACCT/BP/_CMD.INIT" "$ACCT/BP/_CMD.ADD" "$ACCT/BP/_CMD.RUN" "$STAGE/BP/"
cp "$SRC/PKG" "$SRC/mvpkg.json" "$SRC/LICENSE" "$SRC/README.md" "$STAGE/"
echo "build-udt: staged the objects-only package"
