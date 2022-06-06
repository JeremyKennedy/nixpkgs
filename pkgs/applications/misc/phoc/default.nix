{ lib
, stdenv
, fetchFromGitLab
, fetchpatch
, meson
, ninja
, pkg-config
, python3
, wrapGAppsHook
, libinput
, gnome
, gnome-desktop
, glib
, gtk3
, wayland
, libdrm
, libxkbcommon
, wlroots
}:

let
  phocWlroots = wlroots.overrideAttrs (old: {
    patches = (old.patches or []) ++ [
      # Temporary fix. Upstream report: https://source.puri.sm/Librem5/phosh/-/issues/422
      ./0001-Revert-layer-shell-error-on-0-dimension-without-anch.patch

      # wlr_output_layout_contains_point: handle outputs that aren't in the layout
      # https://gitlab.freedesktop.org/wlroots/wlroots/-/commit/13fcdba75cf5
      ./0002-handle-outputs-that-arent-in-the-layout.patch

      # seat: Allow to cancel touches
      (fetchpatch {
        name = "seat-Allow-to-cancel-touches.patch";
        url = "https://gitlab.freedesktop.org/wlroots/wlroots/-/commit/17b2b0663372.patch";
        sha256 = "sha256-BAeXa3ZB5TXnlq0ZP2+rZlVXEPWpLP4Wi4TLwoXjkz4=";
      })

      # xdg-activation: Deduplicate token creation code
      (fetchpatch {
        name = "xdg-activation-deduplicate-token-creation-code.patch";
        url = "https://gitlab.freedesktop.org/wlroots/wlroots/-/commit/dd03d839ab56.patch";
        sha256 = "sha256-mxt68MISC24xpaBtVSc1F2W4cyNs5wQowtbUQH9Eqr8=";
      })
    ];
  });
in stdenv.mkDerivation rec {
  pname = "phoc";
  version = "0.20.0";

  src = fetchFromGitLab {
    domain = "gitlab.gnome.org";
    group = "World";
    owner = "Phosh";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-3mfYhKMTa9idWU7VWkF6/r9+twcNrL36zU/O04s9pNY=";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    python3
    wrapGAppsHook
  ];

  buildInputs = [
    libdrm.dev
    libxkbcommon
    libinput
    glib
    gtk3
    gnome-desktop
    # For keybindings settings schemas
    gnome.mutter
    wayland
    phocWlroots
  ];

  mesonFlags = ["-Dembed-wlroots=disabled"];

  postPatch = ''
    chmod +x build-aux/post_install.py
    patchShebangs build-aux/post_install.py
  '';

  meta = with lib; {
    description = "Wayland compositor for mobile phones like the Librem 5";
    homepage = "https://gitlab.gnome.org/World/Phosh/phoc";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ masipcat zhaofengli ];
    platforms = platforms.linux;
  };
}
