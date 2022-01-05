{ lib
, stdenv
, fetchFromGitHub
, cmake
, coreutils
, fetchpatch
}:

stdenv.mkDerivation rec {
  pname = "aws-c-common";
  version = "0.6.17";

  src = fetchFromGitHub {
    owner = "awslabs";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-+FzTEpotxco4+9gLVUL+rkCWoMjRCorKQ47JINHsnNA=";
  };

  patches = [
    (fetchpatch {
      name = "memtrace-underflow.patch";
      url = "https://github.com/zhaofengli/aws-c-common/commit/affba363a7e0814fa7d35cb44e6e77bba9228ce9.patch";
      sha256 = "sha256-7ZXdhRJuuvTlo+/n6XxoebBRUNnwyvWzj08yzQ5hWpw=";
    })
  ];

  nativeBuildInputs = [ cmake ];

  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=ON"
    "-DCMAKE_SKIP_BUILD_RPATH=OFF" # for tests
  ];

  # aws-c-common misuses cmake modules, so we need
  # to manually add a MODULE_PATH to its consumers
  setupHook = ./setup-hook.sh;

  # Prevent the execution of tests known to be flaky.
  preCheck = let
    ignoreTests = [
      "promise_test_multiple_waiters"
    ] ++ lib.optionals stdenv.hostPlatform.isMusl [
      "sba_metrics" # https://github.com/awslabs/aws-c-common/issues/839
    ];
  in ''
    cat <<EOW >CTestCustom.cmake
    SET(CTEST_CUSTOM_TESTS_IGNORE ${toString ignoreTests})
    EOW
  '';

  doCheck = true;

  checkFlagsArray = lib.optional stdenv.hostPlatform.isRiscV "ARGS=-E test_memtrace_stacks";

  meta = with lib; {
    description = "AWS SDK for C common core";
    homepage = "https://github.com/awslabs/aws-c-common";
    license = licenses.asl20;
    platforms = platforms.unix;
    maintainers = with maintainers; [ orivej eelco r-burns ];
  };
}
