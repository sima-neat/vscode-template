#!/usr/bin/env bash
# Install SiMa.ai Palette Neat for VS Code on macOS/Linux.
#
# What this does:
# - Installs the local product icon theme VSIX into desktop VS Code.
# - Registers the Palette Neat settings for the SiMa ELXR attached container image.
# - Optionally installs Starship/Roboto fonts when a supported package manager is found.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_CONFIG_NAME="ghcr.io%2fsima-neat%2felxr%3alatest.json"
IMAGE_REF="ghcr.io/sima-neat/elxr:latest"
VSIX="$HERE/sima-palette-neat-product-icons-0.1.0.vsix"
DEVCONTAINER_TEMPLATE="$HERE/.devcontainer/sima-elxr/devcontainer.json"
ICON_THEME_DIR="$HERE/product-icon-theme"

log() {
  printf '%s\n' "$*"
}

warn() {
  printf 'Warning: %s\n' "$*" >&2
}

ensure_shell_init() {
  local shell_rc="$1"
  local init_line="$2"

  touch "$shell_rc"
  grep -qF "$init_line" "$shell_rc" 2>/dev/null || printf '\n%s\n' "$init_line" >> "$shell_rc"
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

install_product_icon_theme() {
  if [[ ! -f "$VSIX" ]]; then
    command -v npm >/dev/null 2>&1 || {
      warn "npm not found; cannot build product icon theme VSIX."
      warn "Install Node.js/npm, then rerun this installer."
      return 0
    }

    log "Building product icon theme VSIX..."
    mkdir -p "$ICON_THEME_DIR/fonts"
    npx --yes fantasticon "$ICON_THEME_DIR/source-icons" \
      -o "$ICON_THEME_DIR/fonts" \
      --name sima-icons \
      --font-types woff \
      --asset-types json >/dev/null
    (cd "$ICON_THEME_DIR" && npx --yes @vscode/vsce package --out "../$(basename "$VSIX")" >/dev/null)
  fi

  if [[ ! -f "$VSIX" ]]; then
    warn "Missing VSIX at $VSIX; skipping product icon theme install."
    return 0
  fi

  local code_cli
  if ! code_cli="$(find_code_cli)"; then
    warn "VS Code CLI not found; install the VSIX manually from $VSIX."
    return 0
  fi

  log "Installing VS Code product icon theme..."
  "$code_cli" --install-extension "$VSIX" --force >/dev/null
}

install_terminal_extras() {
  if [[ "${SIMA_SKIP_TERMINAL:-0}" == "1" ]]; then
    log "Skipping terminal extras because SIMA_SKIP_TERMINAL=1."
    return 0
  fi

  if [[ "$(uname -s)" == "Darwin" ]]; then
    if command -v brew >/dev/null 2>&1; then
      command -v starship >/dev/null 2>&1 || brew install starship
      compgen -G "$HOME/Library/Fonts/RobotoMonoNerdFontMono*.ttf" >/dev/null \
        || brew install --cask font-roboto-mono-nerd-font
      compgen -G "$HOME/Library/Fonts/RobotoMono*.ttf" >/dev/null \
        || brew install --cask font-roboto-mono
      compgen -G "$HOME/Library/Fonts/Roboto*.ttf" >/dev/null \
        || brew install --cask font-roboto
    else
      warn "Homebrew not found; skipping Starship and Roboto font install."
    fi
  elif [[ "$(uname -s)" == "Linux" ]]; then
    if command -v apt-get >/dev/null 2>&1; then
      if command -v sudo >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y starship fonts-roboto fonts-roboto-unhinted || true
      else
        warn "sudo not found; skipping apt package install."
      fi
    elif command -v dnf >/dev/null 2>&1; then
      sudo dnf install -y starship google-roboto-fonts google-roboto-mono-fonts || true
    elif command -v pacman >/dev/null 2>&1; then
      sudo pacman -S --needed starship ttf-roboto ttf-roboto-mono || true
    else
      warn "No supported Linux package manager found; skipping Starship and Roboto font install."
    fi
  fi

  mkdir -p "$HOME/.config"
  if [[ -e "$HOME/.config/starship.toml" && ! -L "$HOME/.config/starship.toml" ]]; then
    warn "Refusing to overwrite ~/.config/starship.toml because it is not a symlink."
  else
    ln -sf "$HERE/starship.toml" "$HOME/.config/starship.toml"
  fi

  if command -v zsh >/dev/null 2>&1; then
    ensure_shell_init "$HOME/.zshrc" 'eval "$(starship init zsh)"'
  fi

  if command -v bash >/dev/null 2>&1; then
    ensure_shell_init "$HOME/.bashrc" 'eval "$(starship init bash)"'
  fi
}

install_elxr_attach_config() {
  if ! command -v python3 >/dev/null 2>&1; then
    warn "python3 not found; cannot merge the ELXR attached-container config."
    warn "Use .devcontainer/sima-elxr/devcontainer.json as the manual template."
    return 0
  fi

  local user_dir
  user_dir="$(code_user_dir)"
  local image_config_dir="$user_dir/globalStorage/ms-vscode-remote.remote-containers/imageConfigs"
  local name_config_dir="$user_dir/globalStorage/ms-vscode-remote.remote-containers/nameConfigs"
  local image_config="$image_config_dir/$IMAGE_CONFIG_NAME"
  local name_config="$name_config_dir/ghcr.io-sima-neat-elxr-latest.json"

  mkdir -p "$image_config_dir" "$name_config_dir"

  log "Registering Palette Neat for attached container $IMAGE_REF..."
  python3 - "$DEVCONTAINER_TEMPLATE" "$image_config" "$name_config" <<'PY'
import json
import pathlib
import sys

template_path = pathlib.Path(sys.argv[1])
target_paths = [pathlib.Path(p) for p in sys.argv[2:]]

template = json.loads(template_path.read_text())
template_vscode = template["customizations"]["vscode"]

for target_path in target_paths:
    target = json.loads(target_path.read_text()) if target_path.exists() else {}
    target.setdefault("workspaceFolder", "/home/manuel.roldan")

    # Attached container configs have used both top-level settings/extensions
    # and customizations.vscode across Dev Containers versions. Write both.
    target["settings"] = {
        **target.get("settings", {}),
        **template_vscode["settings"],
    }
    target["extensions"] = list(dict.fromkeys([
        *target.get("extensions", []),
        *template_vscode.get("extensions", []),
        "sima-ai.sima-palette-neat-product-icons",
    ]))

    target.setdefault("customizations", {})
    target["customizations"].setdefault("vscode", {})
    target_vscode = target["customizations"]["vscode"]
    target_vscode["settings"] = {
        **target_vscode.get("settings", {}),
        **template_vscode["settings"],
    }
    target_vscode["extensions"] = list(dict.fromkeys([
        *target_vscode.get("extensions", []),
        *template_vscode.get("extensions", []),
        "sima-ai.sima-palette-neat-product-icons",
    ]))

    target_path.write_text(json.dumps(target, indent=2) + "\n")
PY
}

main() {
  install_product_icon_theme
  install_elxr_attach_config
  install_terminal_extras

  log ""
  log "Done. Palette Neat will activate when VS Code attaches to $IMAGE_REF."
  log "If VS Code is already attached, run: Developer: Reload Window"
}

main "$@"
