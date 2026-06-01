#!/usr/bin/env bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# ============================================================
# 1. SYSTEM PACKAGES
# ============================================================
info "Installing system dependencies..."

sudo apt install -y \
    git curl wget unzip fontconfig \
    clangd \
    python3-pip \
    ripgrep fd-find \
    bear \
    shellcheck \
    universal-ctags \
    nodejs npm

# Node is ONLY for language servers (not editor runtime)

# ============================================================
# 2. LANGUAGE SERVERS (LSP ONLY STACK)
# ============================================================
info "Installing LSP servers (user-local npm)..."

npm config set prefix "$HOME/.npm-global"

export PATH="$HOME/.npm-global/bin:$PATH"

npm install -g \
    pyright \
    bash-language-server \
    yaml-language-server \
    vscode-langservers-extracted
# ============================================================
# 3. NEOVIM CHECK
# ============================================================
if ! command -v nvim >/dev/null; then
    info "Installing Neovim..."

    cd /tmp
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage
    chmod +x nvim-linux-x86_64.appimage
    sudo mv nvim-linux-x86_64.appimage /usr/local/bin/nvim
else
    info "Neovim already installed"
fi

# ============================================================
# 4. CONFIG DIRS
# ============================================================
mkdir -p ~/.config/nvim/lua
mkdir -p ~/.config/nvim/after/ftdetect
mkdir -p ~/.config/nvim/autoload

# ============================================================
# 5. vim-plug
# ============================================================
if [ ! -f ~/.config/nvim/autoload/plug.vim ]; then
    info "Installing vim-plug..."
    curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# ============================================================
# 6. INIT.VIM (LSP ONLY)
# ============================================================
cat > ~/.config/nvim/init.vim << 'EOF'

" =========================
" PLUGINS
" =========================
call plug#begin('~/.config/nvim/plugged')

Plug 'EdenEast/nightfox.nvim'

" LSP CORE
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'L3MON4D3/LuaSnip'

" Treesitter (light syntax only)
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

" Utils
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-commentary'

call plug#end()

" =========================
" BASIC SETTINGS
" =========================
syntax on
filetype plugin indent on
colorscheme carbonfox

set number
set relativenumber
set termguicolors
set signcolumn=yes
set updatetime=200
set clipboard=unnamedplus
set mouse=a
set path+=**

tnoremap jk <C-\><C-n>

" =========================
" TREESITTER (SAFE)
" =========================
lua << LUA
local ok, ts = pcall(require, 'nvim-treesitter.configs')
if not ok then return end
ts.setup {
  ensure_installed = { "c", "python", "bash", "json", "yaml", "lua" },
  highlight = { enable = true },
}
LUA

" =========================
" LSP CONFIG
" =========================
lua << LUA
local ok, lspconfig = pcall(require, "lspconfig")
if not ok then return end
lspconfig.clangd.setup{}
lspconfig.pyright.setup{}
lspconfig.bashls.setup{}
lspconfig.yamlls.setup{}
vim.keymap.set('n', 'gd', vim.lsp.buf.definition)
vim.keymap.set('n', 'gr', vim.lsp.buf.references)
vim.keymap.set('n', 'K', vim.lsp.buf.hover)
vim.keymap.set('n', 'rn', vim.lsp.buf.rename)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
LUA

" =====================
" DTS SUPPORT
" =========================
autocmd BufRead,BufNewFile *.dts,*.dtsi set filetype=dts

EOF

# ============================================================
# 8. INSTALL PLUGINS
# ============================================================
info "Installing Neovim plugins..."

nvim --headless "+PlugInstall" "+qall" || warn "Plugin install warning"

# ============================================================
# DONE
# ============================================================
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} Embedded LSP Neovim setup complete${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "  1. nvim"
echo "  2. :LspInfo"
echo "  3. open a .c file and test diagnostics"
