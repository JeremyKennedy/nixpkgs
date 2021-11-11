{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "smali2java";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "AlexeySoshin";
    repo = "smali2java";
    rev = "v${version}";
    sha256 = "sha256-7l+wdXv9sYm5w/20Yu8mnpgif8lQJBVHtF/dENRLWg8=";
  };

  vendorSha256 = "sha256-hotmr4dYWx6Sf+RhI3xY/syA0UPa0CmNYw9h05cxj9g=";
}
