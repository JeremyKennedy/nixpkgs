# Only used for RISC-V
{ callPackage }:
callPackage ./binary.nix {
  version = "1.18.6";
  hashes = {
    linux-riscv64 = "sha256-I3M142J1ifK1rUQWe4kgwwMhaKoa2MLc92RjuATGD2c=";
  };
  urls = {
    linux-riscv64 = "https://dev.gentoo.org/~williamh/dist/go-linux-riscv64-bootstrap-1.18.6.tbz";
  };
}
