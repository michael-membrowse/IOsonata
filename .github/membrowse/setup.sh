#!/usr/bin/env bash
# Install the tools needed to build an IOsonata MCU library and example with
# the IOcomposer managed builder (Eclipse Embedded C++) in headless mode, and
# clone the external SDKs the selected target needs.
#
# Usage: setup.sh [external repo name ...]
#
# Tools go to $IOSONATA_CI_TOOLS (default ~/iosonata-ci). build.sh is copied
# there so the MemBrowse onboard workflow can build older commits that do not
# contain it. External repos are cloned next to the IOsonata checkout in
# ../external, the layout the IOsonata projects expect.

set -euo pipefail

ECLIPSE_RELEASE=2026-06
ARM_GCC_VERSION=15.2.1-1.1

TOOLS="${IOSONATA_CI_TOOLS:-$HOME/iosonata-ci}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EXT="$(dirname "$REPO_ROOT")/external"

declare -A EXT_URL=(
	[nrfx]=https://github.com/NordicSemiconductor/nrfx.git
	[sdk-nrf-bm]=https://github.com/IOsonata/sdk-nrf-bm.git
	[sdk-nrfxlib]=https://github.com/nrfconnect/sdk-nrfxlib.git
	[sdk-oberon-psa-crypto]=https://github.com/nrfconnect/sdk-oberon-psa-crypto.git
	[sdk-mbedtls]=https://github.com/nrfconnect/sdk-mbedtls.git
	[nRF5_SDK]=https://github.com/IOsonata/nRF5_SDK.git
	[nRF5_SDK_Mesh]=https://github.com/IOsonata/nRF5_SDK_Mesh.git
	[BSEC]=https://github.com/boschsensortec/Bosch-BSEC2-Library.git
	[Fusion]=https://github.com/xioTechnologies/Fusion.git
	[vqf]=https://github.com/dlaidig/vqf.git
	[lwip]=https://github.com/lwip-tcpip/lwip.git
)

mkdir -p "$TOOLS" "$EXT"

if [[ ! -x "$TOOLS/xpack-arm-none-eabi-gcc-$ARM_GCC_VERSION/bin/arm-none-eabi-gcc" ]]; then
	echo "Installing xPack Arm GCC $ARM_GCC_VERSION"
	curl -fsSL "https://github.com/xpack-dev-tools/arm-none-eabi-gcc-xpack/releases/download/v$ARM_GCC_VERSION/xpack-arm-none-eabi-gcc-$ARM_GCC_VERSION-linux-x64.tar.gz" \
		| tar -xz -C "$TOOLS"
fi
ln -sfn "$TOOLS/xpack-arm-none-eabi-gcc-$ARM_GCC_VERSION" "$TOOLS/arm-gcc"

if [[ ! -x "$TOOLS/eclipse/eclipse" ]]; then
	echo "Installing Eclipse Embedded C++ $ECLIPSE_RELEASE"
	curl -fsSL "https://download.eclipse.org/technology/epp/downloads/release/$ECLIPSE_RELEASE/R/eclipse-embedcpp-$ECLIPSE_RELEASE-R-linux-gtk-x86_64.tar.gz" \
		| tar -xz -C "$TOOLS"
fi

for name in "$@"; do
	url="${EXT_URL[$name]:-}"
	if [[ -z "$url" ]]; then
		echo "Unknown external repo: $name" >&2
		exit 1
	fi
	if [[ ! -d "$EXT/$name/.git" ]]; then
		echo "Cloning $name"
		git clone -q --depth=1 "$url" "$EXT/$name"
	fi
done

cp "$REPO_ROOT/.github/membrowse/build.sh" "$TOOLS/build.sh"
chmod +x "$TOOLS/build.sh"

"$TOOLS/arm-gcc/bin/arm-none-eabi-gcc" --version | head -1
