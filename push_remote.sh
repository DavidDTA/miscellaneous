push_remote() {
  # Pushes the local working directory to dta-remote on github.  Does not change the working directory, index, or HEAD.
  local message="dta remote push at $(date -u +%FT%TZ)"
  local index=$(git write-tree)
  local branch=${1:-dta-remote}
  git add --all
  git update-ref "refs/remotes/origin/$branch" $(git commit-tree $(git write-tree) -p HEAD -m "$message")
  git read-tree $index
  git push origin "refs/remotes/origin/$branch:refs/heads/$branch" --force
}
