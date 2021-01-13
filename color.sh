color() {
  # $1 is the color
  # $2 is the text
  # $3 is the escape sequence start (optoinal)
  # $4 is the escape sequence end (optional)
  echo -ne "$3\x1b[$1$4"
  echo -ne "$2"
  echo -ne "$3\x1b[0m$4"
}
