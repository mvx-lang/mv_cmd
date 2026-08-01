# mv_cmd — a command framework for MultiValue

`mv_cmd` is a small **Cobra-style command framework** for MultiValue BASIC. A
verb declares its subcommands and their handlers, and the framework parses the
sentence, dispatches to the right handler, and generates help — so a verb with
subcommands is a few lines plus one small handler per subcommand.

```basic
CALL CMD.INIT("GIT", "work with the account's git repository")
CALL CMD.ADD("STATUS", "working tree status", "GIT.STATUS")
CALL CMD.ADD("LOG",    "recent history",      "GIT.LOG")
CALL CMD.RUN
```

`CMD.RUN` parses the current sentence, dispatches to the handler subroutine
(via the indirect `CALL @VAR`), and generates help for the `help`,
no-argument, and unknown-command cases.

## API

- `CMD.INIT(name, description)` — begin defining a command.
- `CMD.ADD(subcommand, description, handler)` — register a subcommand and the
  subroutine that handles it.
- `CMD.RUN` — parse the sentence and dispatch (or print generated help).

State is carried in the `/CMDPKG/` common block between the three calls.

## Consumers

[`mv_git`](https://github.com/mvx-lang/mv_git) is the reference consumer — its
`GIT` verb builds its subcommands on `cmd`. It ships a cut-down copy so it runs
standalone, and prefers this package when it is installed. The `mv_package`
client (`MVPKG`) also builds its CLI on `cmd`.

## Install

```sh
MVPKG install mvx-lang/cmd
```

`cmd` is pure BASIC with no dependencies, and runs on both **MVX** and Rocket
**UniData** from one source (see below). `MVPKG install` works on either host —
it fetches the prebuilt binary for your system where one is published (the MVX
subroutine library, or the UniData objects, cataloged with no compiler), and
otherwise installs the source and compiles it on install.

## UniData

The same source runs on UniData — there is one copy of each program, not a
separate port. The two host differences — the current sentence (`SENTENCE()`
vs `@SENTENCE`) and the `FMT` justification mask (`L#12` vs `12L`) — are
selected at compile time with `$IFDEF MVX`: the MVX compiler defines the `MVX`
symbol and UniData does not, so each host compiles its own form. (The `$IFDEF`
branches whole statements rather than defining macros — UniData's `$DEFINE`
does not substitute values the way MVX's does.)

`MVPKG install mvx-lang/cmd` installs it on UniData too. Without the package
client, install by hand — copy `BP/CMD.*` into your account's `BP`, then:

```
BASIC BP CMD.INIT CMD.ADD CMD.RUN
CATALOG BP CMD.INIT CMD.ADD CMD.RUN
```

A verb then builds its subcommands exactly as shown at the top.

## Layout

`BP/` — the framework (`CMD.INIT`, `CMD.ADD`, `CMD.RUN`), one cross-platform
source per program; `PKG` + `mvpkg.json` — the package manifest. The account
is an **open account** (the same legible, directory-file format `mv_git` uses):
records are plain files, `%FILE%` carries the portable type, and the runtime
`mvxdata.lmdb` is a build artifact (git-ignored), so the repo is itself a
legible, cross-platform MV package account.

## Licence

GPL-2.0-only. See [LICENSE](LICENSE).
