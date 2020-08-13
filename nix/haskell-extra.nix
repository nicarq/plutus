############################################################################
# Extra Haskell packages which we build with haskell.nix, but which aren't
# part of our project's package set themselves.
#
# These are for e.g. developer usage, or for running formatting tests.
############################################################################
{ pkgs, index-state, checkMaterialization }:
let compiler-nix-name = "ghc8102";
in {
  Agda = pkgs.haskell-nix.hackage-package {
    name = "Agda";
    version = "2.6.1";
    plan-sha256 = "0bpa5z5j1iy4w3jq5lb6v9dx5dccahn02frkizqa6h4whjfi54gx";
    inherit compiler-nix-name index-state checkMaterialization;
    modules = [{
      # Agda is a huge pain. They have a special custom setup that compiles the interface files for
      # the Agda that ships with the compiler. These go in the data files for the *library*, but they
      # require the *executable* to compile them, which depends on the library!
      # They get away with it by using the old-style builds and building everything together, we can't
      # do that.
      # So we work around it:
      # - turn off the custom setup
      # - manually compile the executable (fortunately it has no extra dependencies!) and do the
      # compilation at the end of the library derivation.
      packages.Agda.package.buildType = pkgs.lib.mkForce "Simple";
      packages.Agda.components.library.postInstall = ''
        # Compile the executable using the package DB we've just made, which contains
        # the main Agda library
        ghc src/main/Main.hs -package-db=$out/package.conf.d -o agda

        # Find all the files in $out (would be $data if we had a separate data output)
        shopt -s globstar
        files=($out/**/*.agda)
        for f in "''${files[@]}" ; do
          echo "Compiling $f"
          # This is what the custom setup calls in the end
          ./agda --no-libraries --local-interfaces $f
        done
      '';
    }];
    configureArgs = "--constraint 'haskeline == 0.8.0.0'";
  };
  cabal-install = pkgs.haskell-nix.hackage-package {
    name = "cabal-install";
    version = "3.2.0.0";
    inherit compiler-nix-name index-state checkMaterialization;
    # Invalidate and update if you change the version or index-state
    plan-sha256 = "1s5c3s7jsaf1arqgz2z7ng0nym83vsinm69lm8wvhpk5rdpfhbld";
  };
  stylish-haskell = pkgs.haskell-nix.hackage-package {
    name = "stylish-haskell";
    version = "0.10.0.0";
    inherit compiler-nix-name index-state checkMaterialization;
    # Invalidate and update if you change the version or index-state
    plan-sha256 = "0jz1f417rgk9ifhmv11havw6pgqkg3hax3d7rd3zv219cn8n55rf";
  };
  hlint = pkgs.haskell-nix.hackage-package {
    name = "hlint";
    version = "2.2.11";
    inherit compiler-nix-name index-state checkMaterialization;
    # Invalidate and update if you change the version or index-state
    plan-sha256 = "08dgfnavl4xfpl3a0nhxaabgslbhgbwxmmv6m4n4p08h1ql9hms3";
  };
  inherit (
    let hspkgs = pkgs.haskell-nix.cabalProject {
        src = pkgs.fetchFromGitHub {
          owner = "haskell";
          repo = "haskell-language-server";
          rev = "2186df00a9414c640fba1ae2acc3d9aa21ab6e4c";
          sha256 = "0qh41jbf1a697l8wf48zmfs6vf08gijb0w42h26nvimcgc5dkh9a";
          fetchSubmodules = true;
        };
        lookupSha256 = { location, tag, ... } : {
          "https://github.com/wz1000/shake"."fb3859dca2e54d1bbb2c873e68ed225fa179fbef" = "0sa0jiwgyvjsmjwpfcpvzg2p7277aa0dgra1mm6afh2rfnjphz8z";
          "https://github.com/peti/cabal-plan"."894b76c0b6bf8f7d2f881431df1f13959a8fce87" = "06iklj51d9kh9bhc42lrayypcpgkjrjvna59w920ln41rskhjr4y";
          }."${location}"."${tag}";
        inherit compiler-nix-name index-state checkMaterialization;
        # Invalidate and update if you change the version
        plan-sha256 = "0aqp43yvcm673q8aycmszm38wr8f45cpwgn4mdzym1mvxxi216lj";
        modules = [{
          # Tests don't pass for some reason, but this is a somewhat random revision.
          packages.haskell-language-server.doCheck = false;
        }];
      };
    in { haskell-language-server = hspkgs.haskell-language-server; hie-bios = hspkgs.hie-bios; })
  hie-bios haskell-language-server;
  purty =
    let hspkgs = pkgs.haskell-nix.stackProject {
        src = pkgs.fetchFromGitLab {
          owner = "joneshf";
          repo = "purty";
          rev = "3c073e1149ecdddd01f1d371c70d5b243d743bf2";
          sha256 = "0j8z9661anisp4griiv5dfpxarfyhcfb15yrd2k0mcbhs5nzhni0";
        };
        # Invalidate and update if you change the version
        stack-sha256 = "1r1fyzbl69jir30m0vqkyyf82q2548kdql4m05lss7fdsbdv4bw1";
        inherit checkMaterialization;

        # Force using 8.6.5 to work around https://github.com/input-output-hk/haskell.nix/issues/811
        ghc = pkgs.buildPackages.haskell-nix.compiler.ghc865;
        modules = [{ compiler.nix-name = pkgs.lib.mkForce "ghc865"; }];

        pkg-def-extras = [
          # Workaround for https://github.com/input-output-hk/haskell.nix/issues/214
          (hackage: {
            packages = {
              "hsc2hs" = (((hackage.hsc2hs)."0.68.6").revisions).default;
            };
          })
        ];
      };
    in hspkgs.purty;
}
