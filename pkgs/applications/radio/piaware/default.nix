{ lib
, stdenv
, fetchFromGitHub
, tcl
, tcllauncher
, tcllib
, tcltls
, openssl
, which
, coreutils
, iproute2
, dump1090
, mlat-client
}:

stdenv.mkDerivation rec {
  pname = "piaware";
  version = "8.2";

  src = fetchFromGitHub {
    owner = "flightaware";
    repo = "piaware";
    rev = "v${version}";
    hash = "sha256-La0J+6Y0cWr6fTr0ppzYV6Vq00GisyDxmSyGzR7nfpg=";
  };

  buildInputs = [
    tcl
    tcllauncher
    tcllib
    tcltls
  ];

  nativeBuildInputs = [
    tcl.tclPackageHook
    openssl
    which
  ];

  postPatch = ''
    # uname: Used to generate informational message (hardcoded)
    # ip: Used to obtain MAC address for unique feeder ID (hardcoded)
    # netstat: Used to determine whether helper processes are listening (from PATH)
    find . -type f -name '*.tcl' -print0 | xargs -0 \
      sed -i \
        -e 's|/bin/uname|${coreutils}/bin/uname|g' \
        -e 's|/sbin/ip|${iproute2}/bin/ip|g' \
        -e "s|/usr/lib/piaware/helpers|$out/lib/piaware/helpers|g"
  '';

  installFlags = [ "PREFIX=$(out)" ];

  postInstall = ''
    ln -s ${dump1090}/bin/faup1090 $out/lib/piaware/helpers/faup1090
    ln -s ${mlat-client}/bin/fa-mlat-client $out/lib/piaware/helpers/fa-mlat-client

    # HACK for tcllauncher
    while IFS= read -d "" executable; do
      if [ -d "$out/lib/$executable" ]; then
        ln -s "$out/lib/$executable" "$out/lib/.$executable-wrapped"
      fi
    done < <(find "$out/bin" -executable -type f -printf "%f\0")
  '';

  meta = with lib; {
    description = "Client-side package and programs for forwarding ADS-B data to FlightAware";
    homepage = "https://github.com/flightaware/piaware";
    license = licenses.bsd2;
    platforms = platforms.unix;
    maintainers = with maintainers; [ zhaofengli ];
  };
}
