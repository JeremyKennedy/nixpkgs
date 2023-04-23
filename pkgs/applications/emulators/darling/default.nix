{ clangStdenv
, lib
, runCommandWith
, writeShellScript
, fetchFromGitHub
, fetchpatch

, freetype
, libjpeg
, libpng
, libtiff
, giflib
, libX11
, libXext
, libXrandr
, libXcursor
, libxkbfile
, cairo
, libglvnd
, fontconfig
, dbus
, libGLU
, fuse
, ffmpeg
, pulseaudio

, makeWrapper
, python2
, python3
, cmake
, ninja
, pkg-config
, bison
, flex

, libbsd
, openssl

, xdg-user-dirs

, addOpenGLRunpath

# Whether to pre-compile Python 2 bytecode for performance.
, compilePy2Bytecode ? false
}:
let
  stdenv = clangStdenv;

  # The build system invokes clang to compile Darwin executables.
  # In this case, our cc-wrapper must not be used.
  ccWrapperBypass = runCommandWith {
    inherit stdenv;
    name = "cc-wrapper-bypass";
    runLocal = false;
    derivationArgs = {
      template = writeShellScript "template" ''
        for (( i=1; i<=$#; i++)); do
          j=$((i+1))
          if [[ "''${!i}" == "-target" && "''${!j}" == *"darwin"* ]]; then
            # their flags must take precedence
            exec @unwrapped@ "$@" $NIX_CFLAGS_COMPILE
          fi
        done
        exec @wrapped@ "$@"
      '';
    };
  } ''
    unwrapped_bin=${stdenv.cc.cc}/bin
    wrapped_bin=${stdenv.cc}/bin

    mkdir -p $out/bin

    unwrapped=$unwrapped_bin/$CC wrapped=$wrapped_bin/$CC \
      substituteAll $template $out/bin/$CC
    unwrapped=$unwrapped_bin/$CXX wrapped=$wrapped_bin/$CXX \
      substituteAll $template $out/bin/$CXX

    chmod +x $out/bin/$CC $out/bin/$CXX
  '';

  wrappedLibs = [
    # src/native/CMakeLists.txt
    freetype
    libjpeg
    libpng
    libtiff
    giflib
    libX11
    libXext
    libXrandr
    libXcursor
    libxkbfile
    cairo
    libglvnd
    fontconfig
    dbus
    libGLU

    # darling-dmg
    fuse

    # CoreAudio
    ffmpeg
    pulseaudio
  ];
in stdenv.mkDerivation {
  pname = "darling";
  version = "unstable-2023-04-26";

  src = fetchFromGitHub {
    owner = "darlinghq";
    repo = "darling";
    rev = "410e215184d85b78edd7dbac911a2d398b1def98";
    fetchSubmodules = true;
    hash = "sha256-dt6uyAMRAYMGyVxh8uNvRdNdHY5GzU4Hv0/m+mseuao=";
  };

  patches = [
    # Fixes incorrect assumption during ELF parsing
    # https://github.com/darlinghq/darling/pull/1355
    (fetchpatch {
      url = "https://github.com/darlinghq/darling/commit/8fa8c70d7db7db4be140ecb0758f78d13e72de2a.patch";
      hash = "sha256-gxXeNNutvEplpX8Wj2Sd17BxBWds+fmYo4vxs2Ip7vk=";
    })

    # Removes libm's reference to /nix/store
    # https://github.com/darlinghq/darling/pull/1358
    (fetchpatch {
      url = "https://github.com/darlinghq/darling/commit/ce466ff2964e0ad17e960d98e3b08d16700d0dac.patch";
      hash = "sha256-X1AIvphz1R1KZfyzNBSJnHW4Sml+qm6l5D/8R0h0Pco=";
    })

    # Fixes nano sysconfdir inside the sandbox
    # https://github.com/darlinghq/darling-nano/pull/1
    (fetchpatch {
      url = "https://github.com/darlinghq/darling-nano/commit/37841db50b9d19cc97c9f87c8487090cf9b50580.patch";
      hash = "sha256-7I9sblPqna3EHTJvvZi2yUk2O4RTNtttU2Q8dhfd0QU=";
      stripLen = 1;
      extraPrefix = "src/external/nano/";
    })

    # Allows pinning the xdg-user-dir executable
    # https://github.com/darlinghq/darlingserver/pull/10
    (fetchpatch {
      url = "https://github.com/darlinghq/darlingserver/commit/21e3c369049ea0b44dd4f26a42e407b3dda4719f.patch";
      hash = "sha256-DHYCJ2CnZFphhkoIIN71Bd/NeKSpgtM+4RMzN5GzXB0=";
      stripLen = 1;
      extraPrefix = "src/external/darlingserver/";
    })
  ];

  postPatch = ''
    # We have to be careful - Patching everything indiscriminately
    # would affect Darwin scripts as well
    chmod +x src/external/bootstrap_cmds/migcom.tproj/mig.sh
    patchShebangs \
      src/external/bootstrap_cmds/migcom.tproj/mig.sh \
      src/external/darlingserver/scripts \
      src/external/openssl_certificates/scripts

    substituteInPlace src/startup/CMakeLists.txt --replace SETUID ""
    substituteInPlace src/external/basic_cmds/CMakeLists.txt --replace SETGID ""
  '';

  nativeBuildInputs = [
    bison
    ccWrapperBypass
    cmake
    flex
    makeWrapper
    ninja
    pkg-config
    python3
  ]
  ++ lib.optional compilePy2Bytecode python2;
  buildInputs = wrappedLibs ++ [
    libbsd
    openssl
    stdenv.cc.libc.linuxHeaders
  ];

  # Breaks valid paths like
  # Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include
  dontFixCmake = true;

  # src/external/objc4 forces OBJC_IS_DEBUG_BUILD=1, which conflicts with NDEBUG
  # TODO: Fix in a better way
  cmakeBuildType = " ";

  cmakeFlags = [
    "-DTARGET_i386=OFF"
    "-DCOMPILE_PY2_BYTECODE=${if compilePy2Bytecode then "ON" else "OFF"}"
    "-DDARLINGSERVER_XDG_USER_DIR_CMD=${xdg-user-dirs}/bin/xdg-user-dir"
  ];

  env.NIX_CFLAGS_COMPILE = "-Wno-macro-redefined -Wno-unused-command-line-argument";

  # Linux .so's are dlopen'd by wrapgen during the build
  env.LD_LIBRARY_PATH = lib.makeLibraryPath wrappedLibs;

  # Breaks shebangs of Darwin scripts
  dontPatchShebangs = true;

  postFixup = ''
    echo "Checking for references to $NIX_STORE in Darling root..."

    set +e
    grep -r --exclude=mldr "$NIX_STORE" $out/libexec/darling
    ret=$?
    set -e

    if [[ $ret == 0 ]]; then
      echo "Found references to $NIX_STORE in Darling root (see above)"
      exit 1
    fi

    patchelf --add-rpath "${lib.makeLibraryPath wrappedLibs}:${addOpenGLRunpath.driverLink}/lib" \
      $out/libexec/darling/usr/libexec/darling/mldr
  '';

  meta = with lib; {
    description = "Open-source Darwin/macOS emulation layer for Linux";
    homepage = "https://www.darlinghq.org";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ zhaofengli ];
    platforms = [ "x86_64-linux" ];
  };
}
