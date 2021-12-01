{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.powerdns-admin;
in
{
  options.services.powerdns-admin = {
    enable = mkEnableOption "the PowerDNS web interface";

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [];
      example = literalExpression ''
        [ "-b" "127.0.0.1:8000" ]
      '';
      description = ''
        Extra arguments passed to powerdns-admin.
      '';
    };

    config = mkOption {
      type = types.str;
      default = "";
      example = ''
      '';
      description = ''
        Configuration python file.
        See <link xlink:href="https://github.com/ngoduykhanh/PowerDNS-Admin/blob/v${pkgs.powerdns-admin.version}/configs/development.py">the example configuration</link>
        for options.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services.powerdns-admin = {
      description = "PowerDNS web interface";
      wantedBy = [ "multi-user.target" ];
      after = [ "networking.target" ];

      environment.FLASK_CONF = builtins.toFile "powerdns-admin-config.py" cfg.config;
      environment.PYTHONPATH = pkgs.powerdns-admin.pythonPath;
      serviceConfig = {
        ExecStart = "${pkgs.powerdns-admin}/bin/powerdns-admin --pid /run/powerdns-admin/pid ${escapeShellArgs cfg.extraArgs}";
        ExecStartPre = "${pkgs.coreutils}/bin/env FLASK_APP=${pkgs.powerdns-admin}/share/powerdnsadmin/__init__.py ${pkgs.python3Packages.flask}/bin/flask db upgrade -d ${pkgs.powerdns-admin}/share/migrations";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        ExecStop = "${pkgs.coreutils}/bin/kill -TERM $MAINPID";
        PIDFile = "/run/powerdns-admin/pid";
        RuntimeDirectory = "powerdns-admin";
        User = "powerdnsadmin";
        Group = "powerdnsadmin";

        AmbientCapabilities = "CAP_NET_BIND_SERVICE";
        BindReadOnlyPaths = [
          "/nix/store"
          "-/etc/resolv.conf"
          "-/etc/nsswitch.conf"
          "-/etc/hosts"
          "-/etc/localtime"
        ];
        CapabilityBoundingSet = "CAP_NET_BIND_SERVICE";
        # ProtectClock= adds DeviceAllow=char-rtc r
        DeviceAllow = "";
        # Implies ProtectSystem=strict, which re-mounts all paths
        #DynamicUser = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateMounts = true;
        # Needs to start a server
        #PrivateNetwork = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProcSubset = "pid";
        ProtectClock = true;
        ProtectHome = true;
        ProtectHostname = true;
        # Would re-mount paths ignored by temporary root
        #ProtectSystem = "strict";
        ProtectControlGroups = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        # gunicorn needs setuid
        SystemCallFilter = [ "@system-service" "~@privileged @resources @keyring" "@setuid" "@chown" ];
        TemporaryFileSystem = "/:ro";
        # Does not work well with the temporary root
        #UMask = "0066";
      };
    };

    users.groups.powerdnsadmin = {};
    users.users.powerdnsadmin = {
      description = "PowerDNS web interface user";
      isSystemUser = true;
      group = "powerdnsadmin";
    };
  };
}
