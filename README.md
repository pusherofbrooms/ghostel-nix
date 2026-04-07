# ghostel-nix

Local flake packaging for [ghostel](https://github.com/dakra/ghostel).

## What it does

- fetches upstream `dakra/ghostel` from GitHub
- includes git submodules (`vendor/ghostty`)
- builds the native Zig module during the Nix build
- installs the Emacs Lisp files and the compiled module together

## Build

```sh
nix build .#ghostel
```

## Use as an overlay

```nix
{
  inputs.ghostel-nix.url = "github:pusherofbrooms/ghostel-nix";

  outputs = { self, nixpkgs, ghostel-nix, ... }: {
    nixpkgs.overlays = [ ghostel-nix.overlays.default ];
  };
}
```

Then include it in your Emacs package set as `epkgs.ghostel`.

## Notes

This is a first-pass package. If upstream changes build layout or module lookup,
it may need small adjustments.

On Darwin, this package carries small patches against the vendored `ghostty`
build logic so Zig uses the Nix-provided SDK (`SDKROOT`) instead of relying on
host Apple SDK discovery.
