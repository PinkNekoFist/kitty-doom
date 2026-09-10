# External file download rules

# Detect available download tool (using command -v for better POSIX compliance)
ifeq ($(shell command -v wget >/dev/null 2>&1; echo $$?),0)
    DOWNLOAD_CMD = wget -q -O
else ifeq ($(shell command -v curl >/dev/null 2>&1; echo $$?),0)
    DOWNLOAD_CMD = curl -fsSL --max-time 30 -o
else
    $(error Neither wget nor curl found. Please install one of them.)
endif

# Detect available checksum tool
ifeq ($(shell command -v shasum >/dev/null 2>&1; echo $$?),0)
    SHA256_CMD = shasum -a 256 -c -
else ifeq ($(shell command -v sha256sum >/dev/null 2>&1; echo $$?),0)
    SHA256_CMD = sha256sum -c -
else
    $(error Neither shasum nor sha256sum found. Please install one of them.)
endif


# DOOM1.WAD (shareware version)
# Note: PureDOOM expects lowercase "doom1.wad" on case-sensitive filesystems (Linux).
# The Makefile will create a symlink automatically via the check-wad-symlink target.
DOOM1_ZIP = doom1.zip
DOOM1_WAD = DOOM1.WAD
DOOM1_WAD_SHA256 = 1d7d43be501e67d927e415e0b8f3e29c3bf33075e859721816f652a526cac771

# Download providers with automatic fallback (direct .wad and .zip archives)
DOOM1_WAD_URLS := \
    https://archive.org/download/doom-wads/Doom%20%28v1.9%29%20%28Demo%29.zip \
    https://raw.githubusercontent.com/Akbar30Bill/DOOM_wads/master/doom1.wad \
    https://raw.githubusercontent.com/nneonneo/universal-doom/main/DOOM1.WAD

$(DOOM1_WAD):
	$(Q)for url in $(DOOM1_WAD_URLS); do \
		printf "  GET\t$@ from %s\n" "$$url"; \
		if case "$$url" in \
			*.zip) $(DOWNLOAD_CMD) $(DOOM1_ZIP) "$$url" && \
			       printf "  UNZIP\t$@\n" && \
			       unzip -q -o -j $(DOOM1_ZIP) "*.[wW][aA][dD]" -d . && \
			       { [ ! -f DOOM.WAD ] || mv DOOM.WAD $@; } ;; \
			*)     $(DOWNLOAD_CMD) "$@" "$$url" ;; \
		esac; then \
			rm -f $(DOOM1_ZIP); \
			if echo "$(DOOM1_WAD_SHA256)  $@" | $(SHA256_CMD) >/dev/null 2>&1; then \
				printf "  CHK\t$@ (SHA256: OK)\n"; \
				exit 0; \
			else \
				printf "  WARN\tChecksum mismatch from %s, trying next...\n" "$$url"; \
			fi; \
		fi; \
		rm -f "$@" $(DOOM1_ZIP); \
	done; \
	echo "Error: Failed to download a valid $@ from all providers"; \
	exit 1


# PureDOOM.h download rule
PUREDOOM_URL = https://raw.githubusercontent.com/Daivuk/PureDOOM/master/PureDOOM.h
PUREDOOM_HEADER = src/PureDOOM.h

$(PUREDOOM_HEADER):
	$(VECHO) "  GET\t$@\n"
	$(Q)$(DOWNLOAD_CMD) $@ $(PUREDOOM_URL)

# miniaudio.h download rule (single-header audio library)
MINIAUDIO_URL = https://raw.githubusercontent.com/mackron/miniaudio/master/miniaudio.h
MINIAUDIO_HEADER = src/miniaudio.h

$(MINIAUDIO_HEADER):
	$(VECHO) "  GET\t$@\n"
	$(Q)$(DOWNLOAD_CMD) $@ $(MINIAUDIO_URL)

# Clean external files
.PHONY: clean-external
clean-external:
	$(VECHO) "  CLEAN\t\texternal files\n"
	$(Q)rm -f $(DOOM1_WAD) doom1.wad $(DOOM1_ZIP) $(PUREDOOM_HEADER) $(MINIAUDIO_HEADER)
