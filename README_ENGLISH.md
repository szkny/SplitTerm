# SplitTerm

## About

SplitTerm is a plugin to easily use for neovim terminal mode.  

## Install

if you use [vim-plug](https://github.com/junegunn/vim-plug), add the following to your `init.vim`  

```vim
Plug 'szkny/SplitTerm'
```

then, open nvim and execute the following command  

```vim
:PlugInstall
```

## Mapping (recommended)

add to your `init.vim`  

```vimscript
nnoremap  t  :SplitTerm<CR>i
```

## Commands

| Usage | explain |
|:---|:---|
| :SplitTerm *COMMANDS*        | Start terminal & execute following commands (ex. **python**, default=bash)  |
| :SplitTermJobSend *COMMANDS* | Send job to Terminal |
| :SplitTermClose              | Close latest split terminal window |

## Functions

| Name | explain |
|:---|:---|
| splitterm#open(['*COMMAND*'])                      | Open split console (run if *COMMAND* is given) |
| splitterm#close([*terminal_info*])                 | Close latest split terminal window |
| splitterm#exist([*terminal_info*])                 | Check the existence of the last opened terminal window |
| splitterm#jobsend('*COMMAND*')                     | Send job to the last opened window |
| splitterm#jobsend_id(*terminal_info*, '*COMMAND*') | Send job to the specified terminal window |
| splitterm#getinfo()                                | Get *terminal_info* |

#### <u>Sample</u>

```vimscript
fun! s:python_run() abort
    if &filetype ==# 'python'
        if s:python_exist()
            let l:script_name = expand('%:p')
            let l:script_dir = expand('%:p:h')
            if has_key(s:ipython, 'script_name')
                \&& s:ipython.script_name !=# l:script_name
                call splitterm#jobsend_id(s:ipython.info, '%reset')
                call splitterm#jobsend_id(s:ipython.info, 'y')
            endif
            if has_key(s:ipython, 'script_dir')
                \ && s:ipython.script_dir !=# l:script_dir
                call splitterm#jobsend_id(s:ipython.info, '%cd '.l:script_dir)
            endif
            let s:ipython.script_name = l:script_name
            let s:ipython.script_dir = l:script_dir
            call splitterm#jobsend_id(s:ipython.info, '%run '.s:ipython.script_name)
        else
            let l:command = 'ipython'
            let l:filename = ' ' . expand('%')
            if findfile('Pipfile', expand('%:p')) !=# ''
                \ && findfile('Pipfile.lock', expand('%:p')) !=# ''
                let l:command = 'pipenv run ipython'
            endif
            let s:ipython = {}
            let s:ipython.script_name = expand('%:p')
            let s:ipython.script_dir = expand('%:p:h')
            let l:script_winid = win_getid()
            call splitterm#open(l:command, '--no-confirm-exit --colors=Linux')
            let s:ipython.info = splitterm#getinfo()
            silent exe 'normal G'
            call win_gotoid(l:script_winid)
        endif
    endif
endf
command! Python call s:python_run()


fun! s:python_exist() abort
    if exists('s:ipython')
        \&& has_key(s:ipython, 'script_name')
        \&& has_key(s:ipython, 'script_dir')
        \&& has_key(s:ipython, 'info')
        if splitterm#exist(s:ipython.info)
            return 1
        endif
    endif
    return 0
endf
```

## Demo

![](https://github.com/szkny/SplitTerm/wiki/images/demo1.gif)
![](https://github.com/szkny/SplitTerm/wiki/images/demo2.gif)
