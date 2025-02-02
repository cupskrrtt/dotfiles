{ pkgs, ... }: {
  environment.systemPackages = [
    pkgs.neovim
    pkgs.tmux
    pkgs.mkalias
    pkgs.alacritty
    pkgs.starship
    pkgs.rqbit
  ];
}
