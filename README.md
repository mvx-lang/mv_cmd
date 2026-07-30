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

`CMD.RUN` parses `SENTENCE()`, dispatches to the handler subroutine (via the
indirect `CALL @VAR`), and generates help for the `help`, no-argument, and
unknown-command cases.

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
MVPKG install mv-lang/cmd
```

`cmd` is pure BASIC — no native code, no dependencies — so it installs on any
MVX account as-is.

## Layout

`BP/` — the framework (`CMD.INIT`, `CMD.ADD`, `CMD.RUN`); `PKG` + `mvpkg.json`
— the package manifest. Records are stored as directory files so the repo is
itself a legible MVX package account.

## Licence

GPL-2.0-only. See [LICENSE](LICENSE).
