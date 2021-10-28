# binfmt preserve-argv[0] wrapper
#
# See comments in binfmt-p-wrapper.c

{ lib, stdenv, pkgsStatic, enableDebug ? false }:

name: emulator:

pkgsStatic.stdenv.mkDerivation {
  inherit name;

  src = ./binfmt-p-wrapper.c;

  dontUnpack = true;
  dontInstall = true;

  buildPhase = ''
    runHook preBuild
    $CC -o $out -static -std=c99 -O2 \
        -DTARGET_QEMU=\"${emulator}\" \
        ${lib.optionalString enableDebug "-DDEBUG"} \
        $src
    runHook postBuild
  '';
}
