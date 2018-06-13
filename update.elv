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
#     # Beginning of rc.elv
#     use github.com/iwoloschin/elvish-packages/update
#     notify-bg-job-success = $false
#     update:async-check-commit
#     # End of elv.rc
#     while (> $num-bg-jobs 0) {
#       sleep 0.01
#     }
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

fn last-modified {
  platform = (uname)
  if (eq $platform "Darwin") {
    put (/bin/date -u -j -r (/usr/bin/stat -f%B (which elvish)) +"%a, %d %b %Y %H:%M:%S GMT")
  } elif (eq $platform "Linux") {
    put (/bin/date -u -d (/usr/bin/stat -c%y (which elvish)) +"%a, %d %b %Y %H:%M:%S GMT")
  }
}

fn check-commit [&commit=(current-commit) &verbose=$false]{
  if (eq $commit unknown) {
    echo (styled "Your elvish does not report a version number in elvish -buildinfo" red)
  } else {
    error = ?(
      compare = (
        curl -s -i --max-time 1 \
        -H "If-Modified-Since: "(last-modified) \
        https://api.github.com/repos/elves/elvish/compare/$commit...master | slurp
      )
    )
    if (not-eq $error $ok) {
      echo (styled "update:check_commit: Unable to reach github: "(to-string $error) red)
    } else {
      if (re:match "HTTP/1.1 304 Not Modified" $compare) {
        return
      }
      compare = [(re:split "\r\n\r\n" $compare)]
      headers = $compare[-2]
      json = (echo $compare[-1] | from-json)
      if (and (has-key $json total_commits) (> $json[total_commits] 0)) {
        echo (styled $update-message yellow)
        if $verbose {
          for commit $json[commits] {
            echo (styled $commit[commit][tree][sha][0:$short-hash-length] magenta)': '(styled $commit[commit][message] green)
          }
        }
      }
    }
  }
}

fn async-check-commit [&commit=(current-commit) &verbose=$false]{
  check-commit &commit=$commit &verbose=$verbose &
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
      "-X github.com/elves/elvish/build.Version=HEAD-"$short-hash \
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
