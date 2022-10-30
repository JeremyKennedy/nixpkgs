{ lib, stdenv, fetchFromGitHub
, cmake
, gtest
, pkg-config
, jack2
, pulseaudio
, sndio
, speexdsp
, CoreAudio
, CoreServices
, lazyLoad ? true
}:

let
  version = "unstable-2022-10-18";
  rev = "27d2a102b0b75d9e49d43bc1ea516233fb87d778";
  hash = "sha256-q+uz1dGU4LdlPogL1nwCR/KuOX4Oy3HhMdA6aJylBRk=";

  backendLibs = if stdenv.isDarwin then [
    CoreAudio
  ] else [
    jack2
    pulseaudio
    sndio
    speexdsp
  ];
in stdenv.mkDerivation {
  pname = "cubeb";
  inherit version;

  src = fetchFromGitHub {
    owner = "mozilla";
    repo = "cubeb";
    inherit rev hash;
  };

  nativeBuildInputs = [
    cmake
    gtest
    pkg-config
  ];

  buildInputs = backendLibs
    ++ lib.optional stdenv.isDarwin CoreServices;

  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=ON"
    "-DBUNDLE_SPEEX=OFF"
    "-DUSE_SANITIZERS=OFF"

    # Whether to lazily load libraries with dlopen()
    "-DLAZY_LOAD_LIBS=${if lazyLoad then "ON" else "OFF"}"
  ];

  passthru = {
    # For downstream users when lazyLoad is true
    inherit backendLibs;
  };

  meta = with lib; {
    description = "Cross platform audio library";
    homepage = "https://github.com/mozilla/cubeb";
    license = licenses.isc;
    platforms = platforms.linux ++ platforms.darwin;
    maintainers = with maintainers; [ zhaofengli ];
  };
}
