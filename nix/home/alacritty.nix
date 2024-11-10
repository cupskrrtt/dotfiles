{ config, pkgs, ... }: {
	programs.alacritty = {
		enable = true;
		settings = {
		env = { TERM = "xterm-256color"; };

           	font = {
           	   normal = {
           	     family = "Hack Nerd Font Mono";
           	     style = "Regular";
           	   };

           	   bold = {
           	     family = "Hack Nerd Font Mono";
           	     style = "Bold";
           	   };

           	   italic = {
           	     family = "Hack Nerd Font Mono";
           	     style = "Italic";
           	   };

           	   bold_italic = {
           	     family = "Hack Nerd Font Mono";
           	     style = "Bold Italic";
           	   };

           	   size = 14.0;
           	 };

           	 colors = {
           	   primary = {
           	     background = "#1a1b26";
           	     foreground = "#c0caf5";
           	   };

           	   normal = {
           	     black = "#15161e";
           	     red = "#f7768e";
           	     green = "#9ece6a";
           	     yellow = "#e0af68";
           	     blue = "#7aa2f7";
           	     magenta = "#bb9af7";
           	     cyan = "#7dcfff";
           	     white = "#a9b1d6";
           	   };

           	   bright = {
           	     black = "#414868";
           	     red = "#f7768e";
           	     green = "#9ece6a";
           	     yellow = "#e0af68";
           	     blue = "#7aa2f7";
           	     magenta = "#bb9af7";
           	     cyan = "#7dcfff";
           	     white = "#c0caf5";
           	   };

           	   indexed_colors = [
           	     {
           	       index = 16;
           	       color = "#ff9e64";
           	     }
           	     {
           	       index = 17;
           	       color = "#db4b4b";
           	     }
           	   ];
           	 };
           	 live_config_reload = true;
		};
	};
}
