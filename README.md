# Personal Development Sandbox

<!--toc:start-->
- [Personal Development Sandbox](#personal-development-sandbox)
  - [Bootstrap Installation](#bootstrap-installation)
    - [Existing NeoVim Install](#existing-neovim-install)
  - [Features](#features)
  - [Usage](#usage)
  - [Further Personalization](#further-personalization)
  - [Writing Tests](#writing-tests)
    - [Test Helper Functions](#test-helper-functions)
    - [Tips:](#tips)
    - [Gotchas](#gotchas)
<!--toc:end-->

[![gh-ci][gh-ci-img]][gh-ci]

[gh-ci]: https://github.com/AXGKl/pds/actions/workflows/main.yml
[gh-ci-img]: https://github.com/AXGKl/pds/actions/workflows/main.yml/badge.svg

This installs an IDE and tools, organized so that it won't collide with anything else on the system.


It is intended for

- local and server operation, based on [Mamba][mamba] and [NeoVim][neovim].
- Neovim is your IDE
- Mamba is the package manager for underlying tools the IDE is based upon, incl. a compiler
- python, javascript, lua, shell, markdown lsp support ootb - but extendable

Customization of NeoVim is based on the **[AstroNVim][astronvim]** distribution.

Value Proposition:

- It installs all tools required to turn neovim into an IDE into a directory (`~/pds`)
- It does not require elevated perms to install.
- There are zero requirements on the host (wget and bash), i.e. works on stripped down
  cloud hosts as well
- Comes with tmux based test functions, verifying correct working of the IDE


## Bootstrap Installation

```bash
wget https://raw.githubusercontent.com/AXGKl/pds/master/setup/pds.sh
chmod +x pds.sh
./pds.sh i[nstall]
pds vi # or, recommended: export PATH="~/pds/bin:$PATH, then vi"
```



Requirements: bash, wget.

OS: Currently only tested on Linux.

💡 OSX and BSDs *should* work as well. We do use the Linux style configuration directories though.


This is a run on a minimal debian server:

[![asciicast](https://asciinema.org/a/QObqodPheKWM7A7fUzkveDvzr.svg)](https://asciinema.org/a/QObqodPheKWM7A7fUzkveDvzr)

💡 The installation look and feel may be further improved in the future but you get the idea...

### Existing NeoVim Install

Before installing pds, you might want to run `pds.sh stash mybackup`.

This moves `~/.config/nvim`, `~/.local/state/nvim`, `~/.local/share/nvim` to an archive, ready for
later restoration via `pds restore mybackup`.

`pds clean-all` would erase the existing install.

## Features

- [Here](./setup/astro/README.md) is what you get, config wise, currently.
- pds offers to assert on your config working via tests, see the 'tmux' tests.



## Usage

vi (opening neovim) is installed callable from the app image into `~/pds/bin/vi`.

At pds install time, we've set a function to your `.bashrc` (and `.zshrc`, if in use):

    function pds { source "/home/gk/.config/pds/setup/pds.sh" "$@"; }

This allows to call neovim in 3 different ways:

- `$HOME/bin/vi`: runs neovim - but additional mamba tools are not in your $PATH
- `pds <tool, e.g. vi>`: calls `( insert ~/pds/bin to $PATH && <tool> )`, i.e. you have
  the PATH set, while executing vi.
- `pds a[ctivate]` and subsequently `vi`: First adds the path permanently, then will find
  `vi` (or other tools later)

We recommend the last way

- calling `pds a` e.g. in `.bashrc` or
- `export PATH=$HOME/pds/bin:$PATH` in `.profile`

When activating virtual environments after `pds a`, you'll have their tools (e.g. python)
AND the ones from pds - in the right search order - available in your editor.



## Further Personalization

TBD


## Writing Tests

You can check correct behaviour of your install, using tmux backed tests.

See `*-tmux-*` tests for some blueprints.

tmux is started on a special socket `/tmp/pds...` and therefore should not interfere with
any other session.

The tests are shellscripts and can be executed standalone.

For more output use `pds test -v`, e.g.:

`pds test -v -f <filematch> <testmatch>`

- With -v we produce verbose output.
- But better it is to check what is going on by staring tmux attached session, started
  (and restarted) via  `pds att -l` .
- The main program, when wanting to kill tmux, waits for a key entry, when a session is
  attached.


A testsession might light like so

[![asciicast](https://asciinema.org/a/IPb1eZQ7Ss1Xr3qeWaDhOJAaD.svg)](https://asciinema.org/a/IPb1eZQ7Ss1Xr3qeWaDhOJAaD)



### Test Helper Functions

Open a test file in vim:

- Deindent and write string `$M1` into a file p1.py
- Open it in vi
- Wait until 'foo' is shown on the screen:

```
open p1.py "$M1" foo   
```

Typing and assertions: For improved fun and since we can we use some symbols for function names:

```
⌨️  j k                 # enter j then k (0.05 in between keystrokes)
✔️ shows stuff          # fail when not 'stuff' is on the screen
✔️ max 0.2 shows stuff  # fail when not within 0.2 secs
🚫 max 0.5 shows stuff # fail when 'stuff' is still on screen after max 0.5
```

Convenience:

```
👁️ foo     # eq to: ✔️ shows foo  
👁️ foo 0.4 # eq to: ✔️ max 0.4 shows foo  
😵 foo     # eq to: 🚫 shows foo 
```


The min time deltas are not very small: When waiting for max dts we capture and inspect only every 0.1 seconds.

Lower level commands:

```
T <cmds> # tmux -S <our testsocket> <cmds>
TSC <cmds> # Tmux send command and verify exit code (via && touch <marker file>)
TSK <cmds> # Tmux send keys
```

The cmds sent with `TSC` and `TSK` are safely sent as hex.


### Tips:

- insert simple `read -r foo` to the test program stop at a point, then inspect visually, using `pds att`
- Using `pds att -l` will show you what's going on, even over tmux restarts

### Gotchas

- Mind Test Screen Size

⚠️ Do not assert on content shown only at wider screensizes! Try your tests with the same
tmux geometry than in `pds.sh`'s `run_tmux` function (40x100 by default).

- Popups may not always show

See the LSP Diagnostics user test. Since we got intermittend failures, where in deed the
diagnostics popup did not show up, we let first attempt die within a subshell, then retry once like this:

```
# type j k, then the popup *must* show up:
(✔️ max 1000 diag) || { ⌨️ j k; ✔️ max 1000 diag; }
```

---

[astronvim]: https://astronvim.github.io/
[mamba]:  https://github.com/mamba-org/mamba
[neovim]: https://neovim.io
[pde]: https://www.youtube.com/watch?v=IK_-C0GXfjo
