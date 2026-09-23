{pkgs, ...}: {
  imports = [./shared.nix];

  programs.git.lfs = {
    enable = true;
    package = null;
  };

  home.packages = [pkgs.git-lfs];

  programs.zsh.initContent = ''
    bindkey "^[[3~" delete-char
  '';
}
