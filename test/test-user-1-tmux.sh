#!/usr/bin/env bash
## These tests may fail, depending on user config
set -o errexit
. "$(dirname "$0")/tools.sh"

# -------------------------------------------------------------------- Markdown

function test-markdown-folds { # initially, folds shall stay open
    M1='
    # Head1
    intro
    ## H2
    h2 stuff
    ## H3
    h3 stuff
    ## H4
    h4 stuff
    '
    open 'm1.md' "$M1" Head1
    ✔️ shows intro
    ✔️ shows intro
    ✔️ shows H2
    ✔️ shows H3
    ✔️ shows 'h4 stuff'
    vi_quit
}

function test-markdown-tables { # tables with ; ,t autoformats
    M1='
    ; can be used for |

    ; foo |bar; baz
    ;-;-;-
    |a;bbbb;c
    ;aasd;aasdfaa|aad

    # harder, must insert a ; before replacement:

    | Foo |bar| baz
    |-|-|-
    |A|bbbb|c
    |Aasd|aasdfaa|aad

    # Marker
    '
    open 'm1.md' "$M1" Marker
    ⌨️ gg
    ⌨️ 4j
    ⌨️ ,t # does the magic

    👁️ '| foo  | bar     | baz' 1000
    👁️ '| -    | -       | -'
    👁️ '| a    | bbbb    | c'
    👁️ '| aasd | aasdfaa | aad'

    📴 '|bar; baz'

    ⌨️ G
    ⌨️ 4k
    ⌨️ ,t

    👁️ '| Foo  | bar     | baz' 1000
    👁️ '| -    | -       | -'
    👁️ '| A    | bbbb    | c'
    👁️ '| Aasd | aasdfaa | aad'

    👁️ '; can be used for |' # not replaced, clear
    📷                        # screenshot
    vi_quit
}

# -------------------------------------------------------------------- Man
function test-man-pages { # we have some tweaks for :Man
    #$HOME/pds/bin/vi -c '! echo $VIMRUNTIME>/tmp/vimrt' -c 'q'
    ls -lta "$HOME/pds/bin/nvimfs/usr/share/nvim/runtime/ftplugin/man.vim"
    TSC "alias man='pds vman'"
    TSC man
    ✔️ shows 'What manual page do you want'
    TSK "man ls"
    ✔️ max 1500 shows "SYNOPSIS"
    vi_quit
}

# -------------------------------------------------------------------- Python
function test-diag-show-toggle { # diag off at start up. <spc>lx enables
    # have to wait hover timeout vim.o.update
    function diag { shows "Undefined"; }
    M1='
    xlass foo(noexist):
        stuff=42
    '
    open 'p1.py' "$M1"  # do NOT wait for 'pyslp'. With our width this won't be shown!!
    :eye
    ✔️ shows stuff
    ⌨️ G
    🚫 diag
    ⌨️ g g 0 r c
    ✔️ shows class
    # Every 20to 30 times or so in a continuous test test loop this popup failed :-(, the hover did not come
    # So we go down up at failure. Then it seems safely there always:
    (✔️ max 1000 diag) || {
        ⌨️ j k
        ✔️ max 1000 diag
    }
    ⌨️ G
    🚫 max 1000 diag
    ⌨️ ' ' l x # switch it on
    ✔️ max 1000 diag
    vi_quit
}

function test-lsp-blue { # line-len respected for blue, not pylsp
    echo -e '[tool.blue]\nline-length = 90\n' >"$d_vi_file/pyproject.toml"
    M1='
    ["aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", "bbbbbbbbbbbbbbbbbbbbb"]
    ["AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", "BBBBBBBBBBBBBBBBBBBBBB"]'
    open 'p1.py' "$M1" 
    ⌨️ ,w                       # write format
    👁️ '\aaa'\'', '\''bbb' 1000 # was not wrapped, fits to 90
    📴 '   '\''aaa' 1000         # was not wrapped, we don't see this
    📴 '\AAA'\'', '\''BBB' 1000  # was wrapped, one char too much, don't see this
    👁️ '   '\''BBB' 1000        # but we see this
    vi_quit
}

function test-store-last-position { # will at reopen last position be stored AND gd works
    # spotted that first gd after cursor restore with g'" was screwed, except when done in lua
    # => we verify it working here. We test where we are by checking the <row>:<col> display in vim
    M1='
    def foo(): pass
    baz = 1
    baz = 2
    test = foo
    # end
    '
    open 'p1.py' "$M1" 
    ⌨️ 'gg' 0
    👁️ '1:1' 500
    ⌨️ '/foo' Enter
    👁️ '1:5' 500
    ⌨️ 'n'
    👁️ '4:8' 500
    ⌨️ ',d'              # our done (write quit) shortcut
    touch p1.py          # just any command where we can safely test success
    open 'p1.py' "$M1"  # does not matter that rewritten
    ⌨️ 'l'
    👁️ '4:9' 500 # yes, we are at second test = foo, second o
    ⌨️ 'gd' 500
    👁️ '1:5' 500 # gd worked
    #read -r foo
    T send-keys Escape # required here, sometimes in strange mode still
    vi_quit
}

# -------------------------------------------------------------------- pds function
function test-pds-plugs-list-and-fzf { # pds t function some tools, based on fzf et al
    TSK 'pds t plugins-list'
    until C | grep -q "opt/"; do
        sleep 0.1
        C | grep -q "start/" && break
    done
    TSK "'mason-null-ls.nvim"
    sleep 0.05 # time for fzf
    📷
    T send-keys Enter
    TSC pwd
    ✔️ shows "$HOME/.local/share/nvim/site/pack/packer/opt/mason-null-ls.nvim"
}

return 2>/dev/null || test_in_tmux "$@"
