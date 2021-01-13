PS1='$('$(dirname "$BASH_SOURCE")'/prompt "\001" "\002")'
trap 'SECONDS_START=${SECONDS_START:-$SECONDS}' DEBUG
PROMPT_COMMAND='if [[ "$?" != "0" ]] || [[ $(($SECONDS - ${SECONDS_START:-$SECONDS})) > 3 ]]; then echo -n -e "\07"; fi; history -a; unset SECONDS_START'
HISTTIMEFORMAT='%Y-%m-%d %T '

