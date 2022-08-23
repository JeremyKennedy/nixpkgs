{ lib
, buildDotnetModule
, fetchFromGitHub
, wrapGAppsHook
, libX11
, libgdiplus
, ffmpeg
, openal
, libsoundio
, sndio
, pulseaudio
, gtk3
, gdk-pixbuf
, vulkan-loader
, libICE
, libSM
, libXi
, libXcursor
, libXext
, libXrandr
, fontconfig
, glew
, libGL
, SDL2
, SDL2_mixer
}:

buildDotnetModule rec {
  pname = "ryujinx";
  version = "1.1.227"; # Based off of the official github actions builds: https://github.com/Ryujinx/Ryujinx/actions/workflows/release.yml

  src = fetchFromGitHub {
    owner = "Ryujinx";
    repo = "Ryujinx";
    rev = "54421760c33f77de78fee58d637552d2e00d464b";
    sha256 = "0ndxnfngi8kw9wskvg3pgsl8sw434ra1a4qnc9haznip61h5pzgf";
  };

  nugetDeps = ./deps.nix;

  nativeBuildInputs = [
    wrapGAppsHook
  ];

  buildInputs = [
    gtk3
    gdk-pixbuf
  ];

  runtimeDeps = [
    gtk3
    libX11
    libgdiplus
    SDL2_mixer
    openal
    libsoundio
    sndio
    pulseaudio
    vulkan-loader
    ffmpeg

    # Avalonia UI
    libICE
    libSM
    libXi
    libXcursor
    libXext
    libXrandr
    fontconfig
    glew

    # Headless executable
    libGL
    SDL2
  ];

  patches = [
    ./appdir.patch # Ryujinx attempts to write to the nix store. This patch redirects it to "~/.config/Ryujinx" on Linux.
  ];

  projectFile = "Ryujinx.sln";
  testProjectFile = "Ryujinx.Tests/Ryujinx.Tests.csproj";
  doCheck = true;

  dotnetFlags = [
    "/p:ExtraDefineConstants=DISABLE_UPDATER"
  ];

  executables = [
    "Ryujinx.Headless.SDL2"
    "Ryujinx.Ava"
    "Ryujinx"
  ];

  makeWrapperArgs = [
    # Without this Ryujinx fails to start on wayland. See https://github.com/Ryujinx/Ryujinx/issues/2714
    "--set GDK_BACKEND x11"
    "--set SDL_VIDEODRIVER x11"
  ];

  preInstall = ''
    # workaround for https://github.com/Ryujinx/Ryujinx/issues/2349
    mkdir -p $out/lib/sndio-6
    ln -s ${sndio}/lib/libsndio.so $out/lib/sndio-6/libsndio.so.6
  '';

  preFixup = ''
    mkdir -p $out/share/{applications,icons/hicolor/scalable/apps,mime/packages}
    pushd ${src}/distribution/linux

    install -D ./ryujinx.desktop $out/share/applications/ryujinx.desktop
    install -D ./ryujinx-mime.xml $out/share/mime/packages/ryujinx-mime.xml
    install -D ./ryujinx-logo.svg $out/share/icons/hicolor/scalable/apps/ryujinx.svg

    substituteInPlace $out/share/applications/ryujinx.desktop \
      --replace "Exec=Ryujinx" "Exec=$out/bin/Ryujinx"

    popd
  '';

  passthru.updateScript = ./updater.sh;

  meta = with lib; {
    homepage = "https://ryujinx.org/";
    changelog = "https://github.com/Ryujinx/Ryujinx/wiki/Changelog";
    description = "Experimental Nintendo Switch Emulator written in C#";
    longDescription = ''
      Ryujinx is an open-source Nintendo Switch emulator, created by gdkchan,
      written in C#. This emulator aims at providing excellent accuracy and
      performance, a user-friendly interface and consistent builds. It was
      written from scratch and development on the project began in September
      2017.
    '';
    license = licenses.mit;
    maintainers = with maintainers; [ ivar jk ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "Ryujinx";
  };
}
