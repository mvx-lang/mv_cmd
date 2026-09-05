#!/bin/sh
# mv_cmd — stage the cmd SOURCE package into $1, for the uv and jbase artifacts.
# Copyright (C) 2026 Gordon Heydon.  GPL-2.0-only (see LICENSE).
#
#   sh build-pkg.sh <stagedir>
#
# SOURCE, where the UniData artifact ships prebuilt OBJECTS -- and the difference
# is the platforms, not a shortcut.
#
# build-udt.sh compiles BP/CMD.* to BP/_CMD.* and ships those alone, so MVPKG-udt
# installs by cataloging objects and never needs the compiler.  That works
# because UniData's object for a program is a FILE beside it.  jBASE's is not:
# cataloging there aggregates programs into a per-account shared library
# ($HOME/lib/lib0.so), so there is no per-program object to lift out and nothing
# portable to stage -- shipping one account's lib0.so to another account is not
# the same thing at all.
#
# So uv and jbase take the source and MVPKG catalogs it on the target.  Both
# ship a BASIC compiler as standard, so the only cost is a compile at install
# time.  `<sys>-any-any-le` accordingly: nothing here is compiled, so there is
# nothing to lock to an os or arch.
set -e
STAGE="${1:?usage: build-pkg.sh <stagedir>}"
SRC="$(cd "$(dirname "$0")" && pwd)"
ACCT="$STAGE/cmd"

mkdir -p "$ACCT/BP"
# Derived from the directory, never a hardcoded list: a hardcoded one silently
# drops a newly added program, which is how CMD.FLAG went missing from the 1.1.0
# udt artifact and `GIT` failed with "Cannot find CMD.FLAG".
for f in "$SRC"/BP/*; do
   if [ -f "$f" ]; then cp "$f" "$ACCT/BP/"; fi
done
if [ -d "$SRC/BP.DICT" ]; then
   mkdir -p "$ACCT/BP.DICT"; cp "$SRC"/BP.DICT/* "$ACCT/BP.DICT/"
fi
for f in PKG mvpkg.json LICENSE README.md .mv-account; do
   if [ -f "$SRC/$f" ]; then cp "$SRC/$f" "$ACCT/"; fi
done
echo "build-pkg: staged cmd (source) as $ACCT/"
