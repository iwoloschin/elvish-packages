VIRTUAL_ENV_PREFIX = $E:HOME/.virtualenvs

fn activate [name]{
  E:VIRTUAL_ENV = $VIRTUAL_ENV_PREFIX/$name
  E:_OLD_VIRTUAL_PATH = $E:PATH
  E:PATH = $E:VIRTUAL_ENV/bin:$E:PATH

  if (not-eq $E:PYTHONHOME "") {
    E:_OLD_VIRTUAL_PYTHONHOME = $E:PYTHONHOME
    del E:PYTHONHOME
  }
}

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

edit:arg-completer[python:activate] = [@args]{
    e:ls $VIRTUAL_ENV_PREFIX
}
