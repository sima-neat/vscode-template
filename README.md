# SiMa NEAT — VS Code Template

Minimal VS Code settings for recording NEAT / SiMa marketing videos. Default Dark Modern with three SiMa-colored chrome strips, zoomed for video readability.

## What it does

- **Title bar** → SiMa blue `#6890D8`
- **Activity bar** (left icon column) → SiMa green `#489850`
- **Status bar** → SiMa orange `#C06838`
- `window.zoomLevel: 2` so every panel scales evenly for video
- JetBrains Mono in editor and terminal
- Minimap and breadcrumbs hidden
- Everything else → VS Code Default Dark Modern (editor, sidebar, Claude/Codex panel, terminal — all unchanged)

Hexes sampled from the SiMa logo.

## Install

### Per-project

```bash
cd /path/to/your/project
mkdir -p .vscode
cp ~/workspace/sima-neat/vscode-template/settings.json .vscode/
cp ~/workspace/sima-neat/vscode-template/extensions.json .vscode/
```

Then **`Cmd+Q` and reopen VS Code** — `window.titleBarStyle` requires a full app restart on macOS the first time. After that, color or font tweaks only need `Cmd+Shift+P` → `Developer: Reload Window`.

### Globally

`Cmd+Shift+P` → `Preferences: Open User Settings (JSON)` → merge `settings.json` contents → `Cmd+Q` → reopen.

### As a shareable VS Code Profile

After applying once: `Cmd+Shift+P` → `Profiles: Export Profile` → save the `.code-profile` file. Recipients run `Profiles: Import Profile`.

## Font

Settings reference **JetBrains Mono**. Install:

```bash
brew install --cask font-jetbrains-mono
```

Falls back to Menlo if missing.

## Recommended extensions

`extensions.json` recommends Python, C/C++, and clang-format. VS Code prompts to install on first open.
