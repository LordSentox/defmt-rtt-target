{ lib, rustPlatform, name }:
(rustPlatform.buildRustPackage) {
	inherit name;
	src = lib.cleanSource ./.;
	cargoLock = {
		lockFile = ./Cargo.lock;
	};
}
