# SiMa NEAT — VS Code Template

VS Code chrome + terminal prompt styled with the official SiMa.ai brand palette.

## What it does

- **Title bar** → Opal Blue `#5998DD`
- **Activity bar** → Chalcedony Green `#2A9C4F`
- **Status bar** → Jasper Red `#D26728`
- **Terminal prompt** (starship) → four-tile layout in brand colors
- `window.zoomLevel: 2`, JetBrainsMono Nerd Font, minimap and breadcrumbs hidden
- Everything else → VS Code Default Dark Modern

Hexes from the official SiMa.ai Brand Guidelines (Opal Blue, Chalcedony Green, Lechatelierite Lime, Jasper Red).

## Install

### 1. Terminal prompt (one command)

```bash
./install.sh
```

Installs `starship`, JetBrainsMono Nerd Font, symlinks `~/.config/starship.toml` to this repo's config, and adds `starship init zsh` to `~/.zshrc`. Idempotent — safe to rerun.

Open a new terminal to see it.

### 2. VS Code chrome (per project)

```bash
cd /path/to/your/project
mkdir -p .vscode
cp <this-repo>/settings.json <this-repo>/extensions.json .vscode/
```

Then **`Cmd+Q` and reopen VS Code** — `window.titleBarStyle` requires a full app restart the first time. After that, tweaks only need `Developer: Reload Window`.

### 3. VS Code chrome (globally)

`Cmd+Shift+P` → `Preferences: Open User Settings (JSON)` → merge `settings.json` contents → `Cmd+Q` → reopen.

## Recommended extensions

`extensions.json` recommends Python, C/C++, and clang-format. VS Code prompts to install on first open.
