{
  description = "PlayPhrase - Development Shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            flutter
            pkg-config
            # Linux desktop development
            gtk3
            glib
            pcre2
            util-linux
            libselinux
            libsepol
            libthai
            libdatrie
            xorg.libXdmcp
            xorg.libXtst
            libxkbcommon
            dbus
            at-spi2-core
            libsecret
            jsoncpp
            # Web development
            chromium
            # Build tools
            clang
            cmake
            ninja
            # Optional: Mesa utilities for GPU info
            mesa-demos
          ];
          
          shellHook = ''
            export CHROME_EXECUTABLE="${pkgs.chromium}/bin/chromium"
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [
              pkgs.gtk3
              pkgs.glib
              pkgs.pcre2
              pkgs.util-linux
              pkgs.libselinux
              pkgs.libsepol
              pkgs.libthai
              pkgs.libdatrie
              pkgs.xorg.libXdmcp
              pkgs.xorg.libXtst
              pkgs.libxkbcommon
              pkgs.dbus
              pkgs.at-spi2-core
              pkgs.libsecret
              pkgs.jsoncpp
            ]}:$LD_LIBRARY_PATH"
          '';
        };
      }
    );
}
