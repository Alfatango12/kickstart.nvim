return {
  '0fflineuser/anki.nvim',
  opts = {
    -- Your custom configuration goes here
    -- The URL of your AnkiConnect server
    url = 'http://localhost:8765',
    -- The timeout for requests to AnkiConnect, in milliseconds
    timeout = 500,
    -- The key to open the 'Anki UI' tab
    prefix = '<leader>a',
    -- Automatically map the 'Anki UI' to 'prefix'
    default_mappings = true,
    -- Whether to automatically open the Anki GUI to the relevant deck/note
    gui_browse_enabled = true,
    -- Whether to create the 'Anki' command
    create_user_commands = true,
    -- Keymappings for the deck, note, and editor panes
    mappings = {
      deck = {
        show_help = '?',
        close = 'q',
        select_deck = '<CR>',
        delete_deck = 'd',
        create_deck = 'c',
        add_note = 'a',
        rename_deck = 'm',
        gui_deck = 'o',
        refresh_decks = 'r',
        switch_profile = 'p',
      },
      note = {
        show_help = '?',
        close = 'q',
        edit_note = '<CR>',
        delete_note = 'd',
        gui_note = 'o',
        show_all_notes = 'a',
        refresh_notes = 'r',
        move_note_to_deck = 'm',
      },
      editor = {
        send_note = '<leader>w',
        pull_note = '<leader>p',
        delete_note = '<leader>r',
        kill_note = '<leader>k',
        show_help = '?',
      },
      config = true,
    },
  },
}
