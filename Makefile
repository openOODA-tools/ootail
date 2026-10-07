# ootail Makefile
#
# Usage:
#   make build       - compile main.oo to dist/ootail
#   make check       - run oodac check on every .oo file
#   make line-cap    - enforce 16-256 line cap on every .oo and .oot (shim-exempt)
#   make file-law    - reject forbidden file extensions and stray docs
#   make academy     - verify every .oo has the 4-element Academy header
#   make density     - enforce at most 8 pages per directory
#   make verify      - run line-cap, file-law, academy, density, and check
#   make test        - run functional test suite
#   make bench       - run performance benchmarks
#   make package-deb - generate Debian (.deb) package
#   make package-rpm - generate RedHat/Fedora (.rpm) package
#   make package-arch- generate Arch Linux (.pkg.tar.zst) package
#   make package     - build all distribution packages
#   make clean       - remove build artifacts

OODA_COMPILER ?= $(firstword $(wildcard $(HOME)/.openooda/bin/oodac $(CURDIR)/../../openOODA/oodac/bin/oodac))
OODACODEX ?= $(HOME)/.openooda/northstar.oot
OO_LIST_AMBIENT_QUOTA ?= 8589934592
BIN := dist/ootail
VERSION ?= 0.2.0
PREFIX ?= $(HOME)/.openooda/bin

SRC := $(wildcard *.oo) $(wildcard */*.oo)

.PHONY: all build check line-cap file-law academy density verify test bench install uninstall package package-deb package-rpm package-arch clean

all: verify build test

build: $(BIN)

$(BIN): $(SRC)
	@mkdir -p dist .ooda-cache/ooda-tmp
	OO_LIST_AMBIENT_QUOTA=$(OO_LIST_AMBIENT_QUOTA) OODACODEX=$(OODACODEX) OODA_COMPILER=$(OODA_COMPILER) OODA_NO_JAIL=1 $(OODA_COMPILER) build main.oo -o $(BIN)
	@chmod +x $(BIN)
	@echo "built $(BIN)"

test: $(BIN)
	@echo "=== Tier 1: Core CLI & Windowing ==="
	@./$(BIN) --help > /dev/null && echo "PASS: --help"
	@./$(BIN) --version | grep -q "0.2.0" && echo "PASS: --version banner"
	@test "$$(./$(BIN) qa/fixtures/twenty.txt | wc -l)" = "10" && echo "PASS: default emits 10 lines"
	@test "$$(./$(BIN) -n 5 qa/fixtures/twenty.txt | wc -l)" = "5" && echo "PASS: -n 5 emits 5 lines"
	@test "$$(./$(BIN) -n 5 qa/fixtures/twenty.txt | head -n 1)" = "16" && echo "PASS: -n 5 starts at 16"
	@test "$$(./$(BIN) -n +16 qa/fixtures/twenty.txt | head -n 1)" = "16" && echo "PASS: -n +16 starts at 16"
	@test "$$(./$(BIN) -3 qa/fixtures/twenty.txt | wc -l)" = "3" && echo "PASS: -3 emits 3 lines"
	@test "$$(./$(BIN) +16 qa/fixtures/twenty.txt | head -n 1)" = "16" && echo "PASS: +16 legacy starts at 16"
	@test "$$(./$(BIN) -c 5 qa/fixtures/single.txt)" = "line" && echo "PASS: -c 5 emits trailing 5 bytes"
	@test "$$(./$(BIN) -c +10 qa/fixtures/single.txt)" = "line" && echo "PASS: -c +10 emits from byte 10"
	@test "$$(printf 'a\nb\nc\nd\n' | ./$(BIN) -n 2)" = "$$(printf 'c\nd')" && echo "PASS: stdin -n 2 works"
	@test "$$(printf 'abcdef' | ./$(BIN) -c 3)" = "def" && echo "PASS: stdin -c 3 works"
	@test "$$(printf '1\n2\n3\n4\n5\n' | ./$(BIN) -n +3)" = "$$(printf '3\n4\n5')" && echo "PASS: stdin -n +3 works"
	@echo "=== Tier 2: Boundary & Negative Trust ==="
	@./$(BIN) --invalid-xyz > /dev/null 2>&1; test $$? -eq 2 && echo "PASS: invalid flag exits 2"
	@./$(BIN) -n > /dev/null 2>&1; test $$? -eq 2 && echo "PASS: missing -n arg exits 2"
	@./$(BIN) -c > /dev/null 2>&1; test $$? -eq 2 && echo "PASS: missing -c arg exits 2"
	@./$(BIN) /nonexistent/file/path/xyz > /dev/null 2>&1; test $$? -eq 1 && echo "PASS: missing file exits 1"
	@test -z "$$(./$(BIN) qa/fixtures/empty.txt)" && echo "PASS: empty file emits nothing"
	@test -z "$$(./$(BIN) -n 0 qa/fixtures/twenty.txt)" && echo "PASS: -n 0 emits nothing"
	@test -z "$$(./$(BIN) -c 0 qa/fixtures/twenty.txt)" && echo "PASS: -c 0 emits nothing"
	@test "$$(./$(BIN) -n 50 qa/fixtures/single.txt)" = "only one line" && echo "PASS: count exceeding lines emits whole file"
	@test "$$(./$(BIN) qa/fixtures/no_nl.txt)" = "unfinished line without newline" && test "$$(./$(BIN) qa/fixtures/no_nl.txt | wc -l)" = "0" && echo "PASS: file without trailing newline"
	@test "$$(./$(BIN) qa/fixtures/crlf.txt | head -n 1)" = "line1" && echo "PASS: CRLF stripped cleanly"
	@test "$$(./$(BIN) -n +1 qa/fixtures/twenty.txt | head -n 1)" = "1" && echo "PASS: -n +1 starts at 1"
	@test -z "$$(./$(BIN) -n +50 qa/fixtures/twenty.txt)" && echo "PASS: -n +50 beyond EOF emits empty"
	@test -z "$$(./$(BIN) -c +500 qa/fixtures/twenty.txt)" && echo "PASS: -c +500 beyond EOF emits empty"
	@test "$$( (printf 'line1\n'; sleep 0.15; printf 'line2\n') | ./$(BIN) -n 2 )" = "$$(printf 'line1\nline2')" && echo "PASS: stdin stream idle delay does not truncate"
	@echo "=== Tier 3: Combinations & Formatting ==="
	@./$(BIN) qa/fixtures/single.txt qa/fixtures/twenty.txt | grep -q "==> qa/fixtures/single.txt <==" && echo "PASS: multi-file header 1"
	@./$(BIN) qa/fixtures/single.txt qa/fixtures/twenty.txt | grep -q "==> qa/fixtures/twenty.txt <==" && echo "PASS: multi-file header 2"
	@test "$$(./$(BIN) -q qa/fixtures/single.txt qa/fixtures/twenty.txt | grep -c '==>')" = "0" && echo "PASS: -q suppresses headers"
	@./$(BIN) -v qa/fixtures/single.txt | grep -q "==> qa/fixtures/single.txt <==" && echo "PASS: -v shows header for single file"
	@./$(BIN) --color qa/fixtures/alpha.log | grep -q "$$(printf '\033')" && echo "PASS: --color injects ANSI escapes"
	@test -z "$$(./$(BIN) --no-color qa/fixtures/alpha.log | grep "$$(printf '\033')")" && echo "PASS: --no-color suppresses ANSI escapes"
	@test "$$(./$(BIN) --lines=3 qa/fixtures/twenty.txt | wc -l)" = "3" && echo "PASS: --lines=3 long form"
	@test "$$(./$(BIN) --bytes=4 qa/fixtures/single.txt)" = "ine" && echo "PASS: --bytes=4 long form"
	@test "$$(./$(BIN) -- qa/fixtures/single.txt)" = "only one line" && echo "PASS: -- double dash flag terminator"
	@OODA_TAIL_CYCLES=1 ./$(BIN) -s 0.2 -f qa/fixtures/single.txt > /dev/null && echo "PASS: -s 0.2 fractional sleep interval"
	@test "$$(OODA_TAIL_CYCLES=5 ./$(BIN) --pid=999999 -f qa/fixtures/single.txt)" = "only one line" && echo "PASS: --pid exits when PID dies"
	@echo "=== Tier 4: MCP Protocol & Live Streaming ==="
	@printf '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}\n' | ./$(BIN) --mcp | grep -q "2024-11-05" && echo "PASS: MCP initialize"
	@printf '{"jsonrpc":"2.0","id":2,"method":"ping","params":{}}\n' | ./$(BIN) --mcp | grep -q '"result":{}' && echo "PASS: MCP ping"
	@printf '{"jsonrpc":"2.0","id":3,"method":"tools/list","params":{}}\n' | ./$(BIN) --mcp | grep -q "tail_file" && echo "PASS: MCP tools/list tail_file"
	@printf '{"jsonrpc":"2.0","id":4,"method":"tools/list","params":{}}\n' | ./$(BIN) --mcp | grep -q "tail_stream" && echo "PASS: MCP tools/list tail_stream"
	@printf '{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"tail_file","arguments":{"path":"qa/fixtures/twenty.txt","lines":3}}}\n' | ./$(BIN) --mcp | grep -q "18\\\n19\\\n20" && echo "PASS: MCP tools/call tail_file lines"
	@printf '{"jsonrpc":"2.0","id":6,"method":"tools/call","params":{"name":"tail_stream","arguments":{"content":"first\\nsecond\\nthird\\nfourth","lines":2}}}\n' | ./$(BIN) --mcp | grep -q "third\\\nfourth" && echo "PASS: MCP tools/call tail_stream lines"
	@printf '{"jsonrpc":"2.0","id":7,"method":"tools/call","params":{"name":"nonexistent_tool","arguments":{}}}\n' | ./$(BIN) --mcp | grep -q -- "-32601" && echo "PASS: MCP unknown tool exits -32601"
	@printf '{"jsonrpc":"2.0","id":8,"method":"tools/call","params":{"name":"tail_file","arguments":{"path":"/nonexistent/bad/path"}}}\n' | ./$(BIN) --mcp | grep -q -- "-32602" && echo "PASS: MCP missing path exits -32602"
	@test -z "$$(printf '{"jsonrpc":"2.0","method":"notifications/initialized","params":{}}\n' | ./$(BIN) --mcp)" && echo "PASS: MCP notifications/initialized produces no response"
	@printf '{"jsonrpc":"2.0","id":9,"method":"shutdown","params":{}}\n' | ./$(BIN) --mcp | grep -q '"result":null' && echo "PASS: MCP shutdown"
	@test -z "$$(printf '{"jsonrpc":"2.0","method":"exit","params":{}}\n' | ./$(BIN) --mcp)" && echo "PASS: MCP exit terminates cleanly"
	@(sleep 0.2 && printf '{"jsonrpc":"2.0","id":10,"method":"ping","params":{}}\n') | ./$(BIN) --mcp | grep -q '"result":{}' && echo "PASS: MCP stdio idle pause does not crash server"
	@printf '{"id":"method","method":"ping","params":{}}\n' | ./$(BIN) --mcp | grep -q '"id":"method"' && echo "PASS: MCP string value matching key name parses correctly"
	@printf '{"jsonrpc":"2.0","id":11,"method":"tools/call","params":{"name":"tail_file","arguments":{"path":"qa/fixtures/single.txt","bytes":5}}}\n' | ./$(BIN) --mcp | grep -q "line" && echo "PASS: MCP tools/call tail_file bytes"
	@printf "init1\ninit2\n" > .tf.txt
	@(sleep 0.1 && printf "app1\n" >> .tf.txt) & \
	out="$$(OODA_TAIL_CYCLES=3 ./$(BIN) -n 1 -f .tf.txt)"; \
	wait; \
	echo "$$out" | grep -q "app1" && echo "PASS: -f follows appended data"
	@printf "line1\nline2\n" > .tf.txt
	@(sleep 0.1 && printf "trunc1\n" > .tf.txt) & \
	out="$$(OODA_TAIL_CYCLES=3 ./$(BIN) -n 1 -f .tf.txt)"; \
	wait; \
	echo "$$out" | grep -q "file truncated" && echo "$$out" | grep -q "trunc1" && echo "PASS: -f detects truncate and recovers"
	@rm -f .tf.txt
	@echo "=== Determinism Probe ==="
	@run1="$$(./$(BIN) -n 5 qa/fixtures/twenty.txt)"; \
	run2="$$(./$(BIN) -n 5 qa/fixtures/twenty.txt)"; \
	test "$$run1" = "$$run2" && echo "PASS: determinism Run_1 == Run_2"
	@echo "=== Packaging & Installer Smoke Tests ==="
	@./install.sh --dry-run > /dev/null && echo "PASS: install.sh --dry-run"
	@./install.sh --uninstall --dry-run > /dev/null && echo "PASS: install.sh --uninstall --dry-run"
	@./uninstall.sh --dry-run > /dev/null && echo "PASS: uninstall.sh --dry-run"
	@echo "ALL TESTS PASSED"

bench: $(BIN)
	@echo "=== Running ootail performance benchmarks ==="
	@mkdir -p .ooda-cache
	@seq 1 100000 > .ooda-cache/bench_100k.txt
	@echo "--- 100,000 lines: tail -n 10 ---"
	@time -p ./$(BIN) -n 10 .ooda-cache/bench_100k.txt > /dev/null
	@echo "--- 100,000 lines: tail -c 1000 ---"
	@time -p ./$(BIN) -c 1000 .ooda-cache/bench_100k.txt > /dev/null
	@echo "--- 100,000 lines stdin pipe: tail -n 50 ---"
	@time -p cat .ooda-cache/bench_100k.txt | ./$(BIN) -n 50 > /dev/null
	@rm -f .ooda-cache/bench_100k.txt
	@echo "Benchmark complete."

package-deb: $(BIN)
	@mkdir -p dist/deb-root/DEBIAN dist/deb-root/usr/bin
	@sed "s/^Version:.*/Version: $(VERSION)-1/" packaging/debian/control.binary > dist/deb-root/DEBIAN/control
	@cp $(BIN) dist/deb-root/usr/bin/ootail
	@chmod 0755 dist/deb-root/usr/bin/ootail
	@cp uninstall.sh dist/deb-root/usr/bin/ootail-uninstall
	@chmod 0755 dist/deb-root/usr/bin/ootail-uninstall
	@dpkg-deb --build --root-owner-group dist/deb-root dist/ootail_$(VERSION)-1_amd64.deb
	@rm -rf dist/deb-root
	@echo "built dist/ootail_$(VERSION)-1_amd64.deb"

package-rpm: $(BIN)
	@mkdir -p ~/rpmbuild/SOURCES ~/rpmbuild/SPECS ~/rpmbuild/RPMS
	@cp $(BIN) ~/rpmbuild/SOURCES/ootail-linux-x86_64
	@cp uninstall.sh ~/rpmbuild/SOURCES/uninstall.sh
	@sed "s/^Version:.*/Version: $(VERSION)/" packaging/ootail.spec > ~/rpmbuild/SPECS/ootail.spec
	@rpmbuild -bb ~/rpmbuild/SPECS/ootail.spec
	@cp ~/rpmbuild/RPMS/x86_64/ootail-$(VERSION)*.rpm dist/
	@echo "built dist RPM package"

install: $(BIN)
	@mkdir -p $(PREFIX)
	@cp $(BIN) $(PREFIX)/ootail
	@chmod 0755 $(PREFIX)/ootail
	@cp uninstall.sh $(PREFIX)/ootail-uninstall
	@chmod 0755 $(PREFIX)/ootail-uninstall
	@echo "installed ootail and ootail-uninstall to $(PREFIX)"

uninstall:
	@rm -f $(PREFIX)/ootail $(PREFIX)/ootail-uninstall /usr/local/bin/ootail /usr/local/bin/ootail-uninstall /usr/bin/ootail /usr/bin/ootail-uninstall
	@rm -rf $(HOME)/.cache/ootail $(HOME)/.config/ootail
	@echo "uninstalled ootail"

package-arch: $(BIN)
	@mkdir -p dist/arch-pkg/usr/bin
	@cp $(BIN) dist/arch-pkg/usr/bin/ootail
	@chmod 0755 dist/arch-pkg/usr/bin/ootail
	@cp uninstall.sh dist/arch-pkg/usr/bin/ootail-uninstall
	@chmod 0755 dist/arch-pkg/usr/bin/ootail-uninstall
	@printf "pkgname = ootail\npkgbase = ootail\npkgver = $(VERSION)-1\npkgdesc = Capability-bounded file tail and follower utility with inotify, truncate recovery, and MCP stdio server\nurl = https://github.com/openOODA-tools/ootail\nbuilddate = $$(date +%s)\npackager = openOODA-tools <ops@openooda.org>\nsize = $$(stat -c %s $(BIN))\narch = x86_64\nlicense = Apache-2.0\ndepend = glibc\nprovides = ootail\n" > dist/arch-pkg/.PKGINFO
	@tar --zstd -cf dist/ootail-$(VERSION)-1-x86_64.pkg.tar.zst -C dist/arch-pkg .PKGINFO usr
	@rm -rf dist/arch-pkg
	@bash -n packaging/arch/PKGBUILD
	@cp packaging/arch/PKGBUILD packaging/PKGBUILD
	@echo "built dist/ootail-$(VERSION)-1-x86_64.pkg.tar.zst and validated PKGBUILD"

package: package-deb package-rpm package-arch

# --- Verification gate ---------------------------------------------------------

line-cap:
	@violations=0; \
	for f in $$(find . -name "*.oo" -o -name "*.oot"); do \
		n=$$(wc -l < "$$f"); \
		if [ $$n -gt 256 ]; then \
			echo "VIOLATION: $$f = $$n lines (exceeds 256)"; violations=$$((violations+1)); \
			continue; \
		fi; \
		code=$$(grep -vE '^[[:space:]]*(//.*)?$$' "$$f" | grep -cvE '^[[:space:]]*import[[:space:]]+"'); \
		if [ "$$code" = "0" ]; then continue; fi; \
		if [ $$n -lt 16 ]; then \
			echo "VIOLATION: $$f = $$n lines (under 16-line floor, not a shim)"; violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: $$violations files violate the Page Rule"; exit 1; fi; \
	echo "PASS: Page Rule sizing (16-256 lines, shims exempt from floor) holds"

file-law:
	@forbidden="py js ts rb pl json yaml toml"; \
	violations=0; \
	for ext in $$forbidden; do \
		found=$$(find . -name "*.$$ext" -not -path "./.git/*" -not -path "./dist/*" -not -path "./.ooda-cache/*" -not -path "./.blackbox/*" 2>/dev/null | head -3); \
		if [ -n "$$found" ]; then \
			echo "VIOLATION: .$$ext forbidden:"; echo "$$found"; violations=$$((violations+1)); \
		fi; \
	done; \
	for f in $$(find . -name "*.md" -not -path "./.git/*" -not -path "./.ooda-cache/*" -not -path "./.blackbox/*" 2>/dev/null); do \
		if [ "$$f" != "./README.md" ] && [ "$$f" != "./AGENTS.md" ]; then \
			echo "VIOLATION: .md forbidden outside README.md and AGENTS.md: $$f"; violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: file-law violations"; exit 1; fi; \
	echo "PASS: file law holds"

academy:
	@failures=0; \
	for f in $$(find . -name "*.oo" -not -path "./dist/*"); do \
		header=$$(head -7 "$$f"); \
		missing=""; \
		echo "$$header" | grep -q "^// # "        || missing="$$missing title"; \
		echo "$$header" | grep -q "^// Logline:"  || missing="$$missing logline"; \
		echo "$$header" | grep -q "^// Setup:"    || missing="$$missing setup"; \
		echo "$$header" | grep -q "^// Beats:"    || missing="$$missing beats"; \
		if [ -n "$$missing" ]; then \
			echo "FAIL: $$f missing Academy element(s):$$missing"; failures=$$((failures+1)); \
		fi; \
	done; \
	if [ $$failures -gt 0 ]; then echo "FAIL: $$failures academy header violations"; exit 1; fi; \
	echo "PASS: academy headers hold (all 4 elements present in first 7 lines)"

density:
	@violations=0; \
	for d in $$(find . -type d -not -path "./.git*" -not -path "./dist*" -not -path "./.ooda-cache*"); do \
		n=$$(ls "$$d"/*.oo "$$d"/*.oot 2>/dev/null | grep -v '\*' | wc -l); \
		if [ $$n -gt 8 ]; then \
			echo "VIOLATION: $$d holds $$n pages (exceeds 8)"; violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: $$violations directories exceed the density bound"; exit 1; fi; \
	echo "PASS: directory density (<= 8 pages per directory) holds"

check:
	@for f in $$(find . -name "*.oo" -not -path "./dist/*"); do \
		$(OODA_COMPILER) check "$$f" > /dev/null || exit 1; \
	done; \
	echo "PASS: oodac check holds on all .oo files"

verify: line-cap file-law academy density check

clean:
	@rm -rf dist .ooda-cache
	@echo "cleaned"
