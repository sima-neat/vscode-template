#!/usr/bin/env bash
# Validate SiMa.ai Palette Neat installation files on macOS/Linux.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_CONFIG_NAME="ghcr.io%2fsima-neat%2felxr%3alatest.json"
REQUIRED_ICON_THEME="sima-ai.sima-palette-neat-product-icons"

pass() {
  printf '✓ %s\n' "$*"
}

fail() {
  printf '✗ %s\n' "$*" >&2
  exit 1
}

find_code_cli() {
  if command -v code >/dev/null 2>&1; then
    command -v code
    return 0
  fi

  if command -v code-insiders >/dev/null 2>&1; then
    command -v code-insiders
    return 0
  fi

  if [[ "$(uname -s)" == "Darwin" ]]; then
    local stable="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
    local insiders="/Applications/Visual Studio Code - Insiders.app/Contents/Resources/app/bin/code"
    if [[ -x "$stable" ]]; then
      printf '%s\n' "$stable"
      return 0
    fi
    if [[ -x "$insiders" ]]; then
      printf '%s\n' "$insiders"
      return 0
    fi
  fi

  return 1
}

code_user_dir() {
  if [[ -n "${CODE_USER_DATA_DIR:-}" ]]; then
    printf '%s\n' "$CODE_USER_DATA_DIR/User"
    return 0
  fi

  case "$(uname -s)" in
    Darwin)
      printf '%s\n' "$HOME/Library/Application Support/Code/User"
      ;;
    Linux)
      printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/Code/User"
      ;;
    *)
      return 1
      ;;
  esac
}

require_json() {
  local path="$1"
  python3 -m json.tool "$path" >/dev/null || fail "Invalid JSON: $path"
  pass "Valid JSON: $path"
}

require_file() {
  local path="$1"
  [[ -f "$path" ]] || fail "Missing file: $path"
  pass "Found file: $path"
}

main() {
  command -v python3 >/dev/null 2>&1 || fail "python3 is required for validation."

  require_file "$HERE/settings.json"
  require_file "$HERE/.devcontainer/sima-elxr/devcontainer.json"
  require_file "$HERE/product-icon-theme/package.json"
  require_file "$HERE/product-icon-theme/themes/sima-palette-neat-product-icon-theme.json"
  require_file "$HERE/product-icon-theme/source-icons/sima-logo.svg"

  require_json "$HERE/settings.json"
  require_json "$HERE/.devcontainer/sima-elxr/devcontainer.json"
  require_json "$HERE/product-icon-theme/package.json"
  require_json "$HERE/product-icon-theme/themes/sima-palette-neat-product-icon-theme.json"

  bash -n "$HERE/install.sh" || fail "install.sh has a shell syntax error."
  pass "install.sh syntax is valid"

  local code_cli
  if code_cli="$(find_code_cli)"; then
    "$code_cli" --list-extensions | grep -qx "$REQUIRED_ICON_THEME" \
      || fail "VS Code extension is not installed: $REQUIRED_ICON_THEME"
    pass "VS Code extension installed: $REQUIRED_ICON_THEME"
  else
    fail "VS Code CLI not found."
  fi

  local image_config
  image_config="$(code_user_dir)/globalStorage/ms-vscode-remote.remote-containers/imageConfigs/$IMAGE_CONFIG_NAME"
  require_file "$image_config"
  require_json "$image_config"

  python3 - "$image_config" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text())
settings = data.get("customizations", {}).get("vscode", {}).get("settings", {})
extensions = data.get("customizations", {}).get("vscode", {}).get("extensions", [])

checks = {
    "window.title": "SiMa.ai Palette Neat",
    "workbench.productIconTheme": "sima-palette-neat-icons",
    "workbench.colorCustomizations": dict,
}

for key, expected in checks.items():
    if key not in settings:
        raise SystemExit(f"missing attached-container setting: {key}")
    if isinstance(expected, type):
        if not isinstance(settings[key], expected):
            raise SystemExit(f"attached-container setting {key} has wrong type")
    elif settings[key] != expected:
        raise SystemExit(f"attached-container setting {key} expected {expected!r}, got {settings[key]!r}")

if "sima-ai.sima-palette-neat-product-icons" not in extensions:
    raise SystemExit("attached-container config does not include product icon extension")
PY
  pass "ELXR attached-container config contains Palette Neat settings"

  printf '\nAll validation checks passed.\n'
}

main "$@"
