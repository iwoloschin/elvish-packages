# Powernerd Elvish Theme
#
# Copyright © 2019
#   Ian Woloschin - ian@woloschin.com
#
# A Powerline-inspired theme with Nerd Fonts
#
# Install:
#   epm:install github.com/iwoloschin/elvish-packages
#
# Use:
#   use github.com/iwoloschin/elvish-packages/powernerd

use re
use github.com/muesli/elvish-libs/git

### Default Settings ###
default-user = ""
force-hostname = $false
timestamp-format = "%r"
prompt-path-length = 3
prompt-lines = [
  [session-helper hostname path writeable git]
  [time user virtualenv background-jobs]
]
rprompt-lines = []

nerd-glyphs = [
  &home= ''
  &separator= ''
  &dirseparator= ''
  &virtualenv= ''
  &user-prompt= ''
  &root-prompt= ''
  &time= ''
  &unwriteable= ''
  &background-jobs= ''
  &git-ahead= ''
  &git-behind= ''
  &git-commit= ''
  &git-name= ''
  &git-untracked= ''
  &git-staged= ''
  &git-dirty= ''
  &session-helper= ''
]
glyphs = $nerd-glyphs

# Color numbers come from the 8 bit chart here:
#   https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit
# Format:
#   &segment-name= [$Text-Color $Background-Color]
segment-colors = [
  &path= ['color231' 'color92']
  &hostname= ['color232' 'color51']
  &virtualenv= ['color226' 'color21']
  &user= ['color231' 'color239']
  &time= ['color232' 'color220']
  &unwriteable= ['color16' 'color196']
  &background-jobs= ['color214' 'color17']
  &end-prompt-user= ['color231' 'color36']
  &end-prompt-root= ['color231' 'color196']
  &git-ahead= ['color231' 'color52']
  &git-behind= ['color231' 'color52']
  &git-commit= ['color16' 'color226']
  &git-dirty= ['color231' 'color160']
  &git-name= ['color16' 'color81']
  &git-staged= ['color231' 'color28']
  &git-untracked= ['color231' 'color196']
]

### Private Theme Variables
background = ""
git-status = [&]
session-helper-bg-color = (+ (% $pid 216) 16)
session-helper-fg-color = 0

### Private Theme Functions
fn session-helper-color-picker {
  if (>= (% (- $session-helper-bg-color 16) 36) 18) {
    session-helper-fg-color = 'color232'
  } else {
    session-helper-fg-color = 'color255'
  }
}

fn build-segment [colors @chars]{
  if (not-eq $background '') {
    styled $glyphs[separator] $background bg-$colors[1]
  }
  styled " "(joins '' $chars)" " $colors[0] bg-$colors[1]
  background = $colors[1]
}

### System Segments ###

fn segment-user {
  if (not-eq $default-user (e:whoami)) {
    build-segment $segment-colors[user] (e:whoami)
  }
}

fn segment-hostname {
  if (or $force-hostname (not-eq $E:SSH_CLIENT '')) {
    build-segment $segment-colors[hostname] (e:hostname)
  }
}

fn segment-time {
  build-segment $segment-colors[time] $glyphs[time] ' ' (date +$timestamp-format)
}

fn segment-writeable {
  if (not-eq ?(test -w $pwd) $ok) {
    build-segment $segment-colors[unwriteable] $glyphs[unwriteable]
  }
}

fn segment-background-jobs {
  if (> $num-bg-jobs 0) {
    build-segment $segment-colors[background-jobs] $glyphs[background-jobs] ' ' $num-bg-jobs
  }
}

### Path Segments & Helper Functions ###

fn generate-path {
  path = (re:replace '~' $glyphs[home] (tilde-abbr $pwd))
  path = (re:replace '(\.?[^/'$glyphs[home]']{'$prompt-path-length'})[^/]*/' '$1/' $path)
  directories = [(splits / $path)]
  if (eq $directories[0] '') {
    directories = $directories[1:]
  }
  put $directories[0]

  for directory $directories[1:] {
    put " "$glyphs[dirseparator]" "$directory
  }
}

fn segment-path {
  build-segment $segment-colors[path] (generate-path)
}

### Session Helper Segments ###
fn segment-session-helper {
  build-segment [$session-helper-fg-color color$session-helper-bg-color] $glyphs[session-helper]
}

### Python Segments ###

fn segment-virtualenv {
  if (not-eq $E:VIRTUAL_ENV "") {
    virtualenv = (re:replace '\/.*\/' ''  $E:VIRTUAL_ENV)
  	build-segment $segment-colors[virtualenv] $glyphs[virtualenv] " " $virtualenv
	}
}

### Git Repository Segments ###

fn segment-git-name {
  if (not-eq $git-status[branch-name] "") {
    build-segment $segment-colors[git-name] $glyphs[git-name] " " $git-status[branch-name]
  }
}

fn segment-git-commit {
  if (eq $git-status[is-git-repo] $true) {
    error = ?(commit-or-tag = (git describe --exact-match HEAD 2> /dev/null))
    if (not-eq $error $ok) {
        error = ?(commit-or-tag = (git rev-parse --short HEAD 2> /dev/null))
        if (not-eq $error $ok) {
          commit-or-tag = 'No Commits'
        }
    }
    if (not-eq $commit-or-tag "") {
      build-segment $segment-colors[git-commit] $glyphs[git-commit] " " $commit-or-tag
    }
  }
}

fn segment-git-ahead-behind {
  if (> $git-status[rev-ahead] 0) {
    build-segment $segment-colors[git-ahead] $git-status[rev-ahead] " " $glyphs[git-ahead]
  }
  if (> $git-status[rev-behind] 0) {
    build-segment $segment-colors[git-behind] $git-status[rev-behind] " " $glyphs[git-behind]
  }
}

fn segment-git-dirty {
  if (> $git-status[local-modified-count] 0) {
    build-segment $segment-colors[git-dirty] $git-status[local-modified-count] " " $glyphs[git-dirty]
  }
}

fn segment-git-untracked {
  if (> $git-status[untracked-count] 0) {
    build-segment $segment-colors[git-untracked] $git-status[untracked-count] " " $glyphs[git-untracked]
  }
}

fn segment-git-staged {
  staged-count = (+ $git-status[staged-modified-count staged-deleted-count staged-added-count renamed-count copied-count])
  if (> $staged-count 0) {
    build-segment $segment-colors[git-staged] ""$staged-count " " $glyphs[git-staged]
  }
}

fn segment-git {
  segment-git-name
  segment-git-commit
  segment-git-ahead-behind
  segment-git-dirty
  segment-git-staged
  segment-git-untracked
}

### End of Prompt Segment ###

fn end-prompt {
  if (not-eq 0 (id -u)) {
    build-segment $segment-colors[end-prompt-user] $glyphs[user-prompt]
  } else {
    build-segment $segment-colors[end-prompt-root] $glyphs[root-prompt]
  }
  styled $glyphs[separator] $background
}

segments = [
  &session-helper= $segment-session-helper~
  &path= $segment-path~
  &user= $segment-user~
  &hostname= $segment-hostname~
  &writeable= $segment-writeable~
  &background-jobs= $segment-background-jobs~
  &virtualenv= $segment-virtualenv~
  &time= $segment-time~
  &git= $segment-git~
  &git-ahead-behind= $segment-git-ahead-behind~
  &git-untracked= $segment-git-untracked~
]

### Prompt Building ###

fn build-prompt [lines]{
  if (eq $lines []) {
    return
  }

  first-line = $true
  for line $lines {
    if (bool $first-line) {
      first-line = $false
    } else {
      styled $glyphs[separator] $background
      put "\n"
    }

    background = ''
    for segment $line {
      $segments[$segment]
    }
  }
  end-prompt
  put " "
}

fn prompt {
  git-status = (git:status &counts=$true)
  build-prompt $prompt-lines
}

fn rprompt {
  build-prompt $rprompt-lines
}

fn init {
  session-helper-color-picker
  edit:prompt = $prompt~
  edit:rprompt = $rprompt~
}

init
