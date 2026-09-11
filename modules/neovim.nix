{pkgs, ...}: {
  programs.neovim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      vim-nix
      vim-gitgutter
      vim-which-key
      vim-surround
      vim-commentary
      vim-easy-align
      vim-sleuth
      telescope-nvim
      plenary-nvim
      telescope-fzf-native-nvim
    ];
  };

  xdg.configFile."nvim/init.lua".text = ''
    vim.g.mapleader = " "
    vim.g.maplocalleader = " "

    local map = vim.keymap.set

    local ok, telescope = pcall(require, "telescope.builtin")
    if ok then
      map("n", "<leader>ff", telescope.find_files, { desc = "Find files" })
      map("n", "<leader>fg", telescope.live_grep, { desc = "Live grep" })
      map("n", "<leader>fb", telescope.buffers, { desc = "Find buffers" })
      map("n", "<leader>fh", telescope.help_tags, { desc = "Help tags" })
    end

    map("n", "<leader>wk", "<cmd>WhichKey '<Space>'<CR>", {
      silent = true,
      desc = "Show which-key for <leader>",
    })
  '';
}
