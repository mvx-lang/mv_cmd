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

# Objects-only package: prebuilt _objects + manifest, no source records.
DIST="$SRC/dist/$BASE"; rm -rf "$DIST"; mkdir -p "$DIST/BP"
cp "$ACCT/BP/_CMD.INIT" "$ACCT/BP/_CMD.ADD" "$ACCT/BP/_CMD.RUN" "$DIST/BP/"
cp "$SRC/PKG" "$SRC/mvpkg.json" "$SRC/LICENSE" "$SRC/README.md" "$DIST/"
# Contents at the tar root (no wrapping dir): MVPKG untars into the package dir
# and expects BP/ etc. at its root, matching the source package convention.
tar czf "$SRC/$BASE.tar.gz" -C "$DIST" .
echo "build-udt: wrote $BASE.tar.gz"
