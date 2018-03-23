# Powernerd Elvish Theme
#
# Copyright © 2018
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
timestamp-format = "%r"
prompt-path-length = 3
prompt-lines = [
  [session-helper hostname path writeable git]
  [time user virtualenv]
]
rprompt-lines = []

nerd-glyphs = [
  &home= ''
  &separator= ''
  &dirseparator= ''
  &virtualenv= ''
  &user-prompt= ''
  &root-prompt= ''
  &time= ''
  &unwriteable= ''
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
  &path= [231 92]
  &hostname= [232 51]
  &virtualenv= [226 21]
  &user= [231 239]
  &time= [232 220]
  &unwriteable= [16 196]
  &end-prompt-user= [231 36]
  &end-prompt-root= [231 196]
  &git-ahead= [231 52]
  &git-behind= [231 52]
  &git-commit= [16 226]
  &git-dirty= [231 160]
  &git-name= [16 81]
  &git-staged= [231 28]
  &git-untracked= [231 196]
]

### Private Theme Variables
background = ""
git-status = [&]

session-helper-bg-color = (+ (% $pid 216) 16)
session-helper-fg-color = 0

### Private Theme Functions
fn session-helper-color-picker {
  if (>= (% (- $session-helper-bg-color 16) 36) 18) {
    session-helper-fg-color = 232
  } else {
    session-helper-fg-color = 255
  }
}


# Probably need a session-helper-hash function to select proper fg/bg colors

fn build-segment [colors @chars]{
  if (not-eq $background '') {
    edit:styled $glyphs[separator] "38;5;"$background";48;5;"$colors[1]
  }
  edit:styled " "(joins '' $chars)" " "38;5;"$colors[0]";48;5;"$colors[1]
  background = $colors[1]
}

### User, Hostname & Time Segments ###

fn segment-user {
  if (not-eq $default-user (e:whoami)) {
    build-segment $segment-colors[user] (e:whoami)
  }
}

fn segment-hostname {
  if (not-eq $E:SSH_CLIENT '') {
    build-segment $segment-colors[hostname] (e:hostname)
  }
}

fn segment-time {
  build-segment $segment-colors[time] $glyphs[time] (date +$timestamp-format)
}

fn segment-writeable {
  if (not-eq ?(test -w $pwd) $ok) {
    build-segment $segment-colors[unwriteable] $glyphs[unwriteable]
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
  build-segment [$session-helper-fg-color $session-helper-bg-color] $glyphs[session-helper]
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
    build-segment $segment-colors[git-staged] $staged-count " " $glyphs[git-staged]
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
  edit:styled $glyphs[separator] "38;5;"$background";48;5;0"
}

segments = [
  &session-helper= $segment-session-helper~
  &path= $segment-path~
  &user= $segment-user~
  &hostname= $segment-hostname~
  &writeable= $segment-writeable~
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
      edit:styled $glyphs[separator] "38;5;"$background";48;5;0"
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
