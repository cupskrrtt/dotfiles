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

# Check if the zsh-syntax-highlighting plugin is installed in the default system location
if [[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# If the default system location doesn't exist, check for the Homebrew installation
elif [[ -f $HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source $HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

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
