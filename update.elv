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
#   Normal:
#     use github.com/iwoloschin/elvish-packages/update
#     update:check-commit
#
#   Async:
#     use github.com/iwoloschin/elvish-packages/update
#     notify-bg-job-success = $false
#     update:async-check-commit
#     # End of elv.rc
#     notify-bg-job-success = $true
#


use re

short-hash-length = 7
update-message = 'Elvish Upgrade Available - update:build-HEAD'

fn current-commit {
  # Get the commit from the currently installed Elvish binary
  put (or (
      re:find "HEAD-([a-z0-9]{7})" (elvish -buildinfo -json | from-json)[version]
  )[groups][1][text] unknown)
}

fn check-commit [&commit=(current-commit)]{
  if (eq $commit unknown) {
    echo (styled "Your elvish does not report a version number in elvish -buildinfo" red)
  } else {
    error = ?(
      compare = (curl -s -i https://api.github.com/repos/elves/elvish/compare/$commit...master | slurp)
    )
    if (not-eq $error $ok) {
      echo (styled "Unable to reach github: "(to-string $error) red)
    } else {
      compare = [(re:split "\r\n\r\n" $compare)]
      headers = $compare[-2]
      json = (echo $compare[-1] | from-json)
      if (and (has-key $json total_commits) (> $json[total_commits] 0)) {
        echo (styled $update-message yellow)
      }
    }
  }
}

fn async-check-commit [&commit=(current-commit)]{
  check-commit &commit=$commit &
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
    } elif (eq $platform "Linux") {
      if (eq ?(test -f /etc/gentoo-release) $ok) {
        # Funtoo/Gentoo
        sudo emerge elvish
      }
    }
  }
}
