{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.programs.darling;
in {
  options = {
    programs.darling = {
      enable = mkEnableOption (lib.mdDoc "Darling, a Darwin/macOS compatibility layer for Linux");
      package = mkPackageOptionMD pkgs "darling" {};
    };
  };

  config = mkIf cfg.enable {
    security.wrappers.darling = {
      source = lib.getExe cfg.package;
      owner = "root";
      group = "root";
      setuid = true;
    };
  };
}
