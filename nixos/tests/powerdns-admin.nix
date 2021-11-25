# Test powerdns-admin with postgres.
import ./make-test-python.nix ({ pkgs, ... }: {
  name = "powerdns-admin";
  meta = with pkgs.lib.maintainers; {
    maintainers = [ Flakebi ];
  };

  nodes.server = { ... }: {
    services.powerdns-admin = {
      enable = true;
      config = ''
        import os
        SALT = "salt"
        SECRET_KEY = "secret key"

        BIND_ADDRESS = '127.0.0.1'
        PORT = 8000
        SQLALCHEMY_DATABASE_URI = 'postgresql://powerdnsadmin@/powerdnsadmin?host=/run/postgresql'
      '';
      extraArgs = [ "-b" "127.0.0.1:8000" ];
    };
    systemd.services.powerdns-admin = {
      after = [ "postgresql.service" ];
      serviceConfig.BindPaths = "/run/postgresql";
    };

    services.postgresql = {
      enable = true;
      ensureDatabases = [ "powerdnsadmin" ];
      ensureUsers = [
        {
          name = "powerdnsadmin";
          ensurePermissions = {
            "DATABASE powerdnsadmin" = "ALL PRIVILEGES";
          };
        }
      ];
    };
  };

  testScript = ''
    server.wait_for_unit("powerdns-admin.service")
    server.wait_until_succeeds("curl -sSf http://127.0.0.1:8000/")
  '';
})
