return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  opts = {
    -- Enable the window module
    win = {
      enabled = true,
      -- Optional: you can set default styles for all snacks windows here
      style = 'rounded', -- "rounded", "single", "double", "solid", "shadow", "none"
    },
    -- Other modules you're likely using
  },
}
