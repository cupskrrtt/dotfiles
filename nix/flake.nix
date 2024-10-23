{
  description = "cupskrrtt nix config (for now darwin)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, home-manager }: 
  let
    system = "aarch64-darwin";
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."Eclair" = nix-darwin.lib.darwinSystem {
      modules = [ 
        	./modules/packages/darwin-package.nix
        	./modules/systems/darwin-system.nix
        	./modules/darwin/homebrew.nix
      		./modules/cores/darwin-core.nix
		nix-homebrew.darwinModules.nix-homebrew
		home-manager.darwinModules.home-manager
		{
			home-manager.useGlobalPkgs = true;
          		home-manager.useUserPackages = true;
			home-manager.extraSpecialArgs = { inherit inputs; };
          		home-manager.users.cupskrrtt = import ./home;

			nix-homebrew = {
				enable = true;

				# Apple Silicon Only
				enableRosetta = true;

				# User owning the Homebrew prefix
				user = "cupskrrtt";
			};
		}
	];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."Eclair".pkgs;
  };
}
