# google-cloud-sdk brew caveat
source "/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc"
source "/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc"

# BEGIN ANSIBLE MANAGED BLOCK
# Add homebrew binaries to the path.
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:${PATH?}"

# Force certain more-secure behaviours from homebrew
export HOMEBREW_NO_INSECURE_REDIRECT=1
export HOMEBREW_CASK_OPTS=--require-sha
export HOMEBREW_DIR=/opt/homebrew
export HOMEBREW_BIN=/opt/homebrew/bin

# Load python shims
eval "$(pyenv init -)"

# Load ruby shims
eval "$(rbenv init -)"

# Prefer GNU binaries to Macintosh binaries.
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:${PATH}"

# Add AWS CLI to PATH
export PATH="/opt/homebrew/opt/awscli@1/bin:$PATH"

# Add datadog devtools binaries to the PATH
export PATH="${HOME?}/dd/devtools/bin:${PATH?}"

# Point GOPATH to our go sources
export GOPATH="${HOME?}/go"

# Add binaries that are go install-ed to PATH
export PATH="${GOPATH?}/bin:${PATH?}"

# Point DATADOG_ROOT to ~/dd symlink
export DATADOG_ROOT="${HOME?}/dd"

# Tell the devenv vm to mount $GOPATH/src rather than just dd-go
export MOUNT_ALL_GO_SRC=1

# store key in the login keychain instead of aws-vault managing a hidden keychain
export AWS_VAULT_KEYCHAIN_NAME=login

# tweak session times so you don't have to re-enter passwords every 5min
export AWS_SESSION_TTL=24h
export AWS_ASSUME_ROLE_TTL=1h

# Helm switch from storing objects in kubernetes configmaps to
# secrets by default, but we still use the old default.
export HELM_DRIVER=configmap

# Go 1.16+ sets GO111MODULE to off by default with the intention to
# remove it in Go 1.18, which breaks projects using the dep tool.
# https://blog.golang.org/go116-module-changes
export GO111MODULE=auto
export GOPRIVATE=github.com/DataDog
# END ANSIBLE MANAGED BLOCK
export GITLAB_TOKEN=$(security find-generic-password -a ${USER} -s gitlab_token -w)

# BEGIN personalization
autoload -U compinit
compinit
autoload -U colors
colors
autoload -U select-word-style
select-word-style bash
# If using tmux, Disable bracketed paste
[[ -n "$TMUX" ]] && unset zle_bracketed_paste
test -e $HOME/.nvm/nvm.sh && . $HOME/.nvm/nvm.sh
git_user() {
  user=$(git -C "$1" config user.name)
  author=$(git -C "$1" config duet.env.git-author-initials)
  committer=$(git -C "$1" config duet.env.git-committer-initials)
  if [ -n "${committer}" ]; then
    echo "${author} & ${committer}%{$fg[black]%}@%{$reset_color%}"
  elif [ -n "${author}" ]; then
    echo "${author}%{$fg[black]%}@%{$reset_color%}"
  elif [ -z $user ]; then
    echo "%{$fg_bold[red]%}no user%{$fg[black]%}@%{$reset_color%}"
  else
    echo "$user%{$fg[black]%}@%{$reset_color%}"
  fi
}
git_root() {
  local folder='.'
  for i in $(seq 0 $(pwd|tr -cd '/'|wc -c)); do
    [ -d "$folder/.git" ] && echo "$folder" && return
    folder="../$folder"
  done
}
git_branch() {
  local git_root="$1"
  local line="$2"
  local branch="???"
  local ahead=''
  local behind=''
  case "$line" in
    \#\#\ HEAD*)
      branch="$(git -C "$git_root" tag --points-at HEAD)"
      [ -z "$branch" ] && branch="$(git -C "$git_root" rev-parse --short HEAD)"
      branch="%{$fg[yellow]%}${branch}%{$reset_color%}"
      ;;
    *)
      branch="${line#\#\# }"
      branch="%{$fg[green]%}${branch%%...*}%{$reset_color%}"
      ahead="$(echo $line | sed -En -e 's|^.*(\[ahead ([[:digit:]]+)).*\]$|\2|p')"
      behind="$(echo $line | sed -En -e 's|^.*(\[.*behind ([[:digit:]]+)).*\]$|\2|p')"
      [ -n "$ahead" ] && ahead="%{$fg_bold[white]%}↑%{$reset_color%}$ahead"
      [ -n "$behind" ] && behind="%{$fg_bold[white]%}↓%{$reset_color%}$behind"
      ;;
  esac
  print "${branch}${ahead}${behind}"
}
git_status() {
  local untracked=0
  local modified=0
  local deleted=0
  local staged=0
  local branch=''
  local output=''
  for line in "${(@f)$(git -C "$1" status --porcelain -b 2>/dev/null)}"
  do
    case "$line" in
      \#\#*) branch="$(git_branch "$1" "$line")" ;;
      \?\?*) ((untracked++)) ;;
      U?*|?U*|DD*|AA*|\ M*|\ D*) ((modified++)) ;;
      ?M*|?D*) ((modified++)); ((staged++)) ;;
      ??*) ((staged++)) ;;
    esac
  done
  output="$branch"
  [ $staged -gt 0 ] && output="${output} %{$fg_bold[green]%}S%{$fg_no_bold[black]%}:%{$reset_color$fg[green]%}$staged%{$reset_color%}"
  [ $modified -gt 0 ] && output="${output} %{$fg_bold[red]%}M%{$fg_no_bold[black]%}:%{$reset_color$fg[red]%}$modified%{$reset_color%}"
  [ $deleted -gt 0 ] && output="${output} %{$fg_bold[red]%}D%{$fg_no_bold[black]%}:%{$reset_color$fg[red]%}$deleted%{$reset_color%}"
  [ $untracked -gt 0 ] && output="${output} %{$fg_bold[yellow]%}?%{$fg_no_bold[black]%}:%{$reset_color$fg[yellow]%}$untracked%{$reset_color%}"
  echo "$output"
}
git_prompt_info() {
  local GIT_ROOT="$(git_root)"
  [ -z "$GIT_ROOT" ] && return
  print " $(git_user "$GIT_ROOT")$(git_status "$GIT_ROOT") "
}

set -o emacs
setopt prompt_subst
setopt HIST_IGNORE_DUPS
export HISTSIZE=200
export HISTFILE=~/.zsh_history
export SAVEHIST=200
export LOCALE="en_US.UTF-8"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export CLICOLOR=1
export LSCOLORS=ExFxCxDxBxegedabagacad

# add k8s info to prompt
# brew update
# brew install kube-ps1
source "/opt/homebrew/opt/kube-ps1/share/kube-ps1.sh"
export KUBE_PS1_SYMBOL_USE_IMG=true

export PROMPT='kira.ghandhi@%{$fg_bold[green]%}%m:%{$fg_bold[blue]%}%~%{$fg_bold[green]%}$(git_prompt_info)%{$reset_color%}%#%{$fg_bold[gray]%}%{$reset_color%}$(kube_ps1) '
export EDITOR=vim
export LESS='XFR'
export PIPENV_MAX_DEPTH=10
autoload edit-command-line
zle -N edit-command-line
bindkey '^X^e' edit-command-line
bindkey '^i' expand-or-complete-prefix
bindkey '^u' backward-kill-line
stty stop undef
stty start undef

alias ddgo="cd ${HOME?}/go/src/github.com/DataDog/dd-go"
alias krtb='f(){ host=`kubectl get pods -n=resources-backend --selector=app=resources-toolbox|tail -1|cut -d" " -f1`; kubectl exec -it $host -- /bin/bash };f'

alias tmux-start="tmux new -s kira; tmux a -t kira"
alias tmux-destroy="tmux kill-session -t kira"

alias git-delete-remotes="git branch -r | egrep -v -f /dev/fd/0  <(git branch -vv | grep origin) | xargs git branch -d"
alias to-staging-sql="to-staging resource-sql-querier resource-schema-processor resource-processor resource-sql-analyzer resource-sql-cleaner resource-sql-view-manager"
# END personalization

# dd-go setup
export PATH="/opt/homebrew/opt/openssl@3/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/openssl@3/lib"
export CPPFLAGS="-I/opt/homebrew/opt/openssl@3/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@3/lib/pkgconfig"
# BEGIN DATA-ENG-TOOLS MANAGED BLOCK
# Add data-eng-tools binaries and helpers to the path
export PATH="${DATADOG_ROOT}/data-eng-tools/bin:${PATH?}"
source ${DATADOG_ROOT}/data-eng-tools/dotfiles/helpers
export DYLD_LIBRARY_PATH=/usr/local/opt/openssl/lib
# END DATA-ENG-TOOLS MANAGED BLOCK
# BEGIN DD-ANALYTICS MANAGED BLOCK
# Add required dd-analytics binaries to the path
if [ -z "$LIBRARY_PATH" ]
then
    export LIBRARY_PATH="/opt/homebrew/opt/openssl/lib/"
else
    export LIBRARY_PATH="/opt/homebrew/opt/openssl/lib/:${LIBRARY_PATH?}"
fi

alias j8="export JAVA_HOME=\`/usr/libexec/java_home -v 1.8\`; java -version"
alias j11="export JAVA_HOME=\`/usr/libexec/java_home -v 11\`; java -version"

# Set java 8 as default
export JAVA_HOME=`/usr/libexec/java_home -v 1.8`

# For Spark 3.1.2:
export SCALA_HOME="/opt/homebrew/opt/scala@2.12/"
export PATH=$PATH:$SCALA_HOME/bin
export SPARK_HOME=/usr/local/src/spark-3.1.2-bin-hadoop3.2
export PATH=$PATH:$SPARK_HOME/bin
# Python and Virtualenv Paths
export PATH="/opt/homebrew/opt/virtualenv/bin:$PATH"

# Add dda-cli to the PATH
export PATH=$PATH:${DATADOG_ROOT}/data-eng-tools/bin
# END DD-ANALYTICS MANAGED BLOCK
# BEGIN DATA-ENG-PLATFORM MANAGED BLOCK
eval "$(nodenv init -)"
# END DATA-ENG-PLATFORM MANAGED BLOCK

# Set SSH_AUTH_SOCK to the launchd-managed ssh-agent socket (com.openssh.ssh-agent).
export SSH_AUTH_SOCK=$(launchctl asuser $(id -u) launchctl getenv SSH_AUTH_SOCK)

# Load SSH keys from the keychain if keychain is empty.
ssh-add -l > /dev/null || ssh-add --apple-load-keychain 2> /dev/null
export GITLAB_TOKEN=$(security find-generic-password -a ${USER} -s gitlab_token -w)
