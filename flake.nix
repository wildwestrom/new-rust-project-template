{
  description = "Rust flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    rust-overlay.url = "github:oxalica/rust-overlay";
    devenv.url = "github:cachix/devenv";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    {
      self,
      nixpkgs,
      devenv,
      systems,
      rust-overlay,
      ...
    }@inputs:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      devShells = forEachSystem (
        system:
        let
          overlays = [ (import rust-overlay) ];
          pkgs = nixpkgs.legacyPackages.${system}.extend (
            final: prev: {
              rustPkgs = import nixpkgs {
                inherit system overlays;
              };
            }
          );
          rust-toolchain = pkgs.rustPkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
        in
        {
          default = devenv.lib.mkShell {
            inherit inputs pkgs;
            modules = [
              {
                stdenv = pkgs.stdenvAdapters.useMoldLinker pkgs.clangStdenv;
                packages = with pkgs; [
                  rust-toolchain
                ];
              }
            ];
          };
        }
      );
    };
}
