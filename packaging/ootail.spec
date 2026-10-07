Name:           ootail
Version:        0.2.0
Release:        1%{?dist}
Summary:        Capability-bounded file tail and follower utility
License:        ASL 2.0
URL:            https://github.com/openOODA-tools/ootail
Source0:        ootail-linux-x86_64
Source1:        uninstall.sh
BuildArch:      x86_64
Requires:       glibc

%description
ootail is a drop-in tail replacement written in pure openOODA, featuring
line windowing (-n), byte windowing (-c), inotify-probed following (-f),
truncated file recovery, Model Context Protocol (--mcp) stdio server mode,
clean companion uninstaller, and negative-trust capability security.

%install
mkdir -p %{buildroot}/usr/bin
install -m 0755 %{SOURCE0} %{buildroot}/usr/bin/ootail
install -m 0755 %{SOURCE1} %{buildroot}/usr/bin/ootail-uninstall

%files
/usr/bin/ootail
/usr/bin/ootail-uninstall

%changelog
* Wed Oct 07 2026 openOODA-tools <ops@openooda.org> - 0.2.0-1
- Add MCP stdio server mode (--mcp) with tail_file and tail_stream tools
- Add byte windowing (-c, --bytes) with positive offset support
- Add line windowing from start offset (+NUM) and legacy flag (+NUM)
- Add sleep interval (-s) and PID tracking (--pid) for follow mode
- Comprehensive 4-tier QA suite and performance benchmarks

* Mon Oct 05 2026 openOODA-tools <ops@openooda.org> - 0.1.0-1
- Initial sovereign release: tail -n windowing, tail -f follow with inotify & truncate detection, oote theme integration, and companion uninstaller
