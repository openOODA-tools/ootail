# ootail: House Laws & Agent Engineering Standards (v1)

This document is the **single canonical source of truth** for all code, architecture, and system integration standards across `ootail`. Every human contributor and AI agent must strictly follow these rules without exception.

---

## 1. The Page Rule (Code Layout & Sizing)

A **page** is one committed `.oo` or `.oot` file. Every page holds one idea, fits in one head, and carries its own weight. This rule is enforced by automated verification under `make verify`: red pages fail the build.

### Hard Sizing Invariants
- **16–256 Lines**: Every committed source file must be between **16 and 256 lines**, counted as exact line breaks (blank lines and comments count).
- **Shim Exemption (Floor Only)**: A file is a shim when every non-comment line is an import or re-export (`import "..."`). Shims skip the 16-line floor. The **256-line ceiling still strictly applies**.
- **Directory Density ($\le 8$ files)**: At most **8 `.oo` files per directory**, tests included. Crowded directories must split into functional subdirectories grouped by domain.
- **Banned File Names (Name the function, not the drawer)**:
  `util.oo`, `utils.oo`, `helper.oo`, `helpers.oo`, `common.oo`, `misc.oo`, `shared.oo`, `base.oo`, `core.oo`.

### Splitting, Folding, and Naming
- **Over 256 lines**: Split along functional boundaries into a new subdirectory with an `anchor.oo` shim. One page = one verb or one wholly owned noun.
- **Under 16 lines (and not a shim)**: Fold into its closest sibling or caller. Never pad lines with artificial whitespace or comments to reach 16.
- **Action pages lead with a verb**: `scan_window.oo`, `watch_poll.oo`, `render_line.oo`.
- **State pages name what they own**: `tail_opts.oo`, `watch_state.oo`.
- **Boundary pages speak trust verbs**: `verify_token.oo`, `admit_file.oo`, `enforce_quota.oo`.

---

## 2. The 4-Element Academy Header (Mandatory on Every Page)

Every committed `.oo` file must begin with the standard 4-element Academy docstring within its first 7 lines:

```oo
// # Component Name - Subtitle
//
// Logline: Single-sentence imperative summary of functional responsibility.
//
// Setup: Preconditions, wired capability tokens, imported contracts.
//
// Beats:
//   1. First sequential phase of execution.
//   2. Next phase.
//   3. Final phase / exit state.
```

- **ASD-STE100 Compliance**: Clear, concise English. No filler or ambiguous verbs.
- **Imports**: All imports must be relative string literals (e.g. `import "render/render_line.oo";`). Never use `::` namespaces.

---

## 3. openOODA Capability & Zero-Trust Discipline

`ootail` operates strictly on the Object-Capability (OCap) security model:

### Unforgeable Capability Tokens
- **Zero Ambient Authority**: Privileged operations (reading files, inotify kernel probes, environment access) require explicit, unforgeable capability tokens passed as arguments (`&FsReadCap`, `&SysCap`, `&TimeCap`, `&EnvCap`).
- **Read-Only by Construction**: Streaming logs requires zero write access or network egress. Absence of `&FsWriteCap` and `&NetCap` in `main` is an architectural guarantee.
- **Subprocess Safety**: Never invoke `/bin/sh -c` or `/bin/bash -c`. Direct binary execution must use explicit argv arrays via `ProcessCap`. Clean environment variables of child processes.
- **Truncate & Replay Safety**: Detect file replacements and truncations via inotify / file size polling; reset read offsets deterministically without losing data.

---

## 4. Unified Theming with `oote`

All openOODA tools synchronize visual presentation through `oote`:

- **Theme Resolver**: `ootail` formats log level badges (`log_trace`, `log_debug`, `log_info`, `log_warn`, `log_error`) directly from `~/.openooda/theme.oot` or respects `OODA_THEME`, `OODA_MODE`, and `OODA_BORDER`.
- **Graceful Capability Degradation**: Automatically emits 24-bit TrueColor, degrades to 256 or 16-color ANSI, and suppresses all ANSI escapes under `NO_COLOR`, `OODA_NO_COLOR`, or `TERM=dumb`.

---

## 5. Native systemd Citizenship & Linux Integration

This server follows a pure systemd-native architectural pattern:

1. **System Services & Unit Placement**: Services managed in `/etc/systemd/system/`. Prefer drop-in overrides (`/etc/systemd/system/<unit>.service.d/*.conf`).
2. **Declarative State & Provisioning**: Accounts declared via `systemd-sysusers` in `/etc/sysusers.d/*.conf`; directory lifecycle via `systemd-tmpfiles` in `/etc/tmpfiles.d/*.conf`.
3. **Service Confinement & Hardening**: Use native sandboxing (`ProtectSystem=`, `ProtectHome=`, `PrivateTmp=`, `NoNewPrivileges=`).
4. **Logging & Schedulers**: Logging handled exclusively by `systemd-journald`. Scheduled tasks executed via `systemd.timer` units rather than legacy cron.
5. **Standard System Directories**: Use `$RUNTIME_DIRECTORY` (`/run/openooda`), `$STATE_DIRECTORY` (`/var/lib/openooda`), `$CONFIGURATION_DIRECTORY` (`/etc/openooda`).
6. **Exit Code Contract**: Strict tail parity:
   - `0`: Successful completion or clean termination on `SIGINT`.
   - `1`: File not found, permission denied, or general runtime failure.

---

## 6. Domain Architecture & Responsibilities

Work lands in exactly one domain at a time:

| Domain | Responsibility | Does NOT Do |
|---|---|---|
| `scan/` | Byte streaming, line windowing, CRLF normalization, non-ASCII boundary checks | Inotify watch or file polling |
| `watch/` | File change observation, inotify events under `&SysCap`, append/truncate triggers | Line parsing or rendering |
| `render/` | Multi-file header banners, log level semantic color formatting | File watching or windowing |
| `ipc/` | CLI options, MCP stdio server (`tail_stream`) | Reimplement line assembly |

---

## 7. Verification & QA Gate

Before any commit or release is certified, the entire codebase must pass the automated verification gate:

1. **`make line-cap`**: Hard verification that 100% of `.oo` and `.oot` files are between 16 and 256 lines (shims exempt).
2. **`make file-law`**: Verification that no forbidden file extensions or stray documents are committed.
3. **`make academy`**: Verification that every source file contains the complete 4-element Academy header in its first 7 lines.
4. **`make density`**: Verification that no directory holds more than 8 pages.
5. **`make check`**: Full syntax and semantic verification via `oodac check` across every `.oo` page.
6. **`make verify`**: Orchestrates all verification checks. Red pages fail the build.
7. **`make test`**: Line windowing tests, inotify follow tests, and truncate detection suites.
8. **Double-Run Determinism**: All verification runs execute twice sequentially in fresh processes ($Run_1 == Run_2$).
