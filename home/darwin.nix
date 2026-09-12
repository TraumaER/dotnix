{...}: {
  imports = [./shared.nix];
  programs.git.lfs.enable = true;
  programs.zsh.initContent = ''
    bindkey "^[[3~" delete-char
  '';
}
