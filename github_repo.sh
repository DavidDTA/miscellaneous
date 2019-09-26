# Prints the repo owner and name, separated by a space
github_repo() {
    hub browse --url | sed -n 's|^https://github.com/\([^ /]*\)/\([^ /]*\)$|\1 \2|p'
}
