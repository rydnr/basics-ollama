# nix/flake.nix
#
# This file packages basics-ollama as a Nix flake.
#
# Copyright (C) 2023-today rydnr's rydnr/basics-ollama
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
{
  description = "A repository to learn Ollama";
  inputs = rec {
    flake-utils.url = "github:numtide/flake-utils/v1.0.0";
    nixos.url = "github:NixOS/nixpkgs/23.11";
    pythoneda-shared-pythonlang-application = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
      inputs.pythoneda-shared-pythonlang-banner.follows =
        "pythoneda-shared-pythonlang-banner";
      inputs.pythoneda-shared-pythonlang-domain.follows =
        "pythoneda-shared-pythonlang-domain";
      url = "github:pythoneda-shared-pythonlang-def/application/0.0.58";
    };
    pythoneda-shared-pythonlang-banner = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
      url = "github:pythoneda-shared-pythonlang-def/banner/0.0.49";
    };
    pythoneda-shared-pythonlang-domain = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
      inputs.pythoneda-shared-pythonlang-banner.follows =
        "pythoneda-shared-pythonlang-banner";
      url = "github:pythoneda-shared-pythonlang-def/domain/0.0.37";
    };
    rydnr-nix-flakes-ollama = {
      inputs.flake-utils.follows = "flake-utils";
      # inputs.nixos.follows = "nixos";
      url = "github:rydnr/nix-flakes/ollama-0.1.17?dir=ollama";
    };
  };
  outputs = inputs:
    with inputs;
    let
      defaultSystems = flake-utils.lib.defaultSystems;
      supportedSystems = if builtins.elem "armv6l-linux" defaultSystems then
        defaultSystems
      else
        defaultSystems ++ [ "armv6l-linux" ];
    in flake-utils.lib.eachSystem supportedSystems (system:
      let
        org = "rydnr";
        repo = "basics-ollama";
        version = "0.0.0";
        pname = "${org}-${repo}";
        pythonpackage = "rydnr.basics.ollama";
        package = builtins.replaceStrings [ "." ] [ "/" ] pythonpackage;
        entrypoint = "basics_ollama";
        description = "A repository to learn Ollama";
        homepage = "https://github.com/rydnr/basics-ollama";
        maintainers = [ "rydnr <github@acm-sl.org>" ];
        archRole = "B";
        space = "D";
        layer = "D";
        nixosVersion = builtins.readFile "${nixos}/.version";
        nixpkgsRelease =
          builtins.replaceStrings [ "\n" ] [ "" ] "nixos-${nixosVersion}";
        pkgs = import nixos { inherit system; };
        shared = import "${pythoneda-shared-pythonlang-banner}/nix/shared.nix";
        rydnr-basics-ollama-for = { cuda-support, python
          , pythoneda-shared-pythonlang-application
          , pythoneda-shared-pythonlang-banner
          , pythoneda-shared-pythonlang-domain, rydnr-nix-flakes-ollama }:
          let
            banner_file = "${package}/basics_ollama.py";
            banner_class = "BasicsOllamaBanner";
            pnameWithUnderscores =
              builtins.replaceStrings [ "-" ] [ "_" ] pname;
            pythonVersionParts = builtins.splitVersion python.version;
            pythonMajorVersion = builtins.head pythonVersionParts;
            pythonMajorMinorVersion =
              "${pythonMajorVersion}.${builtins.elemAt pythonVersionParts 1}";
            wheelName =
              "${pnameWithUnderscores}-${version}-py${pythonMajorVersion}-none-any.whl";
          in python.pkgs.buildPythonPackage rec {
            inherit pname version;
            projectDir = ./.;
            pyprojectTemplateFile = ./pyprojecttoml.template;
            pyprojectTemplate = pkgs.substituteAll {
              authors = builtins.concatStringsSep ","
                (map (item: ''"${item}"'') maintainers);
              desc = description;
              inherit homepage package pname pythonMajorMinorVersion
                pythonpackage version;
              pythonedaSharedPythonlangApplication =
                pythoneda-shared-pythonlang-application.pname;
              pythonedaSharedPythonlangApplicationVersion =
                pythoneda-shared-pythonlang-application.version;
              pythonedaSharedPythonlangBanner =
                pythoneda-shared-pythonlang-banner.pname;
              pythonedaSharedPythonlangBannerVersion =
                pythoneda-shared-pythonlang-banner.version;
              pythonedaSharedPythonlangDomain =
                pythoneda-shared-pythonlang-domain.pname;
              pythonedaSharedPythonlangDomainVersion =
                pythoneda-shared-pythonlang-domain.version;
              rydnrNixFlakesOllama = rydnr-nix-flakes-ollama.pname;
              rydnrNixFlakesOllamaVersion = rydnr-nix-flakes-ollama.version;
              src = pyprojectTemplateFile;
            };
            bannerTemplateFile = ../templates/banner.py.template;
            bannerTemplate = pkgs.substituteAll {
              project_name = pname;
              file_path = banner_file;
              inherit banner_class org repo;
              tag = version;
              pescio_space = space;
              arch_role = archRole;
              hexagonal_layer = layer;
              python_version = pythonMajorMinorVersion;
              nixpkgs_release = nixpkgsRelease;
              src = bannerTemplateFile;
            };

            entrypointTemplateFile =
              "${pythoneda-shared-pythonlang-banner}/templates/entrypoint.sh.template";
            entrypointTemplate = pkgs.substituteAll {
              arch_role = archRole;
              hexagonal_layer = layer;
              nixpkgs_release = nixpkgsRelease;
              inherit homepage maintainers org python repo version;
              pescio_space = space;
              python_version = pythonMajorMinorVersion;
              pythoneda_shared_pytholang_banner =
                pythoneda-shared-pythonlang-banner;
              pythoneda_shared_pythonlang_domain =
                pythoneda-shared-pythonlang-domain;
              src = entrypointTemplateFile;
            };
            src = ../.;

            format = "pyproject";

            nativeBuildInputs = with python.pkgs; [
              pip
              poetry-core
              rydnr-nix-flakes-ollama
            ];
            propagatedBuildInputs = with python.pkgs; [
              pythoneda-shared-pythonlang-application
              pythoneda-shared-pythonlang-banner
              pythoneda-shared-pythonlang-domain
              rydnr-nix-flakes-ollama
            ];

            # pythonImportsCheck = [ pythonpackage ];

            unpackPhase = ''
              cp -r ${src} .
              sourceRoot=$(ls | grep -v env-vars)
              chmod +w $sourceRoot
              find $sourceRoot -type d -exec chmod 777 {} \;
              cp ${pyprojectTemplate} $sourceRoot/pyproject.toml
              cp ${bannerTemplate} $sourceRoot/${banner_file}
              cp ${entrypointTemplate} $sourceRoot/entrypoint.sh
            '';

            postPatch = ''
              substituteInPlace /build/$sourceRoot/entrypoint.sh \
                --replace "@SOURCE@" "$out/bin/${entrypoint}.sh" \
                --replace "@PYTHONEDA_EXTRA_NAMESPACES@" "rydnr" \
                --replace "@PYTHONPATH@" "$PYTHONPATH" \
                --replace "@CUSTOM_CONTENT@" "" \
                --replace "@ENTRYPOINT@" "$out/lib/python${pythonMajorMinorVersion}/site-packages/${package}/application/${entrypoint}.py"
            '';

            postInstall = ''
              pushd /build/$sourceRoot
              for f in $(find . -name '__init__.py'); do
                if [[ ! -e $out/lib/python${pythonMajorMinorVersion}/site-packages/$f ]]; then
                  cp $f $out/lib/python${pythonMajorMinorVersion}/site-packages/$f;
                fi
              done
              popd
              mkdir $out/dist $out/bin
              cp dist/${wheelName} $out/dist
              cp /build/$sourceRoot/entrypoint.sh $out/bin/${entrypoint}.sh
              chmod +x $out/bin/${entrypoint}.sh
              cp -r /build/$sourceRoot/templates $out/lib/python${pythonMajorMinorVersion}/site-packages
              echo '#!/usr/bin/env sh' > $out/bin/banner.sh
              echo "export PYTHONPATH=$PYTHONPATH" >> $out/bin/banner.sh
              echo "echo 'Running $out/bin/banner'" >> $out/bin/banner.sh
              echo "${python}/bin/python $out/lib/python${pythonMajorMinorVersion}/site-packages/${banner_file} \$@" >> $out/bin/banner.sh
              chmod +x $out/bin/banner.sh
            '';

            meta = with pkgs.lib; {
              license = licenses.gpl3;
              inherit description homepage maintainers;
            };
          };
      in rec {
        apps = rec {
          default = rydnr-basics-ollama-default;
          rydnr-basics-ollama-default = rydnr-basics-ollama-python310-cuda;
          rydnr-basics-ollama-python38 = shared.app-for {
            package = self.packages.${system}.rydnr-basics-ollama-python38;
            inherit entrypoint;
          };
          rydnr-basics-ollama-python38-cuda = shared.app-for {
            package = self.packages.${system}.rydnr-basics-ollama-python38-cuda;
            inherit entrypoint;
          };
          rydnr-basics-ollama-python39 = shared.app-for {
            package = self.packages.${system}.rydnr-basics-ollama-python39;
            inherit entrypoint;
          };
          rydnr-basics-ollama-python39-cuda = shared.app-for {
            package = self.packages.${system}.rydnr-basics-ollama-python39-cuda;
            inherit entrypoint;
          };
          rydnr-basics-ollama-python310 = shared.app-for {
            package = self.packages.${system}.rydnr-basics-ollama-python310;
            inherit entrypoint;
          };
          rydnr-basics-ollama-python310-cuda = shared.app-for {
            package =
              self.packages.${system}.rydnr-basics-ollama-python310-cuda;
            inherit entrypoint;
          };
        };
        defaultApp = apps.default;
        defaultPackage = packages.default;
        devShells = rec {
          default = rydnr-basics-ollama-default;
          rydnr-basics-ollama-default = rydnr-basics-ollama-python310-cuda;
          rydnr-basics-ollama-python38 = shared.devShell-for {
            banner = "${packages.rydnr-basics-ollama-python38}/bin/banner.sh";
            extra-namespaces = "rydnr";
            nixpkgs-release = nixpkgsRelease;
            package = packages.rydnr-basics-ollama-python38;
            pkgs = pkgsNonCuda;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python38;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python38;
            python = pkgs.python38;
            inherit archRole layer org repo space;
          };
          rydnr-basics-ollama-python38-cuda = shared.devShell-for {
            banner =
              "${packages.rydnr-basics-ollama-python38-cuda}/bin/banner.sh";
            extra-namespaces = "rydnr";
            nixpkgs-release = nixpkgsRelease;
            package = packages.rydnr-basics-ollama-python38-cuda;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python38;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python38;
            python = pkgs.python38;
            inherit archRole layer org pkgs repo space;
          };
          rydnr-basics-ollama-python39 = shared.devShell-for {
            banner = "${packages.rydnr-basics-ollama-python39}/bin/banner.sh";
            extra-namespaces = "rydnr";
            nixpkgs-release = nixpkgsRelease;
            package = packages.rydnr-basics-ollama-python39;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python39;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python39;
            python = pkgs.python39;
            inherit archRole layer org pkgs repo space;
          };
          rydnr-basics-ollama-python39-cuda = shared.devShell-for {
            banner =
              "${packages.rydnr-basics-ollama-python39-cuda}/bin/banner.sh";
            extra-namespaces = "rydnr";
            nixpkgs-release = nixpkgsRelease;
            package = packages.rydnr-basics-ollama-python39-cuda;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python39;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python39;
            python = pkgs.python39;
            inherit archRole layer org pkgs repo space;
          };
          rydnr-basics-ollama-python310 = shared.devShell-for {
            banner = "${packages.rydnr-basics-ollama-python310}/bin/banner.sh";
            extra-namespaces = "rydnr";
            nixpkgs-release = nixpkgsRelease;
            package = packages.rydnr-basics-ollama-python310;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python310;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python310;
            python = pkgsNonCuda.python310;
            inherit archRole layer org pkgs repo space;
          };
          rydnr-basics-ollama-python310-cuda = shared.devShell-for {
            banner =
              "${packages.rydnr-basics-ollama-python310-cuda}/bin/banner.sh";
            extra-namespaces = "rydnr";
            nixpkgs-release = nixpkgsRelease;
            package = packages.rydnr-basics-ollama-python310-cuda;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python310;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python310;
            python = pkgs.python310;
            inherit archRole layer org pkgs repo space;
          };
        };
        packages = rec {
          default = rydnr-basics-ollama-default;
          rydnr-basics-ollama-default = rydnr-basics-ollama-python310-cuda;
          rydnr-basics-ollama-python38 = rydnr-basics-ollama-for {
            cuda-support = false;
            python = pkgs.python38;
            pythoneda-shared-pythonlang-application =
              pythoneda-shared-pythonlang-application.packages.${system}.pythoneda-shared-pythonlang-application-python38;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python38;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python38;
            rydnr-nix-flakes-ollama =
              rydnr-nix-flakes-ollama.packages.${system}.rydnr-nix-flakes-ollama-nonCuda;
          };
          rydnr-basics-ollama-python38-cuda = rydnr-basics-ollama-for {
            cuda-support = true;
            python = pkgs.python38;
            pythoneda-shared-pythonlang-application =
              pythoneda-shared-pythonlang-application.packages.${system}.pythoneda-shared-pythonlang-application-python38;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python38;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python38;
            rydnr-nix-flakes-ollama =
              rydnr-nix-flakes-ollama.packages.${system}.rydnr-nix-flakes-ollama-cuda;
          };
          rydnr-basics-ollama-python39 = rydnr-basics-ollama-for {
            cuda-support = false;
            python = pkgs.python39;
            pythoneda-shared-pythonlang-application =
              pythoneda-shared-pythonlang-application.packages.${system}.pythoneda-shared-pythonlang-application-python39;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python39;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python39;
            rydnr-nix-flakes-ollama =
              rydnr-nix-flakes-ollama.packages.${system}.rydnr-nix-flakes-ollama-nonCuda;
          };
          rydnr-basics-ollama-python39-cuda = rydnr-basics-ollama-for {
            cuda-support = true;
            python = pkgs.python39;
            pythoneda-shared-pythonlang-application =
              pythoneda-shared-pythonlang-application.packages.${system}.pythoneda-shared-pythonlang-application-python39;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python39;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python39;
            rydnr-nix-flakes-ollama =
              rydnr-nix-flakes-ollama.packages.${system}.rydnr-nix-flakes-ollama-cuda;
          };
          rydnr-basics-ollama-python310 = rydnr-basics-ollama-for {
            cuda-support = false;
            python = pkgs.python310;
            pythoneda-shared-pythonlang-application =
              pythoneda-shared-pythonlang-application.packages.${system}.pythoneda-shared-pythonlang-application-python310;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python310;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python310;
            rydnr-nix-flakes-ollama =
              rydnr-nix-flakes-ollama.packages.${system}.rydnr-nix-flakes-ollama-nonCuda;
          };
          rydnr-basics-ollama-python310-cuda = rydnr-basics-ollama-for {
            cuda-support = true;
            python = pkgs.python310;
            pythoneda-shared-pythonlang-application =
              pythoneda-shared-pythonlang-application.packages.${system}.pythoneda-shared-pythonlang-application-python310;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python310;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python310;
            rydnr-nix-flakes-ollama =
              rydnr-nix-flakes-ollama.packages.${system}.rydnr-nix-flakes-ollama-cuda;
          };
        };
      });
}
