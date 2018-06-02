# Elvish Update Checker
#
# Copyright © 2018
#   Ian Woloschin - ian@woloschin.com
#
# A tool to check if a newer version of Elvish is available.  Currently only
# supports checking against HEAD.  Intended to be used in ~/.elvish/rc.elv as
# a one time check when a new shell is started, but could be adapted to be
# used as a prompt segment as well (but beware of Github's API limits).
#
# Install:
#   epm:install github.com/iwoloschin/elvish-packages
#
# Use:
#   use github.com/iwoloschin/elvish-packages/update

use re

fn current-commit {
  # Get the commit from the currently installed Elvish binary
  put (
    re:find "HEAD-([a-z0-9]{7})" (elvish -buildinfo -json | from-json)[version]
  )[groups][1][text]
}

fn check-commit [commit]{
  # Check if $commit is the latest commit to Elvish's master branch
  error = ?(
    response = (
      curl -s https://api.github.com/repos/elves/elvish/compare/$commit...master | from-json
    )
  )
  if (and (eq $error $ok) (> $response[total_commits] 0)) {
    echo 'Elvish Upgrade Available'
  }
}

# Run the update check when module is 'used' in rc.elv
check-commit (current-commit)
