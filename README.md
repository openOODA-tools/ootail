# ootail

> **Capability-bounded file tail and follower utility for the openOODA era.**  
> *A drop-in `tail` replacement written in pure openOODA, featuring line windowing, byte windowing, inotify-probed following, truncated file recovery, native Model Context Protocol (MCP) stdio server mode, and negative-trust capability security.*

Part of [openOODA-tools](https://github.com/openOODA-tools).

---

## 1. Installation

`ootail` has zero runtime dependencies. It compiles to a standalone native binary linked directly with libc.

### Universal Web Installer
Installs the standalone native binary to `/usr/local/bin` (or `~/.local/bin`):

```bash
curl -fsSL https://openooda-tools.github.io/ootail/install.sh | bash
```

### Debian / Ubuntu (APT)
```bash
# Automated via installer
curl -fsSL https://openooda-tools.github.io/ootail/install.sh | bash -s -- --apt

# Or manual package install
sudo dpkg -i ootail_0.2.0-1_amd64.deb
```

### Fedora / RHEL / CentOS (DNF)
```bash
# Automated via installer
curl -fsSL https://openooda-tools.github.io/ootail/install.sh | bash -s -- --dnf

# Or manual RPM install
sudo dnf install ./ootail-0.2.0-1.x86_64.rpm
```

### Arch Linux (PKGBUILD)
```bash
# Automated via installer
curl -fsSL https://openooda-tools.github.io/ootail/install.sh | bash -s -- --arch

# Or manual build via packaging/PKGBUILD
cd packaging && makepkg -si
```

### Clean Uninstaller
To cleanly remove `ootail` and any installed package manager entries:

```bash
# Automated via standalone uninstaller
curl -fsSL https://openooda-tools.github.io/ootail/uninstall.sh | bash

# Or via installer flag
curl -fsSL https://openooda-tools.github.io/ootail/install.sh | bash -s -- --uninstall

# Or preview removal without making changes (dry-run)
curl -fsSL https://openooda-tools.github.io/ootail/uninstall.sh | bash -s -- --dry-run
```

---

## 2. CLI Usage

```
usage: ootail [options] [FILE]...

Print the last 10 lines of each FILE to standard output.
With more than one FILE, precede each with a header giving the file name.
With no FILE, or when FILE is -, read standard input.

Options:
  -n, --lines=[+]NUM       output the last NUM lines, or from line NUM with +
  -c, --bytes=[+]NUM       output the last NUM bytes, or from byte NUM with +
  -f, --follow             output appended data as the file grows
  -F                       same as --follow --retry
  -s, --sleep-interval=S   with -f, sleep for S seconds (default: 0.1)
      --pid=PID            with -f, terminate after process PID dies
      --mcp                run Model Context Protocol server over stdio
  -q, --quiet              never output headers giving file names
  -v, --verbose            always output headers giving file names
      --color              colorize log output levels with active theme
      --no-color           disable color formatting
  -h, --help               display this help and exit
  -V, --version            output version information and exit
```

### Common Examples

```bash
# View the last 20 lines of a file
ootail -n 20 /var/log/syslog

# View lines starting from line 100 to the end
ootail -n +100 app.log

# View the last 512 bytes of a file
ootail -c 512 /var/log/auth.log

# Follow logs in real time (with inotify and truncate detection)
ootail -f app.log

# Stream from systemd journald natively
journalctl -u systemd-journald | ootail -n 5

# Follow multiple files simultaneously
ootail -f /var/log/auth.log /var/log/syslog
```

---

## 3. Model Context Protocol (MCP) Mode

`ootail` includes a native Model Context Protocol (MCP) server over standard I/O (JSON-RPC 2.0, protocol version `2024-11-05`), designed for agentic AI coding harnesses (such as Google Antigravity, Claude Desktop, and Cursor).

Run the server with:
```bash
ootail --mcp
```

### Available MCP Tools

1. **`tail_file`**: Read trailing lines or bytes from a target file.
   - `path` (string, required): Target file path.
   - `lines` (integer): Trailing line count (default: 10).
   - `bytes` (integer): Trailing byte count (0 disables byte mode).
   - `from_start` (boolean): Start from line/byte offset instead of tail.

2. **`tail_stream`**: Window lines or bytes from an in-memory string payload.
   - `content` (string, required): Log text content.
   - `lines` (integer): Trailing line count (default: 10).
   - `bytes` (integer): Trailing byte count.
   - `from_start` (boolean): Start from offset instead of tail.

---

## 4. Architecture & Domains

```
main.oo          CLI entry point, option dispatch, and follow execution
tail_opts.oo     Typed command line argument parser
scan/            Byte streaming, CRLF stripping, and line windowing
watch/           Inotify probe under &SysCap, file change polling, and append reading
render/          Log level semantic color formatting and file headers
ipc/             Model Context Protocol (JSON-RPC 2.0 stdio server)
qa/              Comprehensive 4-tier QA verification suites (.oot)
```

---

## 5. Build, Verify & Test

```bash
make verify    # line-cap, file-law, academy, density, oodac check
make build     # compile main.oo to dist/ootail
make test      # run full 4-tier QA suite
make bench     # run performance benchmark suite
make package   # build .deb, .rpm, and validate PKGBUILD
```

---

## 6. Licence

See `LICENSE`.
