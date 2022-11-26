{ lib, stdenvNoCC, fetchFromGitHub, python3, makeWrapper, unstableGitUpdater, nixosTests }:

let
  pythonEnv = python3.withPackages (packages: with packages; [
    tornado
    pyserial-asyncio
    pillow
    lmdb
    streaming-form-data
    distro
    inotify-simple
    libnacl
    paho-mqtt
    pycurl
    zeroconf
    preprocess-cancellation
    jinja2
    dbus-next
    apprise
  ]);
in stdenvNoCC.mkDerivation rec {
  pname = "moonraker";
  version = "unstable-2022-11-22";

  src = fetchFromGitHub {
    owner = "Arksine";
    repo = "moonraker";
    rev = "b67a08a65b3137935c6dc9e936286a4e4077fc0f";
    sha256 = "sha256-WLZF/qD3D9WLDL4fYBE8HWXWKSTX9a16b5FY5P9Bqzg=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p $out $out/bin $out/lib
    cp -r moonraker $out/lib

    makeWrapper ${pythonEnv}/bin/python $out/bin/moonraker \
      --add-flags "$out/lib/moonraker/moonraker.py"
  '';

  passthru = {
    updateScript = unstableGitUpdater { url = meta.homepage; };
    tests.moonraker = nixosTests.moonraker;
  };

  meta = with lib; {
    description = "API web server for Klipper";
    homepage = "https://github.com/Arksine/moonraker";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ zhaofengli ];
  };
}
