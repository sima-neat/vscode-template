#!/usr/bin/env bash
# Installs starship + JetBrainsMono Nerd Font, wires zsh, symlinks starship.toml.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

command -v starship >/dev/null || brew install starship
ls ~/Library/Fonts/JetBrainsMonoNerdFont-Regular.ttf >/dev/null 2>&1 \
  || brew install --cask font-jetbrains-mono-nerd-font

mkdir -p ~/.config
ln -sf "$HERE/starship.toml" ~/.config/starship.toml

grep -qF 'starship init zsh' ~/.zshrc 2>/dev/null \
  || printf '\neval "$(starship init zsh)"\n' >> ~/.zshrc

echo "Done. Open a new terminal to see the brand prompt."
