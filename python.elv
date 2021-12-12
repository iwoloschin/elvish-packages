# Python Virtual Environment Utilites for Elvish
#
# Copyright © 2018
#   Ian Woloschin - ian@woloschin.com
#
# License: github.com/iwoloschin/elvish-packages/LICENSE
#
# Activation & deactivation methods for working with Python virtual
# environments in Elvish.  Will not allow invalid Virtual
# Environments to be activated.
#
# Install:
#   epm:install github.com/iwoloschin/elvish-packages
#
# Use:
#   use github.com/iwoloschin/elvish-packages/python

var virtualenv-directory = $E:HOME/.virtualenvs

fn activate {|name|
  var virtualenvs = [(ls $virtualenv-directory)]

  var error = ?(var confirmed-name = (
    each {|virtualenv|
      if (eq $name $virtualenv) { put $name }
    } $virtualenvs)
  )

  if (eq $name $confirmed-name) {
    set E:VIRTUAL_ENV = $virtualenv-directory/$name
    set E:_OLD_VIRTUAL_PATH = $E:PATH
    set E:PATH = $E:VIRTUAL_ENV/bin:$E:PATH

    if (not-eq $E:PYTHONHOME "") {
      set E:_OLD_VIRTUAL_PYTHONHOME = $E:PYTHONHOME
      del E:PYTHONHOME
    }
  } else {
    echo 'Virtual Environment "'$name'" not found.'
  }
}

set edit:completion:arg-completer[python:activate] = {|@args|
  e:ls $virtualenv-directory
}

fn deactivate {
  if (not-eq $E:_OLD_VIRTUAL_PATH "") {
    set E:PATH = $E:_OLD_VIRTUAL_PATH
    del E:_OLD_VIRTUAL_PATH
  }

  if (not-eq $E:_OLD_VIRTUAL_PYTHONHOME "") {
    set E:PYTHONHOME = $E:_OLD_VIRTUAL_PYTHONHOME
    del E:_OLD_VIRTUAL_PYTHONHOME
  }

  if (not-eq $E:VIRTUAL_ENV "") {
    del E:VIRTUAL_ENV
  }
}

fn list-virtualenvs {
  all [(ls $virtualenv-directory)]
}
