lvim.plugins = {
  { 'jose-elias-alvarez/typescript.nvim' },
  { 'lunarvim/lunar.nvim' },
  { "morhetz/gruvbox" },
  { "sainnhe/gruvbox-material" },
  { "sainnhe/sonokai" },
  { "sainnhe/edge" },
  { "lunarvim/horizon.nvim" },
  { "tomasr/molokai" },
  { "ayu-theme/ayu-vim" },
  {
    "folke/trouble.nvim",
    cmd = "TroubleToggle",
  },
  {
    -- "nvim-neo-tree/neo-tree.nvim",
    -- branch = "v2.x",
    -- dependencies = {
    --   "nvim-lua/plenary.nvim",
    --   "nvim-tree/nvim-web-devicons",
    --   "MunifTanjim/nui.nvim",
    -- },
    -- config = function()
    --   require("neo-tree").setup({
    --     close_if_last_window = true,
    --     window = {
    --       width = 30,
    --     },
    --     buffers = {
    --       follow_current_file = true,
    --     },
    --     filesystem = {
    --       follow_current_file = true,
    --       filtered_items = {
    --         hide_dotfiles = false,
    --         hide_gitignored = false,
    --         hide_by_name = {
    --           "node_modules"
    --         },
    --         never_show = {
    --           ".DS_Store",
    --           "thumbs.db"
    --         },
    --       },
    --     },
    --   })
    -- end
  },
  {
    "folke/todo-comments.nvim",
    event = "BufRead",
    config = function()
      require("todo-comments").setup()
    end
  },

  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    config = function()
      require("persistence").setup({
        dir = vim.fn.expand(vim.fn.stdpath "state" .. "/sessions/"),
        options = { "buffers", "curdir", "tabpages", "winsize" }
      })
    end
  },

  { "christoomey/vim-tmux-navigator" },
  { "tpope/vim-surround" },
  { "felipec/vim-sanegx",            event = "BufRead" },
  {
    "windwp/nvim-ts-autotag",
    config = function()
      require("nvim-ts-autotag").setup()
    end,
  },
  { "tpope/vim-repeat" },

  { "ThePrimeagen/harpoon" },

  {
    'phaazon/hop.nvim',
    branch = 'v2',
    config = function()
      require('hop').setup()
    end
  },

  {
    'nvim-telescope/telescope-frecency.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim', 'kkharji/sqlite.lua' },
  },

  {
    'AckslD/nvim-trevJ.lua',
    config = 'require("trevj").setup()',
    init = function()
      vim.keymap.set('n', '<leader>j', function()
        require('trevj').format_at_cursor()
      end)
    end,
  },
}

table.insert(lvim.plugins, {
  "zbirenbaum/copilot-cmp",
  event = "InsertEnter",
  dependencies = { "zbirenbaum/copilot.lua" },
  config = function()
    local ok, cmp = pcall(require, "copilot_cmp")
    if ok then cmp.setup({}) end
  end,
})

-- lvim.builtin.nvimtree.active = treu;

lvim.builtin.telescope.on_config_done = function(telescope)
  pcall(telescope.load_extension, "frecency")
end
