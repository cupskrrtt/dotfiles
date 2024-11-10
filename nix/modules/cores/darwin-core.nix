{ pkgs, ... }: {
	services.nix-daemon.enable = true;
	nix.settings.experimental-features = "nix-command flakes";
	programs.zsh.enable = true;
	system.stateVersion = 5;
	nixpkgs.hostPlatform = "aarch64-darwin";
}
