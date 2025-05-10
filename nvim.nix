{pkgs, ... }:

{
    programs.neovim = {
  	enable = true;
  	viAlias = true;
	vimAlias = true;
	plugins = with pkgs.vimPlugins; [ 
		vim-nix
        telescope-nvim
        nvim-treesitter
        lualine-nvim
        indent-blankline-nvim
        dracula-nvim
		];
    extraConfig = ''
        set relativenumber 
        set linebreak
        set showbreak=+++
        set textwidth=100
        set showmatch
        set visualbell
        
        set hlsearch
        set smartcase
        set ignorecase
        set incsearch
        
        set autoindent
        set shiftwidth=4
        set smartindent
        set smarttab
        set softtabstop=4
        
        set ruler
        
        set undolevels=1000	
        set backspace=indent,eol,start
        colorscheme dracula

        lua << END
        require('lualine').setup {
            options = {
                icons_enabled = true,
                theme = 'dracula',
                component_separators = { left = '', right = ''},
                section_separators = { left = '', right = ''},
                disabled_filetypes = {
                statusline = {},
                winbar = {},
                },
                ignore_focus = {},
                always_divide_middle = true,
                globalstatus = false,
                refresh = {
                statusline = 1000,
                tabline = 1000,
                winbar = 1000,
                }
            },
            sections = {
                lualine_a = {'mode'},
                lualine_b = {'branch', 'diff', 'diagnostics'},
                lualine_c = {'filename'},
                lualine_x = {'encoding', 'fileformat', 'filetype'},
                lualine_y = {'progress'},
                lualine_z = {'location'}
            },
            inactive_sections = {
                lualine_a = {},
                lualine_b = {},
                lualine_c = {'filename'},
                lualine_x = {'location'},
                lualine_y = {},
                lualine_z = {}
            },
            tabline = {},
            winbar = {},
            inactive_winbar = {},
            extensions = {}
        }
        END
    '';
	};
}
