{
  description = "";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    zig-overlay.url = "github:mitchellh/zig-overlay";
  };

  outputs = { self, nixpkgs, zig-overlay, flake-utils, ... } @ inputs : flake-utils.lib.eachDefaultSystem (
    system: let
      overlays = [
        zig-overlay.overlays.default
      ];

      pkgs = import nixpkgs { inherit system overlays; };

      llvmPackages = pkgs.llvmPackages_21;
    in {
      devShells.default = pkgs.mkShell rec {
        packages = (with pkgs; [
          zigpkgs.master
          zls

          ripgrep cmake-language-server
          pkg-config cmake ninja codespell
          lldb valgrind

          spirv-tools

          # required by zig
          zstd
        ]) ++ (with llvmPackages; [
          # see: https://blog.kotatsu.dev/posts/2024-04-10-nixpkgs-clangd-missing-headers/
          # reordering didn't help but bringing clang-tools to the front in `shellHook` did.
          clang-tools
          clang
          clang-unwrapped.dev

          libclang
          libcxx
          lld
          llvm
        ]);

        nativeBuildInputs = packages;

        LD_LIBRARY_PATH = "${nixpkgs.lib.makeLibraryPath nativeBuildInputs}";

        shellHook = ''
          export LIBCLANG_PATH="${llvmPackages.libclang.lib}/lib";
          export PATH="${llvmPackages.clang-tools}/bin:$PATH"
        '';
        # export LIBSTDCPP_PATH="${pkgs.gcc}/lib/libstdc++.so.6";
      };

      devShell = self.devShells.${system}.default;
    }
  );
}

