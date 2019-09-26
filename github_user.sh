github_user() {
    hub api graphql --raw-field query='query { viewer { login } }' | jq '.data.viewer.login' --raw-output
}
