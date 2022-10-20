gg() {
  local query="\b$1\b"
  shift
  if (($#)); then
    grep "$query" "$@" -r
  else
    grep "$query" * -r
  fi
}
