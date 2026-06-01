#!/usr/bin/env bash
# =============================================================
# Neovim full setup script
# Run with : chmod +x nvim-setup.sh
# =============================================================
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }

nvim --headless "+PlugClean" "+qall" || warn "PlugClean failed (first run only)"

info "Removing CoC data"
rm -rf ~/.config/coc
rm -rf ~/.config/nvim/plugged/coc.nvim
rm -rf ~/.local/share/coc
rm -rf ~/.config/coc
rm -rf ~/.local/share/nvim
rm -rf ~/.cache/nvim
