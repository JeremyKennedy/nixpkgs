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
      version = "unstable-2022-12-19";

      src = fetchFromGitHub {
        owner = "bambulab";
        repo = "BambuStudio";
        rev = "e32792c305b6ab4c42ce537b88fefa394066cf91";
        hash = "sha256-5Irsk1c4ybSMIFrCEs8XvfeyRnv0rI7qpn19KuYlhwo=";
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
    wxGTK31-override = wxGTK31';

    inherit curl;
  };

  allVersions = builtins.mapAttrs (_name: version: (prusa-slicer'.overrideAttrs (override version))) versions;
in allVersions.official
