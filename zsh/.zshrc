#=======#
# PATHS #
#=======#

# Define tool directories
export GOPATH="$HOME/go"
export PNPM_HOME="$HOME/.local/share/pnpm"
export NVM_DIR="$HOME/.nvm"
export GTK_USE_PORTAL=1

# Cleanly prepend paths (ensures no duplicates)
typeset -U path
path=(
	"$HOME/.local/bin"
  "$PNPM_HOME"
  "$GOPATH/bin"
  "$(go env GOBIN 2>/dev/null)"
  "$path[@]"
)

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
zstyle ':completion:*' menu select

#=========#
# PLUGINS #
#=========#

# Helper to source files if they exist
source_if_exists() {
  [[ -f "$1" ]] && source "$1"
}

# Syntax Highlighting
source_if_exists "/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
source_if_exists "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# NVM Load (Prioritize Brew, then Local, then System)
NVM_LOCATIONS=(
  "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
  "$NVM_DIR/nvm.sh"
  "/usr/share/nvm/init-nvm.sh"
)

for nvm_path in $NVM_LOCATIONS; do
  if [[ -f "$nvm_path" ]]; then
    source "$nvm_path"
    # Load completion if not on system-wide init
    [[ -f "${nvm_path%/*}/bash_completion" ]] && source "${nvm_path%/*}/bash_completion"
    break
  fi
done

#======#
# EVAL #
#======#

eval "$(starship init zsh)"
export DISPLAY=:0
