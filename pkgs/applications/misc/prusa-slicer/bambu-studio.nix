{ lib, fetchFromGitHub, fetchpatch, prusa-slicer
, curl
, wxGTK31
, glfw
, glib-networking
, mesa
, webkitgtk
, wrapGAppsHook
, makeShellWrapper
}:
let
  wxGTK31' = wxGTK31.overrideAttrs (old: {
    configureFlags = old.configureFlags ++ [
      # Disable noisy debug dialogs
      "--enable-debug=no"
    ];
  });

  versions = {
    official = rec {
      version = "unstable-2022-12-16";

      src = fetchFromGitHub {
        owner = "bambulab";
        repo = "BambuStudio";
        rev = "73679f6f2e1111cfeefba146f2897d2d593ae452";
        hash = "sha256-j66FE81S7GNg7KyiBbLc5RvfHIkBAcxDQvQ99/ipzKM=";
      };

      patches = [
        # Fix for webkitgtk linking
        ./0001-not-for-upstream-CMakeLists-Link-against-webkit2gtk-.patch
      ];
    };

    # TODO: SoftFever
  };

  override = { version, src, patches ? [], ... } @ args: super: rec {
    pname = "bambu-studio";
    inherit version src patches;

    buildInputs = super.buildInputs ++ [
      glfw
      glib-networking
      mesa.osmesa
      webkitgtk
    ];

    prePatch = ''
      # Since version 2.5.0 of nlopt we need to link to libnlopt, as libnlopt_cxx
      # now seems to be integrated into the main lib.
      sed -i 's|nlopt_cxx|nlopt|g' cmake/modules/FindNLopt.cmake
    '';

    cmakeFlags = super.cmakeFlags ++ [
      "-DBBL_RELEASE_TO_PUBLIC=1"
      "-DBBL_INTERNAL_TESTING=0"
      "-DDEP_WX_GTK3=ON"
      "-DSLIC3R_BUILD_TESTS=0"
      "-DCMAKE_CXX_FLAGS=-DBOOST_LOG_DYN_LINK"
    ];

    postInstall = null;

    preFixup = (super.preFixup or "") + ''
      gappsWrapperArgs+=(
        # ~/.config/BambuStudio needs to exist, otherwise the app segfaults
        --run "mkdir -p \"\''${XDG_CONFIG_HOME:-\$HOME/.config}/BambuStudio\""
      )
    '';

    passthru = allVersions;

    meta = with lib; {
      description = "PC Software for BambuLab's 3D printers";
      homepage = "https://github.com/bambulab/BambuStudio";
      license = licenses.agpl3;
      maintainers = with maintainers; [ zhaofengli ];
      mainProgram = "bambu-studio";
    };
  } // args;

  prusa-slicer' = prusa-slicer.override {
    # We use --run in makeWrapper
    wrapGAppsHook = wrapGAppsHook.override {
      makeWrapper = makeShellWrapper;
    };
    wxGTK31-override = wxGTK31';

    inherit curl;
  };

  allVersions = builtins.mapAttrs (_name: version: (prusa-slicer'.overrideAttrs (override version))) versions;
in allVersions.official
