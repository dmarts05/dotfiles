# Prompt: show current directory in bold blue with a pink arrow
PS1='%F{blue}%B%~%b%f %F{magenta}❯%f '

# History configuration
HISTFILE=~/.zsh_history       # File to save command history
HISTSIZE=100000           # Max commands in memory
SAVEHIST=100000           # Max commands saved to file
setopt inc_append_history # Append commands to history immediately

# Enable completion system
autoload -U compinit && compinit

# Key bindings
bindkey -e                                   # Use Emacs-style bindings
bindkey "\e[A" history-beginning-search-backward  # ↑: search history by prefix
bindkey "\e[B" history-beginning-search-forward   # ↓: search history by prefix
bindkey '^[[1;5D' backward-word # Bind Ctrl+Left to backward-word
bindkey '^[[1;5C' forward-word # Bind Ctrl+Right to forward-word

# Command aliases
alias ls='ls --color=auto -hv'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ip='ip -c=auto'
alias mv='mv -i'

# Plugins
source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh  # Must be last
