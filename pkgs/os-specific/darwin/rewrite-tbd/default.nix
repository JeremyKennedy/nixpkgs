{ stdenv, lib, fetchFromGitHub, cmake, pkg-config, libyaml }:

stdenv.mkDerivation {
  pname = "rewrite-tbd";
  version = "20230326";

  src = fetchFromGitHub {
    owner = "thefloweringash";
    repo = "rewrite-tbd";
    rev = "d7852691762635028d237b7d00c3dc6a6613de79";
    hash = "sha256-syxioFiGvEv4Ypk5hlIjLQth5YmdFdr+NC+aXSXzG4k=";
  };

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [ libyaml ];

  meta = with lib; {
    homepage = "https://github.com/thefloweringash/rewrite-tbd/";
    description = "Rewrite filepath in .tbd to Nix applicable format";
    platforms = platforms.unix;
    license = licenses.mit;
  };
}
