{ config, pkgs, ... }: {
	programs.zsh = {
		enable = true;
		enableCompletion = true;
		syntaxHighlighting.enable = true;
		shellAliases = {
			ls = "exa --long --header --all --icons";
		};
		initExtraFirst = ''
			zstyle ':completion:*' menu select
            		eval "$(starship init zsh)"
          	'';
	};
}
