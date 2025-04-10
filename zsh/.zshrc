# ZSH CONFIG

#=======#
# ALIAS #
#=======#

alias ls="eza --long --header --all --icons"

#==========#
# AUTOLOAD #
#==========#

autoload -Uz compinit promptinit
compinit
promptinit

#========#
# ZSTYLE #
#========#

zstyle ':completion:*' menu select

#=========#
# PLUGINS #
#=========#

source $HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

#======#
# EVAL #
#======#

eval "$(starship init zsh)"

# pnpm
export PNPM_HOME="/home/cup/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
