# Elvish Update Checker
#
# Copyright © 2021
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
use str

var short-hash-length = 7
var update-message = 'Elvish Upgrade Available - update:build-HEAD'
var curl-timeout = 1

fn current-commit-or-tag {
  # Get the tag and commit from the currently installed Elvish binary
  var tag commit = (re:find '^(.[^-]*?)(?:-dev\.(.*))?$' (elvish -buildinfo -json | from-json)[version])[groups][1 2][text]
  if (not-eq $commit '') {
    put $commit
  } else {
    put $tag
  }
}

fn last-modified {
  var platform = (uname)
  if (eq $platform "Darwin") {
    put (/bin/date -u -j -r (/usr/bin/stat -f%B (which elvish)) +"%a, %d %b %Y %H:%M:%S GMT")
  } elif (eq $platform "Linux") {
    put (/usr/bin/env date -u -d (/usr/bin/env stat -c%y (which elvish)) +"%a, %d %b %Y %H:%M:%S GMT")
  }
}

fn check-commit {|&commit=(current-commit-or-tag) &verbose=$false &ignore-ts=$false|
  if (eq $commit unknown) {
    echo (styled "Your elvish does not report a version number in elvish -buildinfo" red)
  } else {
    var error = ?(
      var compare = (
        curl -s -i --max-time $curl-timeout --suppress-connect-headers ^
        -H "Accept: application/vnd.github.v3+json" ^
        (if (not $ignore-ts) { put -H "If-Modified-Since: "(last-modified) }) ^
        https://api.github.com/repos/elves/elvish/compare/$commit...master | slurp
      )
    )
    if (not-eq $error $ok) {
      echo (styled "update:check_commit: Unable to reach github: "(to-string $error) red)
    } else {
      if (re:match "^HTTP/(2|1.1) 304" $compare) {
        return
      }
      var headers raw-json = (re:split "\r\n\r\n" $compare)
      var json = (echo $raw-json | from-json)
      var total-commits = 0
      if (and (has-key $json total_commits)) {
        set total-commits = $json[total_commits]
      }
      if (> $total-commits 0) {
        echo (styled $update-message yellow)
        if $verbose {
          for commit $json[commits] {
            echo (styled $commit[sha][0..$short-hash-length] magenta)': '(styled $commit[commit][message] green)
          }
        }
      }
    }
  }
}

fn async-check-commit {|&commit=(current-commit-or-tag) &verbose=$false|
  check-commit &commit=$commit &verbose=$verbose &
}

fn build-HEAD {|&silent=$false &force=$false|
  var gopath = (go env GOPATH)
  if (re:match $gopath (which elvish)) {
    var commit = (current-commit-or-tag)
    var error = ?(
      var from-master = (
        curl -s https://api.github.com/repos/elves/elvish/compare/$commit...master | from-json
      )
    )
    if (not-eq $error $ok) {
      echo (styled "Unable to query github to determine number of commits since last tag" red)
    }

    if (and (not $force) (not-eq $commit unknown) (== $from-master[total_commits] (float64 0))) {
      if (not $silent) {
        echo (styled "No changes, not rebuilding" yellow)
      }
      return
    }

    var new-commit = (or (set _ = ?(put $from-master[commits][-1][sha])) "master")

    if (not $silent) {
      echo (styled "Building and installing Elvish "$new-commit" using go get" yellow)
    }
    var build-ok = ?(
      git -C $gopath"/src/src.elv.sh" pull; ^
      make -C $gopath"/src/src.elv.sh" get
    )
    if $build-ok {
      if (not $silent) {
        echo (styled "Installed Elvish "(str:join "\n" [(elvish -buildinfo)]) green)
      }
    } else {
      echo (styled "Error updating Elvish: "(to-string $build-ok) red)
    }
  } else {
    # Elvish is not in $E:GOPATH, use native package manager
    echo (styled "Elvish is not installed via go get, not rebuilding" red)
  }
}
