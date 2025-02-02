{ ... }: {
  homebrew = {
    enable = true;
    brews = [
      "mas"
    ];
    casks = [
      "cloudflare-warp"
      "font-hack-nerd-font"
      "stremio"
    ];
    masApps = {
      "Ghostery" = 6504861501;
      "Proton Pass Safari" = 6502835663;
    };

    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };
  };
}
