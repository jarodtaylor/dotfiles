#
# Core ZSH Options
# Focused on developer workflow and terminal convenience
#

# History
setopt extended_history        # Save timestamp and duration
setopt hist_ignore_all_dups   # Remove older duplicate entries from history
setopt hist_ignore_space      # Don't record commands starting with space
setopt hist_verify            # Show command with history expansion before running it
setopt share_history          # Share history between all sessions
setopt inc_append_history     # Add commands to history as they're typed
setopt hist_reduce_blanks     # Remove superfluous blanks from history

# Directory Navigation
setopt auto_cd               # If command is a directory path, cd into it
setopt auto_pushd           # Push the old directory onto the stack on cd
setopt pushd_ignore_dups    # Don't store duplicates in the stack
setopt pushd_minus          # Use +/- operators for pushd

# Completion
setopt auto_menu            # Show completion menu on tab press
setopt complete_in_word     # Complete from both ends of a word
setopt always_to_end        # Move cursor to end of word after completion
unsetopt menu_complete      # Don't autoselect the first completion entry

# Input/Output
setopt interactive_comments  # Allow comments in interactive shell
unsetopt beep              # No beep on error
unsetopt flow_control      # Disable start/stop characters (^S/^Q)

# Globbing and Files
setopt extended_glob        # Use extended globbing syntax
setopt glob_dots           # Include hidden files in globbing
unsetopt case_glob         # Make globbing case insensitive

# Job Control
setopt auto_resume         # Allow simple commands to resume background jobs
setopt long_list_jobs      # List jobs in long format
setopt notify             # Report status of background jobs immediately

# Safety
unsetopt rm_star_silent    # Prompt before executing 'rm *'
unsetopt clobber          # Don't overwrite files with >

# Command Editing
setopt combining_chars     # Handle multi-byte characters
