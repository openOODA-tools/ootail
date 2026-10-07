# ootail

> **Capability-bounded file tail and follower utility for the openOODA era.**  
> *A drop-in `tail` replacement written in pure openOODA, featuring line windowing, inotify-probed following, truncated file recovery, and negative-trust capability security.*

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
sudo dpkg -i ootail_0.1.0-1_amd64.deb
```

### Fedora / RHEL / CentOS (DNF)
```bash
# Automated via installer
curl -fsSL https://openooda-tools.github.io/ootail/install.sh | bash -s -- --dnf

# Or manual RPM install
sudo dnf install ./ootail-0.1.0-1.x86_64.rpm
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
  -n, --lines=[+]NUM   output the last NUM lines, instead of the last 10
  -f, --follow         output appended data as the file grows
  -F                   same as --follow --retry
  -q, --quiet          never output headers giving file names
  -v, --verbose        always output headers giving file names
      --color          colorize log output levels with active theme
      --no-color       disable color formatting
  -h, --help           display this help and exit
  -V, --version        output version information and exit
```

### Common Examples

```bash
# View the last 20 lines of a file
ootail -n 20 /var/log/syslog

# Follow logs in real time (with inotify and truncate detection)
ootail -f app.log

# Stream from standard input
journalctl -u systemd-journald | ootail -n 5

# Follow multiple files simultaneously
ootail -f /var/log/auth.log /var/log/syslog
```

---

## 3. Architecture & Domains

```
main.oo          CLI entry point, option dispatch, and follow execution
tail_opts.oo     Typed command line argument parser
scan/            Byte streaming, CRLF stripping, and line windowing
watch/           Inotify probe under &SysCap, file change polling, and append reading
render/          Log level semantic color formatting and file headers
ipc/             Model Context Protocol and socket surfaces
```

---

## 4. Build & Verify

```bash
make verify    # line-cap, file-law, academy, density, oodac check
make build     # compile main.oo to dist/ootail
make test      # run functional test suite
make package   # build .deb, .rpm, and validate PKGBUILD
```

---

## 5. Licence

See `LICENSE`.
