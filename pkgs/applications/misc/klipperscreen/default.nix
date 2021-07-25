{ stdenvNoCC, lib, fetchFromGitHub, python3, gobject-introspection, gtk3, wrapGAppsHook }:

let
  pythonEnv = python3.withPackages (packages: with packages; [
    humanize
    jinja2
    matplotlib
    netifaces
    requests
    websocket-client
    pygobject3
  ]);
in stdenvNoCC.mkDerivation rec {
  pname = "klipperscreen";
  #version = "0.1.6";
  version = "unstable-2021-07-24";

  src = fetchFromGitHub {
    #owner = "jordanruthe";
    #repo = "KlipperScreen";
    #rev = "v${version}";
    #sha256 = "04bys2mbr86p9plyghk5n008kdssv2pap1p8qgmm7gy2amb7jkyw";
    owner = "zhaofengli";
    repo = "KlipperScreen";
    rev = "8341c733efebd833b8abbe4617151648c535b939";
    sha256 = "1c3fr3glj32gps629skv4xw213zj9fqks3z3qp3n5icl1y436g5p";
  };

  buildInputs = [
    pythonEnv
    gtk3
  ];
  nativeBuildInputs = [
    gobject-introspection
    wrapGAppsHook
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin $out/lib
    cp -r $src $out/lib/klipperscreen

    makeWrapper ${pythonEnv}/bin/python $out/bin/klipperscreen \
      --set KS_DIR $out/lib/klipperscreen \
      --set KS_VERSION v$version \
      --add-flags "$out/lib/klipperscreen/screen.py"
  '';

  meta = with lib; {
    description = "Touchscreen GUI for Klipper-based 3D printers";
    homepage = "https://github.com/jordanruthe/KlipperScreen";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ zhaofengli ];
  };
}
