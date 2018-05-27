# Elvish Update Checker
#
# Copyright © 2018
#   Ian Woloschin - ian@woloschin.com
#
# A tool to check if new versions of Elvish are available,
# intended to be used in rc.elv to check when Elvish starts
#
#
# Install:
#   epm:install github.com/iwoloschin/elvish-packages
#
# Use:
#   use github.com/iwoloschin/elvish-packages/update

use re

fn current-commit {
  buildinfo = [(elvish -buildinfo)]
  for line $buildinfo {
    if (re:match "HEAD-([a-z0-9]{7})" $line) {
      put (re:find "HEAD-([a-z0-9]{7})" $line)[groups][1][text]
    }
  }
}

fn check-commit [commit]{
  error = ?(
    response = (
      curl -s https://api.github.com/repos/elves/elvish/compare/$commit...master | from-json
    )
  )
  if (and (eq $error $ok) (> $response[total_commits] 0)) {
      echo 'Elvish Upgrade Available'
  }
}

check-commit (current-commit)
