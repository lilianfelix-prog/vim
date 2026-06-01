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
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# =============================================================
# 1. System dependencies
# =============================================================
info "Installing system dependencies..."
sudo apt update -y
sudo apt install -y \
    git \
    curl \
    nodejs \
    npm \
    clangd \
    python3-pip \
    universal-ctags \
    ripgrep \
    fd-find \
    bear \
    unzip \
    wget \
    fontconfig \
    shellcheck

# =============================================================
# 2. tree-sitter CLI
# =============================================================
info "Installing tree-sitter CLI via npm..."
sudo npm install -g tree-sitter-cli

# =============================================================
# 3. Neovim (latest AppImage)
# =============================================================
info "Downloading latest Neovim AppImage..."
cd /tmp
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage
chmod +x nvim-linux-x86_64.appimage

info "Installing Neovim to /usr/local/bin/nvim..."
sudo mv nvim-linux-x86_64.appimage /usr/local/bin/nvim

nvim --version | head -1 || error "Neovim installation failed"

# =============================================================
# 4. Neovim config directories
# =============================================================
info "Creating Neovim config directories..."
mkdir -p ~/.config/nvim
mkdir -p ~/.config/nvim/autoload
mkdir -p ~/.config/nvim/plugged
mkdir -p ~/.config/nvim/lua
mkdir -p ~/.config/nvim/after/ftdetect

# =============================================================
# 5. vim-plug
# =============================================================
info "Installing vim-plug..."
curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# =============================================================
# 6. init.vim
# =============================================================
info "Writing ~/.config/nvim/init.vim..."
cat > ~/.config/nvim/init.vim << 'EOF'
" =========================
" PLUGINS
" =========================
call plug#begin('~/.config/nvim/plugged')
Plug 'EdenEast/nightfox.nvim'
" CoC autocomplete/LSP
Plug 'neoclide/coc.nvim', {'branch': 'release'}
" Better syntax highlighting
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
" Nice status line
Plug 'vim-airline/vim-airline'
" Git support
Plug 'tpope/vim-fugitive'
" Surround text easily
Plug 'tpope/vim-surround'
" Comment shortcut
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
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set smartindent
set mouse=a
set clipboard=unnamedplus
set ignorecase
set smartcase
set nowrap
set termguicolors
set updatetime=300
set signcolumn=yes
" Better splits
set splitright
set splitbelow
set path+=**
" =========================
" SEARCH
" =========================
set incsearch
set hlsearch
" Clear search highlight
nnoremap <leader>h :nohlsearch<CR>

" =========================
" COC CONFIG
" =========================
" TAB completion
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible()
      \ ? coc#pum#prev(1)
      \ : "\<C-h>"
inoremap <silent><expr> <CR>
      \ coc#pum#visible()
      \ ? coc#pum#confirm()
      \ : "\<CR>"
function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction
" Go to definition
nmap gd <Plug>(coc-definition)
" References
nmap gr <Plug>(coc-references)
" Rename symbol
nmap rn <Plug>(coc-rename)
" Hover docs
nnoremap K :call CocActionAsync('doHover')<CR>
" Diagnostics
nmap [g <Plug>(coc-diagnostic-prev)
nmap ]g <Plug>(coc-diagnostic-next)
" Format
nmap <leader>f <Plug>(coc-format)

" =========================
" TREESITTER
" =========================
lua require('treesitter-config')

" =========================
" FILETYPE SETTINGS
" =========================
autocmd FileType dts setlocal commentstring=/*\ %s\ */

" =========================
" LEADER
" =========================
let mapleader=" "
EOF

# =============================================================
# 7. treesitter-config.lua
# =============================================================
info "Writing ~/.config/nvim/lua/treesitter-config.lua..."
cat > ~/.config/nvim/lua/treesitter-config.lua << 'EOF'
require('nvim-treesitter').setup {
  install_dir = vim.fn.stdpath('data') .. '/site'
}

require('nvim-treesitter').install({
  'c',
  'python',
  'bash',
  'lua',
  'vim',
  'json',
  'yaml',
  'markdown'
}):wait(300000)
EOF

# =============================================================
# 8. DTS filetype detection
# =============================================================
info "Creating DTS filetype detection..."
cat > ~/.config/nvim/after/ftdetect/dts.vim << 'EOF'
autocmd BufRead,BufNewFile *.dts,*.dtsi set filetype=dts
EOF

# =============================================================
# 9. Install vim-plug plugins
# =============================================================
info "Installing Neovim plugins via PlugInstall..."
nvim --headless +PlugInstall +qall 2>/dev/null || warn "PlugInstall had warnings — usually fine"

# =============================================================
# 10. Install CoC extensions
# =============================================================
info "Installing CoC extensions..."
nvim --headless \
    +"CocInstall -sync coc-clangd coc-pyright coc-sh coc-json coc-yaml" \
    +qall 2>/dev/null || warn "CocInstall had warnings — run manually on first launch if needed"


# =============================================================
# 11. JetBrainsMono Nerd Font
# =============================================================
info "Installing JetBrainsMono Nerd Font..."
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts

if [ ! -d "JetBrainsMono" ]; then
    wget -q --show-progress \
        https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
    unzip -q JetBrainsMono.zip -d JetBrainsMono
    rm JetBrainsMono.zip
else
    warn "JetBrainsMono already exists, skipping download"
fi

info "Refreshing font cache..."
fc-cache -fv > /dev/null 2>&1

# =============================================================
# Done
# =============================================================
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} Neovim setup complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Files written:"
echo "  ~/.config/nvim/init.vim"
echo "  ~/.config/nvim/lua/treesitter-config.lua"
echo "  ~/.config/nvim/after/ftdetect/dts.vim"
echo ""
echo "Next steps:"
echo "  1. Set your terminal font to 'JetBrainsMono Nerd Font'"
echo "  2. Open nvim and run :checkhealth to verify everything"
echo "  3. If CoC extensions are missing, run :CocInstall coc-clangd coc-pyright coc-sh coc-json coc-yaml"
