{ config, pkgs, ... }:
let 
	homeDir = config.home.homeDirectory;
in
{
	imports = [
		./alacritty.nix
		./zsh.nix
	];

	home = {
	    username = "cupskrrtt";
	    homeDirectory = pkgs.lib.mkForce "/Users/cupskrrtt";
	    
	    # Environment variables
	    sessionVariables = {
	      EDITOR = "nvim";
	      VISUAL = "nvim";
	      TERM = "xterm-256color";
	    };
	
	    # Packages that should be installed to the user profile
	    packages = with pkgs; [
	      # Development tools
	      ripgrep
	      fd
	      jq
	      fzf
	      tree
	      btop
	      eza
	
	      # Languages and development tools
        bun
	      go
        nodejs_20

        # LSP
        vscode-langservers-extracted
        gopls
        tailwindcss-language-server
        nodePackages_latest.typescript-language-server
        lua-language-server
	
	      # Git tools
	      git
	    ];
	    

	    file = {
		".tmux.conf".source = config.lib.file.mkOutOfStoreSymlink "${homeDir}/dotfiles/tmux/.tmux.conf";
		".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "${homeDir}/dotfiles/nvim/.config/nvim";
    ".config/starship.toml".source = config.lib.file.mkOutOfStoreSymlink "${homeDir}/dotfiles/starship/.config/starship.toml";
    ".config/aerospace".source = config.lib.file.mkOutOfStoreSymlink "${homeDir}/dotfiles/aerospace/.config/aerospace";
	    };
	
	    stateVersion = "24.05";
	  };

	  # Let Home Manager manage itself
	  programs.home-manager.enable = true;
	  fonts.fontconfig.enable = true;
}
