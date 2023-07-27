{
  description = "Install and debug iOS apps from the command line. Designed to work on un-jailbroken devices";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };
  outputs = { self, nixpkgs }:
    let
      # The set of systems to provide outputs for
      allSystems = [ "x86_64-darwin" "aarch64-darwin" ];

      # A function that provides a system-specific Nixpkgs for the desired systems
      forAllSystems = f: nixpkgs.lib.genAttrs allSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
      version = "1.12.2";
    in
    {
      packages = forAllSystems ({ pkgs }: {
        default = with pkgs;  stdenvNoCC.mkDerivation {
          pname = "ios-deploy";
          inherit version;
          src = ./.;
          nativeBuildInputs = [ rsync ];
          buildPhase = ''
            LD=$CC
            tmp=$(mktemp -d)
            ln -s /usr/bin/xcodebuild $tmp
            export PATH="$PATH:$tmp"
            xcodebuild -configuration Release SYMROOT=build OBJROOT=$tmp
          '';
          checkPhase = ''
            xcodebuild test -scheme ios-deploy-tests -configuration Release SYMROOT=build
          '';
          installPhase = ''
            install -D build/Release/ios-deploy $out/bin/ios-deploy
          '';
          meta = {
            platforms = lib.platforms.darwin;
            description = "Install and debug iOS apps from the command line. Designed to work on un-jailbroken devices";
            license = lib.licenses.gpl3;
          };
        };
      });
    };
}
