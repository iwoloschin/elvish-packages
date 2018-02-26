# Python Virtual Environment Utilites for Elvish
#
# Copyright © 2018
#   Ian Woloschin - ian@woloschin.com
#
# License: github.com/iwoloschin/elvish-packages/LICENSE
#
# Activation & deactivation methods for working with Python virtual
# environments in Elvish.
#
# Install:
#   epm:install github.com/iwoloschin/elvish-packages
#
# Use:
#   use github.com/iwoloschin/elvish-packages/python

virtual-env-prefix = $E:HOME/.virtualenvs

fn activate [name]{
    E:VIRTUAL_ENV = $virtual-env-prefix/$name
    E:_OLD_VIRTUAL_PATH = $E:PATH
    E:PATH = $E:VIRTUAL_ENV/bin:$E:PATH

    if (not-eq $E:PYTHONHOME "") {
        E:_OLD_VIRTUAL_PYTHONHOME = $E:PYTHONHOME
        del E:PYTHONHOME
    }
}

edit:arg-completer[python:activate] = [@args]{ e:ls $virtual-env-prefix}

fn deactivate {
    if (not-eq $E:_OLD_VIRTUAL_PATH "") {
        E:PATH = $E:_OLD_VIRTUAL_PATH
        del E:_OLD_VIRTUAL_PATH
    }

    if (not-eq $E:_OLD_VIRTUAL_PYTHONHOME "") {
        E:PYTHONHOME = $E:_OLD_VIRTUAL_PYTHONHOME
        del E:_OLD_VIRTUAL_PYTHONHOME
    }

    if (not-eq $E:VIRTUAL_ENV "") {
        del E:VIRTUAL_ENV
    }
}
