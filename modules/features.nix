{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.dotnix;
  f = cfg.features;
  containerTools = f.containers || f.colima;
  browserLauncher = pkgs.writeShellScript "dotnix-browser" ''
    exec ${lib.escapeShellArg cfg.browser} "$@"
  '';
  proxy = {GOPROXY = "http://localhost:3100,direct";};
  helper =
    if cfg.localDirectory == null
    then "dotnix rebuild"
    else "dotnix --config ${lib.escapeShellArg cfg.localDirectory} rebuild";
in {
  dotnix.brew.casks = lib.mkIf (f.desktop && pkgs.stdenv.hostPlatform.isDarwin) ["kap" "alt-tab"];
  assertions = [
    {
      assertion = !(f.desktop && pkgs.stdenv.hostPlatform.isDarwin) || f.homebrew;
      message = "macOS desktop applications require Homebrew";
    }
    {
      assertion = !f.signing || cfg.signing.key != null;
      message = "Signing requires dotnix.signing.key";
    }
    {
      assertion = !f.browser || cfg.browser != null;
      message = "Browser integration requires dotnix.browser";
    }
    {
      assertion = !f.onePassword || cfg.onePasswordSocket != null;
      message = "1Password requires an explicit agent socket";
    }
    {
      assertion = !(f.keychain && f.onePassword);
      message = "Select only one SSH agent integration";
    }
    {
      assertion = !f.java || (cfg.jdk != null && builtins.hasAttr cfg.jdk pkgs);
      message = "Java requires an explicit nixpkgs JDK attribute";
    }
    {
      assertion = !f.athens || (cfg.athensImage != null && builtins.match ".*(:v?[0-9][^ /]*|@sha256:[a-f0-9]{64})" cfg.athensImage != null);
      message = "Athens requires an explicit numeric version tag or sha256 digest";
    }
    {
      assertion = pkgs.stdenv.hostPlatform.isDarwin || cfg.brew.casks == [];
      message = "Homebrew casks require macOS";
    }
  ];
  home.packages =
    [(import ../lib/helper.nix {inherit pkgs;})]
    ++ lib.optionals f.development (with pkgs; [posting mise bun pre-commit zizmor actionlint go go-jsonnet golangci-lint mage rustup rustscan shellcheck shfmt])
    ++ lib.optionals containerTools (with pkgs; [docker docker-compose kind kubectl kubectx k9s])
    ++ lib.optionals f.colima [pkgs.colima]
    ++ lib.optionals f.cloud (with pkgs; [tenv (google-cloud-sdk.withExtraComponents (with google-cloud-sdk.components; [gke-gcloud-auth-plugin])) azure-cli awscli2])
    ++ lib.optionals (f.desktop && pkgs.stdenv.hostPlatform.isLinux) (with pkgs; [firefox xclip wl-clipboard]);
  programs.bash.shellAliases = {rebuild = lib.mkForce helper;} // lib.optionalAttrs cfg.integrated {rebuildSys = helper;};
  programs.zsh.shellAliases = {rebuild = lib.mkForce helper;} // lib.optionalAttrs cfg.integrated {rebuildSys = helper;};
  programs.zsh.oh-my-zsh.plugins =
    lib.optionals containerTools ["docker" "docker-compose" "kubectx" "kubectl"]
    ++ lib.optionals f.development ["npm" "pip" "python"] ++ lib.optionals f.homebrew ["brew"];
  home.sessionPath = ["${config.home.homeDirectory}/.local/bin"];
  programs.git = lib.mkMerge [
    (lib.mkIf f.githubSsh {settings.url."git@github.com:".insteadOf = "https://github.com/";})
    (lib.mkIf f.signing {
      signing = {
        inherit (cfg.signing) key format;
        signByDefault = true;
      };
      settings = lib.mkIf (cfg.signing.allowedSigners != "") {gpg.ssh.allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";};
    })
  ];
  xdg.configFile."git/allowed_signers" = lib.mkIf (f.signing && cfg.signing.allowedSigners != "") {text = cfg.signing.allowedSigners;};
  keychain.enable = lib.mkDefault f.keychain;
  nvm.enable = lib.mkDefault f.nvm;
  programs.java = lib.mkIf f.java {
    enable = true;
    package = pkgs.${cfg.jdk};
  };
  home.sessionVariables = lib.mkMerge [
    (lib.mkIf f.browser {BROWSER = toString browserLauncher;})
    (lib.mkIf f.onePassword {SSH_AUTH_SOCK = cfg.onePasswordSocket;})
    (lib.mkIf f.athens proxy)
  ];
  programs.bash.sessionVariables = lib.mkIf f.athens proxy;
  programs.zsh.sessionVariables = lib.mkIf f.athens proxy;
  home.file.".local/athens/docker-compose.yml" = lib.mkIf f.athens {
    text = builtins.toJSON {
      name = "athens-go-proxy";
      services.athens = {
        image = cfg.athensImage;
        ports = ["127.0.0.1:3100:3000"];
        volumes = ["athens_storage:/var/lib/athens" "./.netrc:/etc/.netrc:ro"];
        environment = {
          ATHENS_STORAGE_TYPE = "disk";
          ATHENS_DISK_STORAGE_ROOT = "/var/lib/athens";
          ATHENS_TIMEOUT = "300";
          ATHENS_NETRC_PATH = "/etc/.netrc";
        };
        restart = "unless-stopped";
      };
      volumes.athens_storage.driver = "local";
    };
  };
}
