{
  description = "PlayPhrase - Search and play video clips by phrase";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        runtimeDeps = with pkgs; [
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
          mpv
          libepoxy
        ];
        
        buildDeps = with pkgs; [
          flutter
          pkg-config
          clang
          cmake
          ninja
          sysprof
        ] ++ runtimeDeps;
      in
      {
        packages.default = pkgs.flutter.buildFlutterApplication {
          pname = "playphrase";
          version = "1.0.0";
          
          src = ./.;
          
          pubspecLock = pkgs.lib.importJSON ./pubspec.lock.json;
          
          nativeBuildInputs = with pkgs; [
            pkg-config
            makeWrapper
          ];
          
          buildInputs = runtimeDeps;
          
          extraWrapProgramArgs = ''
            --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath runtimeDeps}
          '';
          
          meta = with pkgs.lib; {
            description = "PlayPhrase - Search and play video clips by phrase";
            license = licenses.mit;
            platforms = platforms.linux;
            mainProgram = "PlayPhrase";
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = buildDeps ++ [ pkgs.chromium pkgs.mesa-demos ];
          
          shellHook = ''
            export CHROME_EXECUTABLE="${pkgs.chromium}/bin/chromium"
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath runtimeDeps}:$LD_LIBRARY_PATH"
          '';
        };
      }
    );
}
