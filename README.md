# Ian's Elvish Packages

# Use
In order to use any modules included in this package add the following lines to `~/.elvish/rc.elv`:
```elvish
use epm
epm:install &silent-if-installed=$true github.com/iwoloschin/elvish-packages
```

## Git
A collection of methods to help gather useful information about a git repository for use in building a prompt.  The intended use case of this module is to call `git:check` when a prompt is built, and rely on the information stored in `git:status` to build the prompt.  All other functions should be considered 'private', there's no harm in calling them, but they do not return anything themselves, they only update `git:status`.

### How To Use
In your `~/.elvish/rc.elv` file, put the following lines:
```elvish
use github.com/iwoloschin/elvish-packages/git
```
In your prompt theme, when building the prompt call `git:check`, this will populate `git:status` with the following information:
```elvish
git:status[ahead]
git:status[behind]
git:status[dirty]
git:status[name]
git:status[staged]
git:status[untracked]
```

## Python
A set of simple functions to help Elvish work with Python Virtual Environments created by the standard [Virtualenv](https://virtualenv.pypa.io/en/stable/) tool. Instead of relying on shell scripts installed as part of the Virtual Environment this module utilizes Elvish functions to activate & deactivate Virtual Environments.

### How To Use
In your `~/.elvish/rc.elv` file, put the following lines:
```elvish
use github.com/iwoloschin/elvish-packages/python
```

### Optional Helpers
This module assumes all virtual environments are located under `~/.virtualenvs`, but this can easily be changed if needed.  Currently only one prefix is supported.
```elvish
python:virtual-env-prefix = /path/to/virtual/environments
```

While it is completely possible to use the Python module without any extra work, it becomes unwieldy to type in `python:activate virtualenv` or `python:deactivate` every time you want to touch a virtual environment.  One solution is to use [zzamboni's alias module](https://github.com/zzamboni/elvish-modules/blob/master/alias.org) to define aliases that can then be called as just `activate` or `deactivate`.  If using aliases take care to also update the argument completer variable, otherwise Elvish will be unable to automatically complete virtual environment names.
```elvish
alias:new activate python:activate
alias:new deactivate python:deactivate
edit:arg-completer[activate] = $edit:arg-completer[python:activate]
```
