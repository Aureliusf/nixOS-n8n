{pkgs, ... }:

{
    programs.neovim = {
  	enable = true;
  	viAlias = true;
	vimAlias = true;
	configure = {
			customRC = ''
			set number
			set nowrap

			'';
			packages.myVimPackage = with pkgs.vimPlugins; {
				start = [ ctrlp ];
			};

		};
	
	};
}
