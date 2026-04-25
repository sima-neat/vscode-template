# SiMa.ai Palette Neat — VS Code Template

<p>
  <img src="assets/sima-logo.svg" alt="SiMa.ai logo" width="164">
</p>

VS Code chrome + terminal prompt styled with the official SiMa.ai brand palette.

## What it does

- **Title bar** → Quartz Lavender `#D1CEE6`
- **Activity bar** → Carbide Black `#010F0E` with Quartz Lavender active border
- **Status bar** → Opal Blue `#5998DD`
- **Editor, sidebar, panel, and terminal surfaces** → Carbide Black `#010F0E`
- **Primary foreground** → Tridymite Gray `#E8E9EB`
- **Window title** → `SiMa.ai Palette Neat`
- **Product icons** → `SiMa.ai Palette Neat Icons`
- **Codex-friendly shared UI tokens** → Opal Blue actions, Chalcedony Green icon accents, dark input surfaces
- **Terminal prompt** (starship) → four-tile layout in SiMa brand colors
- **Font** → Roboto Mono / RobotoMono Nerd Font Mono
- Command Center/search enabled with black title-bar foreground
- `window.zoomLevel: 2`, minimap and breadcrumbs hidden
- Base theme → VS Code Default Dark Modern

Hexes from the official SiMa.ai Brand Guidelines, including Quartz Lavender, Opal Blue, Carbide Black, Tridymite Gray, Chalcedony Green, Lechatelierite Lime, and Jasper Red.

## Palette direction

This template uses the calmer, more productized direction:

- Lavender brand hit in the title bar
- Serious dark workspace and left rail
- Blue state/status strip at the bottom
- Chalcedony Green active and in-window icon accents from the SiMa guidelines
- Jasper Red reserved for rare highlights rather than the main chrome

Plain VS Code settings can theme the chrome, tabs, sidebar, editor, panel, terminal, and many shared tokens consumed by VS Code webviews such as Codex. They cannot replace the actual VS Code application icon in the operating-system shell, and `window.title` does not support per-word color. The included product icon theme can replace built-in UI glyphs with single-color icon-font glyphs, including a SiMa logo mark for supported product-icon slots.

## One-command install

macOS / Linux:

```bash
./install.sh
```

Windows PowerShell:

```powershell
.\install.ps1
```

Windows Command Prompt:

```bat
install.cmd
```

The installer:

- Builds the product icon theme VSIX from source when needed.
- Installs the packaged VS Code product icon theme.
- Registers Palette Neat for the attached container image `ghcr.io/sima-neat/elxr:latest`.
- Leaves normal local VS Code windows alone.
- Installs terminal extras where supported: Starship, Starship config, and Roboto fonts on macOS; best-effort Starship/font package install on Linux; Starship setup on Windows.

To skip terminal prompt setup:

```bash
SIMA_SKIP_TERMINAL=1 ./install.sh
```

```powershell
.\install.ps1 -SkipTerminal
```

Docker does not need to be running during install. The theme applies the next time VS Code attaches to the ELXR container. If VS Code is already attached, run **Developer: Reload Window**.

## Validate

macOS / Linux:

```bash
./validate.sh
```

Windows PowerShell:

```powershell
.\validate.ps1
```

Windows Command Prompt:

```bat
validate.cmd
```

Validation checks:

- Required repo files exist.
- JSON files parse.
- VS Code can see the product icon extension.
- The ELXR attached-container image config exists.
- The attached-container config contains the Palette Neat settings and product icon extension.

## Container activation

Palette Neat is intended to activate only when VS Code is attached to the SiMa ELXR container.

For a repo-managed dev container, use:

```text
.devcontainer/sima-elxr/devcontainer.json
```

That file places the full theme under:

```json
"customizations": {
  "vscode": {
    "settings": {}
  }
}
```

Those settings are applied only in the Dev Containers context, not when the folder is opened locally.

For an already-running ELXR container, the installer updates VS Code's image-specific attached-container configuration automatically. If you want to inspect or edit it manually, run **Dev Containers: Open Attached Container Configuration File** after attaching to the container.

The product icon theme is a UI extension, so it is built and installed on the desktop VS Code side:

```bash
code --install-extension sima-palette-neat-product-icons-0.1.0.vsix --force
```

The container-scoped template sets:

```json
"workbench.productIconTheme": "sima-palette-neat-icons"
```

Do not copy `settings.json` into a normal workspace `.vscode/settings.json` if you want the theme to remain container-only.

## Future extension path

This repo currently ships portable settings. To turn it into a fuller VS Code package, add:

- `SiMa.ai Palette Neat Dark` as a real color theme extension
- `SiMa.ai Palette Neat Light` later, if needed
- Publish the included product icon theme as a packaged extension

## Recommended extensions

`extensions.json` recommends Python, C/C++, and clang-format. VS Code prompts to install on first open.
