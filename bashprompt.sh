PS1='$(
  color() {
    # $1 is the color
    # $2 is the text
    echo -ne "\001\x1b[$1\002"
    echo -ne "$2"
    echo -ne "\001\x1b[0m\002"
  }
  if $(git status >/dev/null 2>/dev/null); then
    referencebranch="origin/master"
    root="$(git rev-parse --show-toplevel)"
    repo="${root##*/}"
    path="${PWD:${#root}}"
    path=${path/#\//>}
    commit=$(git rev-parse HEAD | tr -d "\n")
    mergebase=$(git merge-base $referencebranch $commit | tr -d "\n")
    mergecount=$(git rev-list ${mergebase}..${commit} --count | tr -d "\n")
    echo -ne "["
    color "1;32m" "$repo"
    echo -ne "]"
    color "1;36m" "($(git show-ref | grep --color=never "^$commit" | sed "s#^[^ ]* ##" | grep -v --color=never "^refs/remotes/[^/]*/HEAD$" | sed "s#^refs/remotes/##" | sed "s#^refs/heads/##" | sed "s#^refs/tags/#tags/#" | sed "s/^/ /" | paste -sd ","  - | sed "s/^ //"); +$mergecount)"
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
trap 'SECONDS_START=${SECONDS_START:-$SECONDS}' DEBUG
PROMPT_COMMAND='if [[ "$?" != "0" ]] || [[ $(($SECONDS - $SECONDS_START)) > 3 ]]; then echo -n -e "\07"; fi; history -a; unset SECONDS_START'
HISTTIMEFORMAT='%Y-%m-%d %T '
