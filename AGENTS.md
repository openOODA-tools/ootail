# ootail: House Laws & Where To Start

Status: **skeleton**. Nothing is implemented. This file is the map.

## 1. What ootail Is

A tail replacement. Show the last lines of a file, and with `--follow` keep
showing what gets appended. It must behave like `tail -f` closely enough to
replace it in a pipeline, which means the awkward cases are the whole job:

- a file that is rewritten shorter, not appended to
- a file replaced by rename, where the old descriptor is now a different file
- a partial line at EOF, which must be held, not printed and split later
- non-ASCII content, which breaks naive character indexing

## 2. The Four Domains

Work lands in exactly one domain at a time. Each anchor.oo states its contract.

| Domain | Job | Does not do |
|---|---|---|
| `watch/` | report append, truncate, and replace | read file contents |
| `scan/` | bytes arriving into whole lines | decide what to watch |
| `render/` | lines to prefixed output | split or buffer lines |
| `ipc/` | CLI, MCP stdio, AF_UNIX socket | reimplement line assembly |

Suggested order: `scan/` (pure, testable with no harness), then `watch/`, then
`render/`, then `ipc/`.

## 3. The Page Rule

Every `.oo` and `.oot` page is 16 to 256 lines. A shim — a file whose every
non-comment line is an import — skips the 16-line floor but never the ceiling.

At most 8 pages per directory, counting tests.

Never name a page `util.oo`, `utils.oo`, `helper.oo`, `helpers.oo`,
`common.oo`, `misc.oo`, `shared.oo`, `base.oo`, or `core.oo`. Use a verb:
`watch_poll.oo`, `scan_take_line.oo`, `render_line.oo`.

Imports are relative string literals. There are no `::` namespaces.

## 4. The 4-Element Academy Header

Mandatory on every page, all four elements within the first 7 lines. The gate
enforces this, so a Setup paragraph that runs long will push `Beats:` out and
fail the build.

## 5. Capability Discipline

Zero ambient authority. Every function that touches the outside world takes the
explicit token it needs: `FsReadCap`, `FsWriteCap`, `BindCap`, `ProcessCap`.

Never `/bin/sh -c`. Use an explicit argv array. No shell, no PATH lookup.

Every file descriptor is opened `O_CLOEXEC`.

Validation is negative-trust and fails closed. Double-run determinism is
required.

`process_exit` is classified under `ProcessCap`. `main`'s return value does NOT
set exit status, so a non-zero status must be raised explicitly.

## 6. Runtime Traps Already Found

- `str_index_of` returns **byte** offsets while `str_slice` and `char_at` are
  **character** indexed. Mixing them truncates silently on non-ASCII input. Use
  `byte_get` and `byte_sub` together, or nothing. This one bit oogrep: every
  match was silently lost on files containing emoji.
- `char_at` is O(index); character-by-character scanning is quadratic.
- A `"\0"` literal compiles to an empty string, and `"\033["` emits no escape.
  Build such bytes explicitly, e.g. with `bytes_to_str(bytes_push(bytes_new(), 27))`.
- `byte_concat` cannot lower. `str_concat` fails at check. Use `+`.
- `oo_read_stdin_chunk` in oodar shows the three-state read pattern: data, timed
  out, and peer gone are three distinct outcomes, not two. Follow it.
- `parse_int` is a std builtin at arity 1. Avoid the name.

## 7. Verification Gate

```
make verify
```

Runs `line-cap`, `file-law`, `academy`, `density`, then `oodac check` on every
page. All five must pass. There is no `test` target yet; add one when following
produces observable output.
