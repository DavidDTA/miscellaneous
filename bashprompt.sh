PS1='$(
  color() {
    # $1 is the color
    # $2 is the text
    echo -ne "\001\x1b[$1\002"
    echo -ne "$2"
    echo -ne "\001\x1b[0m\002"
  }
  if $(git status >/dev/null 2>/dev/null); then
    root="$(git rev-parse --show-toplevel)"
    repo="${root##*/}"
    path="${PWD:${#root}}"
    path=${path/#\//>}
    echo -ne "["
    color "1;32m" "$repo"
    echo -ne "]"
    color "1;36m" "$(git branch | grep --color=never '^[*]' | sed 's/^..//')"
    echo -ne "$path"
    if [[ ! -z "$(git stash list)" ]]; then
      color "1;33m" '\\*'
    fi
    if [[ ! -z "$(git status --porcelain)" ]]; then
      color "1;31m" '\\*'
    fi
  else
    echo -ne "$PWD";
  fi
)\$ '
PROMPT_COMMAND='if [[ "$?" != "0" ]]; then echo -n -e "\07"; fi; history -a'
HISTTIMEFORMAT='%Y-%m-%d %T '

