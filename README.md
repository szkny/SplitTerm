# SplitTerm

## About

SplitTerm is a plugin to easily use for neovim terminal mode.  

## Install

if you use [vim-plug](https://github.com/junegunn/vim-plug), add to your `init.vim`

```vim
Plug 'szkny/SplitTerm'
```

then, open nvim
```vim
:PlugInstall
```

## Commands

| Usage | explain |
|:---|:---|
|  :SplitTerm **COMMANDS**  |  Begin terminal & execute following commands (ex. **python**, default=bash)  |
|  :SplitTermJobSend **COMMANDS** |  Send job to Terminal (ex. **echo**)  |
|  :SplitTermClose  |  End Terminal  |

## Mapping (recommended)

add to your `init.vim`

```vimscript
nnoremap  t  :SplitTerm<CR>i
```

## Demo

![](https://github.com/szkny/SplitTerm/wiki/images/demo1.gif)
![](https://github.com/szkny/SplitTerm/wiki/images/demo2_python_rand.gif)
![](https://github.com/szkny/SplitTerm/wiki/images/demo3_python_3dplot.gif)
