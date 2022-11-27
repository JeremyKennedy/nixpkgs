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
      version = "1.3.0.25";

      src = fetchFromGitHub {
        owner = "bambulab";
        repo = "BambuStudio";
        rev = "v${version}";
        hash = "sha256-yaJr3rwkUKS7Ct6qf7irxjoX1ZBoQJLG1H8YKGeRJmY=";
      };

      patches = [
        # Various fixes to be upstreamed
        (fetchpatch {
          url = "https://github.com/zhaofengli/BambuStudio/compare/96707fc4b4b40c30b7e5610d2489ef283fe952a4...897d035d85b5b4e4a9e708551c6b9854c37139f6.patch";
          hash = "sha256-uQdOjbgny9HBD0ZX52kJLBLeAtotTQBEvtRgW4PT+aY=";
        })

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

    cmakeFlags = super.cmakeFlags ++ [
      "-DBBL_RELEASE_TO_PUBLIC=1"
      "-DBBL_INTERNAL_TESTING=0"
      "-DDEP_WX_GTK3=ON"
      "-DSLIC3R_BUILD_TESTS=0"
    ];

    postInstall = null;

    preFixup = (super.preFixup or "") + ''
      gappsWrapperArgs+=(
        --suffix XDG_DATA_DIRS : "$out/share/BambuStudio"

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
