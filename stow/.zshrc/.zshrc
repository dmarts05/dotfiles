# Prompt: show current directory in bold blue with a pink arrow
PS1='%F{blue}%B%~%b%f %F{green}❯%f '

# History configuration
HISTFILE=~/.zsh_history       # File to save command history
HISTSIZE=100000           # Max commands in memory
SAVEHIST=100000           # Max commands saved to file
setopt inc_append_history # Append commands to history immediately

# Enable completion system
autoload -U compinit && compinit

# Key bindings
bindkey -e                                   # Use Emacs-style bindings
bindkey "^[[A" history-search-backward
bindkey "^[[B" history-search-forward
bindkey '^[[1;5D' backward-word # Bind Ctrl+Left to backward-word
bindkey '^[[1;5C' forward-word # Bind Ctrl+Right to forward-word

# Aliases
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ip='ip -c=auto'
alias mv='mv -i'
alias ls='eza -lh --group-directories-first --icons=auto'
alias lsa='ls -a'
alias lt='eza --tree --level=2 --long --icons --git'
alias lta='lt -a'
alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Plugins
source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh  # Must be last
