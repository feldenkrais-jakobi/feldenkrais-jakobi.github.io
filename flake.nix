{
  description = "Hakyll site for the Feldenkrais practice of Heinrich Jakobi";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    hix = {
      url = "github:tek/hix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {self, ...}:
    inputs.hix ({
      config,
      lib,
      ...
    }: let
      sourceFilter = root:
        with lib.fileset;
          toSource {
            inherit root;
            fileset =
              fileFilter
              (file: lib.any file.hasExt ["cabal" "hs" "md"] || file.name == "LICENSE")
              root;
          };
      pname = "fjakobi-site";
      system = config.pkgs.stdenv.hostPlatform.system;
      open-sans-woff2 =
        config.pkgs.runCommand "open-sans-woff2" {
          nativeBuildInputs = [
            (config.pkgs.python3.withPackages (ps: [ps.brotli ps.fonttools]))
          ];
        } ''
          mkdir -p $out
          for style in Light LightItalic Regular Italic; do
            pyftsubset ${config.pkgs.open-sans}/share/fonts/truetype/OpenSans-$style.ttf \
              --output-file=$out/OpenSans-$style.woff2 \
              --flavor=woff2 \
              --drop-tables=kern \
              --unicodes=U+0-10FFFF \
              --layout-features='*'
          done
        '';
    in {
      cabal = {
        author = "Marc Jakobi";
        build-type = "Simple";
        license = "GPL-3.0-only";
        license-file = "LICENSE";
        version = "1.0.0.0";
        meta = {
          maintainer = "marc@jakobi.dev";
          homepage = "feldenkrais-jakobi.de";
          synopsis = "Hakyll site for the Feldenkrais practice of Heinrich Jakobi";
        };
        language = "GHC2021";
        default-extensions = [
          "ApplicativeDo"
          "BlockArguments"
          "DataKinds"
          "DefaultSignatures"
          "DeriveAnyClass"
          "DeriveGeneric"
          "DerivingVia"
          "ExplicitNamespaces"
          "LambdaCase"
          "NoImplicitPrelude"
          "OverloadedLabels"
          "OverloadedStrings"
          "PackageImports"
          "RecordWildCards"
          "StrictData"
          "TypeFamilies"
          "ViewPatterns"
        ];
        ghc-options = [
          "-Weverything"
          "-Wno-unsafe"
          "-Wno-missing-safe-haskell-mode"
          "-Wno-missing-export-lists"
          "-Wno-missing-import-lists"
          "-Wno-missing-kind-signatures"
          "-Wno-all-missed-specialisations"
        ];
      };
      packages.${pname} = {
        src = sourceFilter ./.;
        executable = {
          enable = true;
          source-dirs = "app";
          dependencies = ["hakyll" "pandoc" "time"];
        };
      };
      envs.dev = {
        env.DIRENV_IN_ENVRC = "";
        setup-pre =
          ''
            NIX_MONITOR=disable nix run .#gen-cabal
            NIX_MONITOR=disable nix run .#tags
            mkdir -p theme/yoo_aurora/fonts/opensans
            cp -f ${open-sans-woff2}/*.woff2 theme/yoo_aurora/fonts/opensans/
          ''
          + self.checks.${system}.git.shellHook;
        buildInputs = self.checks.${system}.git.enabledPackages;
      };
      outputs = {
        packages = with config; let
          site-pkg = self.packages.${system}.default;
        in {
          inherit open-sans-woff2;

          website = pkgs.stdenv.mkDerivation {
            name = "website";
            src = self.outPath;
            # LANG and LOCALE_ARCHIVE are fixes pulled from the community:
            #   https://github.com/jaspervdj/hakyll/issues/614#issuecomment-411520691
            #   https://github.com/NixOS/nix/issues/318#issuecomment-52986702
            #   https://github.com/MaxDaten/brutal-recipes/blob/source/default.nix#L24
            LANG = "en_US.UTF-8";
            LOCALE_ARCHIVE =
              pkgs.lib.optionalString
              (pkgs.stdenv.buildPlatform.libc == "glibc")
              "${pkgs.glibcLocales}/lib/locale/locale-archive";

            buildPhase = ''
              runHook preBuild
              mkdir -p theme/yoo_aurora/fonts/opensans
              cp ${open-sans-woff2}/*.woff2 theme/yoo_aurora/fonts/opensans/
              ${lib.getExe' site-pkg "fjakobi-site"} build --verbose
              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall
              mkdir -p "$out/dist"
              cp -a _site/. "$out/dist"
              cp LICENSE THIRD-PARTY.md "$out/dist/"
              runHook postInstall
            '';
          };
        };
        checks = {
          git = inputs.git-hooks.lib.${system}.run {
            src = self;
            hooks = {
              alejandra.enable = true;
            };
          };
        };
      };
    });
}
