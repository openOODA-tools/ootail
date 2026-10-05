# ootail

A tail replacement, written in the openOODA language.

**Status: skeleton. Nothing works yet.**

The entry point compiles, answers `--help` and `--version`, and refuses
everything else with exit status 2. No file is followed.

## Layout

```
main.oo          argument gate; refuses unimplemented invocations
anchor.oo        the four domains and their boundaries
watch/           file and directory change events
scan/            bytes arriving into whole lines
render/          emitted lines to prefixed output
ipc/             CLI, MCP stdio, AF_UNIX socket
```

`AGENTS.md` is the real document: house laws, domain contracts, and the runtime
traps that have already cost debugging time.

## Build

```sh
make build     # compile main.oo to dist/ootail
make verify    # line-cap, file-law, academy, density, oodac check
```

Requires the `oodac` compiler. Found at `~/.openooda/bin/oodac`, falling back to
`../../openOODA/oodac/bin/oodac`. Override with `make OODA_COMPILER=/path/to/oodac`.

## Next

1. `scan/` — turn arriving bytes into whole lines. Pure, no harness needed.
   Model it on `std/net/varlink/frame.oo`: a read boundary is not a line
   boundary, and holding a trailing partial line is the whole job.
2. `watch/` — `std/core/encoding/watch.oo` wraps only `oo_sys_inotify_init`,
   which is real; its add-watch and poll paths are marked residual. Filling that
   hole is step two. Truncate handling is the part that matters: a follower that
   only seeks forward prints nothing after a rewrite.
3. `render/` — prefixing, line numbers, and colour kept off by default so IPC
   output stays clean.
4. `ipc/` — three surfaces over one follower.

## Licence

See `LICENSE`.
