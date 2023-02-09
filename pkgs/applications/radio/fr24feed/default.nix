{ lib
, stdenv
, fetchurl
}:

stdenv.mkDerivation {
  pname = "fr24feed";
  version = "1.0.34";

  src = fetchurl {
    url = "https://repo-feed.flightradar24.com/linux_x86_64_binaries/fr24feed_1.0.34-0_amd64.tgz";
    hash = "sha256-baXxzua3EDqzXAAWAikynTHOW3XxGchTHtIoWS2xXWc=";
  };

  dontConfigure = true;
  dontBuild = true;

  postPatch = ''
    # attempts to run shell commands via `/bin/bash`
    sed -i 's|/bin/bash\x0|/bin/sh\x0\x0\x0|g' fr24feed
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp fr24feed $out/bin

    mkdir -p $out/share/doc/fr24feed
    cp -r licences/* $out/share/doc/fr24feed

    runHook postInstall
  '';

  meta = with lib; {
    description = "Flightradar24 data sharing software";
    homepage = "https://www.flightradar24.com/share-your-data";
    license = licenses.unfree;
    maintainers = with maintainers; [ zhaofengli ];
    platforms = [ "x86_64-linux" ];
  };
}
