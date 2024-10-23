{ pkgs, config, ... }: {
  system.defaults = {
    dock.autohide = true;
    dock.persistent-apps = [
      "${pkgs.alacritty}/Applications/Alacritty.app"
    ];
    loginwindow.GuestEnabled = false;
    NSGlobalDomain = {
      "com.apple.mouse.tapBehavior" = 1;
      _HIHideMenuBar = true;
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;
    };
  };

  system.activationScripts.applications.text = let
    env = pkgs.buildEnv {
      name = "system-applications";
      paths = config.environment.systemPackages;
      pathsToLink = "/Applications";
    };
  in
    pkgs.lib.mkForce ''
      echo "setting up /Applications..." >&2
      rm -rf /Applications/Nix\ Apps
      mkdir -p /Applications/Nix\ Apps
      find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
      while read src; do
        app_name=$(basename "$src")
        echo "copying $src" >&2
        ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
      done
    '';
}
