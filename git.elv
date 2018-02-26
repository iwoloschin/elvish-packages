# Git Methods for Elvish Themes
#
# Copyright © 2018
#   Ian Woloschin - ian@woloschin.com
#
# License: github.com/iwoloschin/elvish-packages/LICENSE
#
# A collection of simple git methods to gather the current status of a git
# repository, intended for use as part of an Elvish theme.  The only public
# interfaces in this module are the 'check' function and the 'status' map,
# all other functions should be considered private as they only update the
# 'status' map, they do not return any information on their own.
#
# Install:
#   epm:install github.com/iwoloschin/elvish-packages
#
# Use:
#   use github.com/iwoloschin/elvish-packages/git

status = [
    &ahead= '0'
    &behind= '0'
    &dirty= '0'
    &name= ''
    &staged= '0'
    &untracked= '0'
]

fn -ahead-behind {
    # Get the number of commits ahead/behind upstream, if upstream exists
    error = ?(
        ahead behind = (
            splits "\t" (
                git rev-list --left-right --count $status[name]'...@{upstream}' 2> /dev/null
            )
        )
    )
    if (eq $error $ok) {
        status[ahead] = $ahead
        status[behind] = $behind
    }
}

fn -branch-name {
    # Get the current git branch name
    status[name] = (git rev-parse --abbrev-ref HEAD)
}

fn -dirty {
    # Get the number of dirty files in the current repo
    status[dirty] = (count [(git diff --name-only $status[name])])
}

fn -staged {
    # Get the number of staged files in the current repo
    status[staged] = (count [(git diff --cached --numstat)])
}

fn -untracked {
    # Get the number of untracked files in the current repo
    status[untracked] = (count [(git ls-files --exclude-standard --others)])
}

fn check {
    # Gather status information if in a git repo
    if (bool ?(git rev-parse --is-inside-work-tree 2> /dev/null)) {
        # Branch name *must* be discovered first to use in other commands!
        -branch-name
        -ahead-behind
        -dirty
        -staged
        -untracked

    } else {
        status[ahead] = '0'
        status[behind] = '0'
        status[name] = ''
        status[staged] = '0'
        status[untracked] = '0'
    }
}
