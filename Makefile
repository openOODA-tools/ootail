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
#   make package-deb - generate Debian (.deb) package
#   make package-rpm - generate RedHat/Fedora (.rpm) package
#   make package     - build all distribution packages
#   make clean       - remove build artifacts

OODA_COMPILER ?= $(firstword $(wildcard $(HOME)/.openooda/bin/oodac $(CURDIR)/../../openOODA/oodac/bin/oodac))
OODACODEX ?= $(HOME)/.openooda/northstar.oot
OO_LIST_AMBIENT_QUOTA ?= 8589934592
BIN := dist/ootail
VERSION ?= 0.1.0

SRC := $(wildcard *.oo) $(wildcard */*.oo)

.PHONY: all build check line-cap file-law academy density verify test package package-deb package-rpm package-arch clean

all: verify build test

build: $(BIN)

$(BIN): $(SRC)
	@mkdir -p dist .ooda-cache/ooda-tmp
	OO_LIST_AMBIENT_QUOTA=$(OO_LIST_AMBIENT_QUOTA) OODACODEX=$(OODACODEX) OODA_COMPILER=$(OODA_COMPILER) OODA_NO_JAIL=1 $(OODA_COMPILER) build main.oo -o $(BIN)
	@chmod +x $(BIN)
	@echo "built $(BIN)"

test: $(BIN)
	@echo "=== testing --help ==="
	@./$(BIN) --help > /dev/null && echo "PASS: --help"
	@echo "=== testing --version ==="
	@./$(BIN) --version > /dev/null && echo "PASS: --version"
	@echo "=== testing invalid flag (expect exit 2) ==="
	@./$(BIN) --invalid-xyz > /dev/null 2>&1; test $$? -eq 2 && echo "PASS: invalid flag exits 2"
	@echo "=== testing missing file (expect exit 1) ==="
	@./$(BIN) /nonexistent/file/path/xyz > /dev/null 2>&1; test $$? -eq 1 && echo "PASS: missing file exits 1"
	@echo "=== testing -n line windowing ==="
	@seq 1 20 > .test_lines.txt
	@test "$$(./$(BIN) -n 5 .test_lines.txt | wc -l)" = "5" && echo "PASS: -n 5 emits 5 lines"
	@test "$$(./$(BIN) -n 5 .test_lines.txt | head -n 1)" = "16" && echo "PASS: -n 5 starts at 16"
	@test "$$(./$(BIN) -3 .test_lines.txt | wc -l)" = "3" && echo "PASS: -3 emits 3 lines"
	@test "$$(./$(BIN) .test_lines.txt | wc -l)" = "10" && echo "PASS: default emits 10 lines"
	@rm -f .test_lines.txt
	@echo "=== testing stdin pipe ==="
	@test "$$(printf 'a\nb\nc\nd\n' | ./$(BIN) -n 2)" = "$$(printf 'c\nd')" && echo "PASS: stdin -n 2 works"
	@echo "=== testing multi-file headers ==="
	@printf "f1_1\nf1_2\n" > .t1.txt
	@printf "f2_1\nf2_2\n" > .t2.txt
	@./$(BIN) .t1.txt .t2.txt | grep -q "==> .t1.txt <==" && echo "PASS: multi-file header 1"
	@./$(BIN) .t1.txt .t2.txt | grep -q "==> .t2.txt <==" && echo "PASS: multi-file header 2"
	@test "$$(./$(BIN) -q .t1.txt .t2.txt | grep -c '==>')" = "0" && echo "PASS: -q suppresses headers"
	@./$(BIN) -v .t1.txt | grep -q "==> .t1.txt <==" && echo "PASS: -v shows header for single file"
	@rm -f .t1.txt .t2.txt
	@echo "=== testing follow mode append ==="
	@printf "init1\ninit2\n" > .tf.txt
	@(sleep 0.1 && printf "app1\n" >> .tf.txt) & \
	out="$$(OODA_TAIL_CYCLES=3 ./$(BIN) -n 1 -f .tf.txt)"; \
	wait; \
	echo "$$out" | grep -q "app1" && echo "PASS: -f follows appended data"
	@echo "=== testing follow mode truncate recovery ==="
	@printf "line1\nline2\n" > .tf.txt
	@(sleep 0.1 && printf "trunc1\n" > .tf.txt) & \
	out="$$(OODA_TAIL_CYCLES=3 ./$(BIN) -n 1 -f .tf.txt)"; \
	wait; \
	echo "$$out" | grep -q "file truncated" && echo "$$out" | grep -q "trunc1" && echo "PASS: -f detects truncate and recovers"
	@rm -f .tf.txt
	@echo "=== testing installer & uninstaller dry-run ==="
	@./install.sh --dry-run > /dev/null && echo "PASS: install.sh --dry-run"
	@./install.sh --uninstall --dry-run > /dev/null && echo "PASS: install.sh --uninstall --dry-run"
	@./uninstall.sh --dry-run > /dev/null && echo "PASS: uninstall.sh --dry-run"
	@echo "ALL TESTS PASSED"

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

package-arch:
	@bash -n packaging/arch/PKGBUILD
	@cp packaging/arch/PKGBUILD packaging/PKGBUILD
	@echo "validated packaging/arch/PKGBUILD and packaging/PKGBUILD"

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
