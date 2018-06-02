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

short-hash-length = 7
update-message = 'Elvish Upgrade Available - update:build-HEAD'

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
      echo $update-message
  }
}

fn deferred-check-commit [commit]{
  curl -s https://api.github.com/repos/elves/elvish/compare/$commit...master > ~/.elvish/commit.json &
}

fn deferred-compare-commit {
  error = ?(commit = (cat ~/.elvish/commit.json | from-json))
  if (and (eq $error $ok) (> $commit[total_commits] 0)) {
    echo $update-message
  }
}

fn build-HEAD {
  platform = (uname)

  if (re:match $E:GOPATH (which elvish)) {
    # Elvish is in $E:GOPATH indicating that it was installed via 'go get'
    error = ?(
      response = (
        curl -s https://api.github.com/repos/elves/elvish/commits/master | from-json
      )
    )
    if (not-eq $error $ok) {
      echo "Unable to query Github for latest version"
      return
    }
    hash = $response[sha]
    short-hash = (re:find "^.{"$short-hash-length"}" $hash)[text]
    error = ?(
      go get \
      -ldflags \
        "-X github.com/elves/elvish/build.Version="$short-hash \
      -u github.com/elves/elvish
    )
    if (not-eq $error $ok) {
      echo "Error updating Elvish"
    }
  } else {
    # Elvish is not in $E:GOPATH, try using native package managers to upgrade
    if (eq $platform "Darwin") {
      brew reinstall elvish
    }
  }
}

fn check-for-update {
 error = ?(commit = (cat ~/.elvish/commit.json | from-json))
 if (and (eq $error $ok) (> $commit[total_commits] 0)) {
   echo $update-message
  } elif (not-eq $error $ok) {
    echo 'Error'
  }
}

# Run the update check when module is 'used' in rc.elv
check-for-update
deferred-check-commit (current-commit)
