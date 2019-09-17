color() {
  # $1 is the color
  # $2 is the text
  echo -ne "\001\x1b[$1\002"
  echo -ne "$2"
  echo -ne "\001\x1b[0m\002"
}
