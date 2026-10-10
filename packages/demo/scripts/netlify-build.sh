#!/usr/bin/env bash
# Netlify build: installs the Rust/WASM toolchain needed to compile the
# scramjet rewriter (packages/core/dist/scramjet.wasm), then builds the demo.
set -euo pipefail

WASM_BINDGEN_VERSION="0.2.105"
BINARYEN_VERSION="version_124"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TOOLS_BIN="$HOME/.local/bin"
mkdir -p "$TOOLS_BIN"
export PATH="$HOME/.cargo/bin:$TOOLS_BIN:$PATH"

if ! command -v rustup &> /dev/null; then
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain none
fi
rustup toolchain install nightly --profile minimal --component rust-src --target wasm32-unknown-unknown
rustup default nightly

if ! [[ "$(wasm-bindgen -V 2> /dev/null)" =~ ^"wasm-bindgen $WASM_BINDGEN_VERSION" ]]; then
	name="wasm-bindgen-${WASM_BINDGEN_VERSION}-x86_64-unknown-linux-musl"
	curl -sSfL "https://github.com/wasm-bindgen/wasm-bindgen/releases/download/${WASM_BINDGEN_VERSION}/${name}.tar.gz" \
		| tar xz -C /tmp
	cp "/tmp/${name}/wasm-bindgen" "$TOOLS_BIN/"
fi

if ! command -v wasm-opt &> /dev/null; then
	curl -sSfL "https://github.com/WebAssembly/binaryen/releases/download/${BINARYEN_VERSION}/binaryen-${BINARYEN_VERSION}-x86_64-linux.tar.gz" \
		| tar xz -C "$HOME/.local" --strip-components=1
fi

if ! command -v wasm-snip &> /dev/null; then
	cargo install --git https://github.com/r58playz/wasm-snip --root "$HOME/.local"
fi

cd "$ROOT"
RELEASE=1 pnpm --filter @mercuryworkshop/scramjet run rewriter:build
pnpm --filter @mercuryworkshop/scramjet-demo... run build
