#!/usr/bin/env bash
# Build an IOsonata MCU library and one of its examples with the IOcomposer
# managed builder (Eclipse Embedded C++) in headless mode. Run setup.sh first.
#
# Usage: build.sh <MCU directory> [example] [configuration]
#   build.sh ARM/Nordic/nRF52/nRF52832 UartPrbsTxTest Release
#
# Run from the IOsonata repository root. The example ELF and map file are
# written to <MCU directory>/exemples/<example>/ioc/<configuration>/.

set -euo pipefail

MCU_DIR="${1:?MCU directory required}"
EXAMPLE="${2:-UartPrbsTxTest}"
CONFIG="${3:-Release}"

TOOLS="${IOSONATA_CI_TOOLS:-$HOME/iosonata-ci}"
export PATH="$TOOLS/arm-gcc/bin:$PATH"

LIB_PROJ="$PWD/$MCU_DIR/lib/ioc"
APP_PROJ="$PWD/$MCU_DIR/exemples/$EXAMPLE/ioc"

proj_name() {
	sed -n 's:.*<name>\(.*\)</name>.*:\1:p' "$1/.project" | head -1
}

headless_build() {
	local proj="$1" ws
	ws="$(mktemp -d)"
	"$TOOLS/eclipse/eclipse" \
		--launcher.suppressErrors \
		-nosplash \
		-application org.eclipse.cdt.managedbuilder.core.headlessbuild \
		-data "$ws" \
		-no-indexer \
		-import "$proj" \
		-cleanBuild "$(proj_name "$proj")/$CONFIG" \
		-printErrorMarkers
	rm -rf "$ws"
}

# The headless build rewrites the tracked .project files (it re-sorts the
# linked resources). Restore them so the MemBrowse onboard action can check
# out the next commit.
trap 'git checkout -q -- "$LIB_PROJ" "$APP_PROJ" 2>/dev/null || true' EXIT

headless_build "$LIB_PROJ"
headless_build "$APP_PROJ"

ELF="$APP_PROJ/$CONFIG/$(proj_name "$APP_PROJ").elf"
if [[ ! -f "$ELF" ]]; then
	echo "Build did not produce $ELF" >&2
	exit 1
fi
arm-none-eabi-size "$ELF"
