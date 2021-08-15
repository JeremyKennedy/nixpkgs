{ lib
, stdenv
, fetchurl
, fetchFromGitHub
, dotnetCorePackages
, dotnetPackages
, linkFarmFromDrvs
, dos2unix
, makeWrapper
, z3
}:

let
  fetchNuGet = { name, version, sha256 }: fetchurl {
    name = "nuget-${name}-${version}.nupkg";
    url = "https://www.nuget.org/api/v2/package/${name}/${version}";
    inherit sha256;
  };

  cocor = fetchNuGet {
    name = "cocor";
    version = "2014.12.23";
    sha256 = "0gp75b3s0v7cismdkr8jmbblwgb01l99ir5sjl0h5y0xlx7l2fsy";
  };
in stdenv.mkDerivation rec {
  pname = "dafny";
  version = "3.2.0";

  src = fetchFromGitHub {
    owner = "dafny-lang";
    repo = "dafny";
    rev = "v${version}";
    sha256 = "sha256-HX4IaeN37aShh78R/odYLQ0Ed2XHdtpb4cg9uKAbHRU=";
  };

  nativeBuildInputs = [
    dotnetCorePackages.sdk_5_0 dotnetPackages.Nuget dos2unix
    makeWrapper
  ];

  nugetDeps = linkFarmFromDrvs "${pname}-nuget-deps" ((import ./deps.nix { inherit fetchNuGet; }) ++ [ cocor ]);

  patches = [
    # We will restore Coco ourselves with our offline cache
    ./dont-restore-coco.patch
  ];

  prePatch = ''
    dos2unix Source/Dafny/DafnyPipeline.csproj
  '';

  configurePhase = ''
    runHook preConfigure

    export HOME=$(mktemp -d)
    export DOTNET_CLI_TELEMETRY_OPTOUT=1
    export DOTNET_NOLOGO=1

    nuget sources Add -Name nixos -Source "$PWD/nixos"
    nuget init "$nugetDeps" "$PWD/nixos"

    # FIXME: https://github.com/NuGet/Home/issues/4413
    mkdir -p $HOME/.nuget/NuGet
    cp $HOME/.config/NuGet/NuGet.Config $HOME/.nuget/NuGet

    dotnet restore --source "$PWD/nixos" Source/Dafny.sln
    dotnet tool restore --add-source "$PWD/nixos" --tool-manifest Source/dotnet-tools.json

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    dotnet build Source/Dafny.sln \
      --configuration Release \
      --no-restore

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    dotnet publish Source/Dafny.sln \
      --configuration Release \
      --output $out/lib/dafny \
      --no-self-contained \
      --no-build

    for f in Dafny DafnyLanguageServer DafnyServer; do
      makeWrapper $out/lib/dafny/$f $out/bin/$f \
        --set DOTNET_ROOT "${dotnetCorePackages.net_5_0}" \
        --prefix PATH : ${z3}/bin
    done

    ln -s $out/bin/Dafny $out/bin/dafny

    runHook postInstall
  '';

  # Stripping breaks the executables.
  dontStrip = true;

  meta = with lib; {
    description = "A programming language with built-in specification constructs";
    homepage = "https://research.microsoft.com/dafny";
    maintainers = with maintainers; [ layus zhaofengli ];
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
  };
}
