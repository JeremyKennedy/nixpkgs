{ lib, fetchFromGitHub, fetchpatch, makeDesktopItem, prusa-slicer
, wxGTK31
, glfw
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

  override = super: rec {
    pname = "bambu-studio";
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

    buildInputs = super.buildInputs ++ [
      glfw
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
  };

  prusa-slicer' = prusa-slicer.override {
    # We use --run in makeWrapper
    wrapGAppsHook = wrapGAppsHook.override {
      makeWrapper = makeShellWrapper;
    };
    wxGTK31-override = wxGTK31';
  };
in prusa-slicer'.overrideAttrs override
