##
# Plugins
#

# -a sets the variable's type to array.
local -a plugins=(
    marlonrichert/zsh-autocomplete      # Real-time type-ahead completion
    marlonrichert/zsh-edit              # Better keyboard shortcuts
    marlonrichert/zsh-hist              # Edit history from the command line.
    marlonrichert/zcolors               # Colors for completions and Git
    zsh-users/zsh-autosuggestions       # Inline suggestions
    zsh-users/zsh-syntax-highlighting   # Command-line syntax highlighting
    romkatv/powerlevel10k
)

#   zstyle ':autocomplete:*' min-delay 0.5  # seconds
#   zstyle ':autocomplete:*' async no

# Speed up the first startup by cloning all plugins in parallel.
znap clone $plugins

# Load each plugin, one at a time.
local p=
for p in $plugins; do
  znap source $p
done