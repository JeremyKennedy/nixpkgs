{ lib
, python3Packages
, fetchFromGitHub
}:

python3Packages.buildPythonPackage rec {
  pname = "mlat-client";
  version = "0.2.12";

  src = fetchFromGitHub {
    owner = "mutability";
    repo = "mlat-client";
    rev = "v${version}";
    hash = "sha256-kU7DJ6lPwz+mVlp4g7rDz0TTSzsZvd/KxjHbYsDFLPI=";
  };

  meta = with lib; {
    description = "Mode S multilateration client";
    homepage = "https://github.com/mutability/mlat-client";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ zhaofengli ];
    platforms = platforms.linux;
  };
}
