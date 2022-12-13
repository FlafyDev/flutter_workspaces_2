{
  description = "bottom_bar";

  inputs = {
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    dart-flutter = {
      # url = "github:flafydev/dart-flutter-nix";
      url = "path:/mnt/general/repos/flafydev/dart-flutter-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    flake-utils,
    nixpkgs,
    dart-flutter,
  }:
    flake-utils.lib.eachDefaultSystem
    (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          dart-flutter.overlays.default
          self.overlays.default
        ];
      };
    in {
      packages = {
        inherit (pkgs) flutter-workspaces-2;
        default = pkgs.flutter-workspaces-2;
      };
      devShell = pkgs.mkFlutterShell {
        linux = {
          enable = true;
        };
        LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [pkgs.libepoxy];
        nativeBuildInputs = with pkgs; [
          cmake
          ninja
          pkg-config
          wrapGAppsHook
          autoPatchelfHook
          bash
          curl
          flutter.dart
          git
          unzip
          which
          xz
          gtk-layer-shell
          gtk-layer-shell.dev
          gtk3.dev
          gtk3
        ];
        buildInputs = with pkgs; [
          clang-tools
          clang
          gtk-layer-shell
          gtk-layer-shell.dev
          at-spi2-core.dev
          cmake
          dart
          dbus.dev
          flutter
          gtk3.dev
          gtk3
          libdatrie
          libepoxy.dev
          libselinux
          libsepol
          libthai
          libxkbcommon
          ninja
          pcre
          pkg-config
          util-linux.dev
          xorg.libXdmcp
          xorg.libXtst
          gtk3
          glib
          pcre
          pcre2
          util-linux
        ];
      };
    })
    // {
      overlays.default = final: prev: let
        pkgs = import nixpkgs {
          inherit (prev) system;
          overlays = [dart-flutter.overlays.default];
        };
      in {
        flutter-workspaces-2 = pkgs.callPackage ./nix/package.nix {};
      };
    };
}
