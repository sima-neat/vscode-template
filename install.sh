#!/usr/bin/env bash
# Installs starship + JetBrainsMono Nerd Font, wires zsh, symlinks starship.toml.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

command -v brew >/dev/null \
  || { echo "Homebrew required — install from https://brew.sh" >&2; exit 1; }

command -v starship >/dev/null || brew install starship
compgen -G "$HOME/Library/Fonts/JetBrainsMono*NerdFont*.ttf" >/dev/null \
  || brew install --cask font-jetbrains-mono-nerd-font

mkdir -p ~/.config
if [[ -e ~/.config/starship.toml && ! -L ~/.config/starship.toml ]]; then
  echo "Refusing to overwrite ~/.config/starship.toml (not a symlink). Move it aside and re-run." >&2
  exit 1
fi
ln -sf "$HERE/starship.toml" ~/.config/starship.toml

grep -qE '^[[:space:]]*eval "\$\(starship init zsh\)"' ~/.zshrc 2>/dev/null \
  || printf '\neval "$(starship init zsh)"\n' >> ~/.zshrc

echo "Done. Open a new terminal to see the brand prompt."
