{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    programs.darling = {
      enable = mkOption {
        default = false;
        type = types.bool;
        description = lib.mdDoc ''
          Whether to set up Darling, a Darwin/macOS compatibility layer
          for Linux.
        '';
      };
    };
  };

  config = mkIf config.programs.darling.enable {
    security.wrappers.darling = {
      source = "${pkgs.darling}/bin/darling";
      owner = "root";
      group = "root";
      setuid = true;
    };
  };
}
