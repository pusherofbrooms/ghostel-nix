{
  description = "Nix packaging for ghostel with prebuilt native Zig module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ghostel-src = {
      url = "git+https://github.com/dakra/ghostel?submodules=1";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, ghostel-src, ... }:
    let
      lib = nixpkgs.lib;
      systems = lib.systems.flakeExposed;
      forAllSystems = lib.genAttrs systems;

      overlay = final: prev:
        let
          pname = "ghostel";
          version = "unstable";
          buildGhostel = epkgs:
            epkgs.trivialBuild {
              inherit pname version;
              src = ghostel-src;
              packageRequires = [ ];

              nativeBuildInputs = with final; [
                zig
              ] ++ lib.optionals final.stdenv.hostPlatform.isDarwin [
                apple-sdk
                cctools
              ];

              patches = lib.optionals final.stdenv.hostPlatform.isDarwin [
                ./patches/apple-sdk-build.patch
                ./patches/shareddeps-darwin-sdk.patch
              ];

              preBuild = ''
                export HOME="$TMPDIR"
                export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-global-cache"
                export ZIG_LOCAL_CACHE_DIR="$TMPDIR/zig-local-cache"
                export EMACS_INCLUDE_DIR="${epkgs.emacs}/include"
              '' + lib.optionalString final.stdenv.hostPlatform.isDarwin ''
                export SDKROOT="${final.apple-sdk.sdkroot}"
              '' + ''
                ./build.sh
              '';

              postInstall = ''
                module_dir="$out/share/emacs/site-lisp/elpa/${pname}-${version}"
                mkdir -p "$module_dir"
                if [ -f ghostel-module.so ]; then
                  cp ghostel-module.so "$module_dir/"
                elif [ -f ghostel-module.dylib ]; then
                  cp ghostel-module.dylib "$module_dir/"
                else
                  echo "ghostel native module missing after build" >&2
                  exit 1
                fi
              '';

              meta = with final.lib; {
                description = "Emacs terminal emulator powered by libghostty-vt";
                homepage = "https://github.com/dakra/ghostel";
                license = licenses.gpl3Plus;
                platforms = platforms.linux ++ platforms.darwin;
              };
            };
        in
        {
          emacsPackagesFor = emacs:
            (prev.emacsPackagesFor emacs).overrideScope (_finalE: prevE: {
              ghostel = buildGhostel prevE;
            });
        };
    in
    {
      overlays.default = overlay;

      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ overlay ];
          };
        in
        {
          default = (pkgs.emacsPackagesFor pkgs.emacs).ghostel;
          ghostel = (pkgs.emacsPackagesFor pkgs.emacs).ghostel;
        });
    };
}
