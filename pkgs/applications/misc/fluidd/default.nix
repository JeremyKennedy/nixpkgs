{ lib, pkgs, stdenvNoCC, fetchFromGitHub, nodejs, nodePackages }:

let
  rev = "c01a473bbaede2a980dd94a3f7f7cc9ceeecc339";

  src = fetchFromGitHub {
    owner = "zhaofengli";
    repo = "fluidd";
    inherit rev;
    sha256 = "0rwbc6h8gqc9gs6rzgw7h1y6z0087zwb5yqb0xmzapnp39h58nhq";
  };

  # vue.config.js attempts to run `git rev-parse --short HEAD`
  # sorry about this :/
  fakegit = pkgs.writeScriptBin "git" ''
    #!${pkgs.runtimeShell}
    echo ${builtins.substring 0 7 rev}
  '';

  buildDeps = nodePackages.fetchNodeModules {
    inherit src;
    makeTarball = false;
    production = false;
    sha256 = "12lj3k4msiw4bpdx5i1n70jaylcgrhj65nri298d4zjj3wr7r4d1";
  };
in stdenvNoCC.mkDerivation rec {
  pname = "fluidd";
  version = "unstable-2021-07-18";

  inherit src;

  dontConfigure = true;

  buildPhase = ''
    ln -s ${buildDeps}/lib/node_modules node_modules
    PATH=${fakegit}/bin:$PATH ${nodejs}/bin/node node_modules/.bin/vue-cli-service build
  '';

  installPhase = ''
    mkdir -p $out/share/fluidd/htdocs
    cp -r dist/* $out/share/fluidd/htdocs
  '';

  meta = with lib; {
    description = "Klipper web interface";
    homepage = "https://docs.fluidd.xyz";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ zhaofengli ];
  };
}
