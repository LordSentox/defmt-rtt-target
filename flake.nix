{
	description = "Antric vehicle control firmware";
	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/release-24.05";
		rust-overlay = {
			url = "github:oxalica/rust-overlay";
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};

	outputs = { self, nixpkgs, rust-overlay }:
	let
		inherit (nixpkgs) lib;
		systems = ["aarch64-linux" "x86_64-linux"];
		systemClosure = attrs:
			builtins.foldl' (acc: system:
				lib.recursiveUpdate acc (attrs system)) {}
			systems;
	in
	systemClosure (
		system:
		let
			inherit ((builtins.fromTOML (builtins.readFile ./Cargo.toml)).package) name;
			pkgs = import nixpkgs {
				inherit system;
				overlays = [(import rust-overlay)];
			};
			toolchain = (
				pkgs.rust-bin.fromRustupToolchainFile ./rust_toolchain.toml
			);
			rustPlatform =
			let
				pkgsCross = import nixpkgs {
					inherit system;
					crossSystem = {
						inherit system;
						rustc.config = "thumbv7em-none-eabihf";
					};
				};
			in
			pkgsCross.makeRustPlatform {
				rustc = toolchain;
				cargo = toolchain;
			};
		in
		{
			packages.${system}.default = pkgs.callPackage ./derivation.nix {
				inherit name rustPlatform;
			};

			devShells.${system}.default = pkgs.mkShell {
				buildInputs = [
					pkgs.probe-rs
					toolchain
				];
			};
		}
	);
}
