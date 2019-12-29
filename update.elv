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
curl-timeout = 1

fn current-commit-or-tag {
  # Get the tag and commit from the currently installed Elvish binary
  tag commit = (re:find '^(.*?)(?:-\d+-g(.*))?$' (elvish -buildinfo -json | from-json)[version])[groups][1 2][text]
  if (not-eq $commit '') {
    put $commit
  } else {
    put $tag
  }
}

fn last-modified {
  platform = (uname)
  if (eq $platform "Darwin") {
    put (/bin/date -u -j -r (/usr/bin/stat -f%B (which elvish)) +"%a, %d %b %Y %H:%M:%S GMT")
  } elif (eq $platform "Linux") {
    put (/bin/date -u -d (/usr/bin/stat -c%y (which elvish)) +"%a, %d %b %Y %H:%M:%S GMT")
  }
}

fn check-commit [&commit=(current-commit-or-tag) &verbose=$false]{
  if (eq $commit unknown) {
    echo (styled "Your elvish does not report a version number in elvish -buildinfo" red)
  } else {
    error = ?(
      compare = (
        curl -s -i --max-time $curl-timeout \
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
      total-commits = 0
      if (and (has-key $json total_commits)) {
        total-commits = $json[total_commits]
      }
      if (> $total-commits 0) {
        echo (styled $update-message yellow)
        if $verbose {
          for commit $json[commits] {
            echo (styled $commit[sha][0:$short-hash-length] magenta)': '(styled $commit[commit][message] green)
          }
        }
      }
    }
  }
}

fn async-check-commit [&commit=(current-commit-or-tag) &verbose=$false]{
  check-commit &commit=$commit &verbose=$verbose &
}

fn build-HEAD [&silent=$false]{
  platform = (uname)

  if (re:match $E:GOPATH (which elvish)) {
    # Elvish is in $E:GOPATH indicating that it was installed via 'go get'
    error = ?(
      tags = (curl -s https://api.github.com/repos/elves/elvish/tags | from-json)
    )
    if (not-eq $error $ok) {
      echo (styled "Unable to query github for latest version" red)
    }
    tag = $tags[0][name]
    commit = $tags[0][commit][sha]
    error = ?(
      from-master = (
        curl -s https://api.github.com/repos/elves/elvish/compare/$commit...master | from-json
      )
    )
    if (not-eq $error $ok) {
      echo (styled "Unable to query github to determine number of commits since last tag" red)
    }
    total-commits = 0
    if (and (has-key $from-master total_commits)) {
      total-commits = $from-master[total_commits]
    }
    commit-version = ""
    if (> $total-commits 0) {
      short-last-commit = (re:find "^.{"$short-hash-length"}" $from-master[commits][-1][sha])[text]
      commit-version = "-"$total-commits"-g"$short-last-commit
    }
    version = $tag$commit-version

    if (not $silent) {
      echo (styled "Building and installing Elvish "$version" using go get" yellow)
    }
    build_ok = ?(
      go get \
      -trimpath \
      -ldflags "-X github.com/elves/elvish/pkg/buildinfo.Version="$version" -X github.com/elves/elvish/pkg/buildinfo.Reproducible=true" \
      github.com/elves/elvish
    )
    if $build_ok {
      if (not $silent) {
        echo (styled "Installed Elvish "(joins "\n" [(elvish -buildinfo)]) green)
      }
    } else {
      echo (styled "Error updating Elvish: "(to-string $build_ok) red)
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
