{ stdenv, pkgs, lib, fetchFromGitHub, makeWrapper, buildEnv, nodejs, nodePackages }:

stdenv.mkDerivation rec {
  name = "bgpalerter";
  version = "1.28.1";

  src = fetchFromGitHub {
    owner = "nttgin";
    repo = "BGPalerter";
    rev = "v${version}";
    sha256 = "sha256-Y0atkJfZxjUOGPQ3goXS/YD5SsX9ZjpbM0Nc5IuaFP4=";
  };

  nativeBuildInputs = [ makeWrapper nodejs ];

  buildDependencies = nodePackages.fetchNodeModules {
    inherit src;
    makeTarball = false;
    production = false;
    sha256 = "sha256-+FzVzpa1JwQ4vzBpgpwp44KSu59luNbamZxPl4cgct4=";
  };

  runtimeDependencies = nodePackages.fetchNodeModules {
    inherit src;
    makeTarball = false;
    production = true;
    sha256 = "sha256-Ukw2ntLV+yFiruhazCExxUYv46NmXk3OJ9CoKMDq1WA=";
  };

  buildPhase = ''
    runHook preBuild

    export PATH=${nodejs}/bin:$PATH
    ln -s ${buildDependencies}/lib/node_modules node_modules

    node ./node_modules/.bin/babel index.js -d dist
    node ./node_modules/.bin/babel src -d dist/src
    cp package.json dist/package.json

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share
    cp -r dist $out/share/bgpalerter

    makeWrapper '${nodejs}/bin/node' "$out/bin/bgpalerter" \
      --set NODE_PATH "${runtimeDependencies}/lib/node_modules" \
      --add-flags "$out/share/bgpalerter/index.js"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Self-configuring BGP monitoring tool";
    homepage = "https://github.com/nttgin/BGPalerter";
    license = licenses.bsd3;
    maintainers = with maintainers; [ zhaofengli ];
  };
}
