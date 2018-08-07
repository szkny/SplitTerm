"=============================================================================
" FILE: splitterm.vim
" AUTHOR:  Sohei Suzuki <suzuki.s1008 at gmail.com>
" License: MIT license
"=============================================================================
scriptencoding utf-8


if !has('nvim')
    echomsg 'SplitTerm requires Neovim.'
    finish
endif


command! -complete=file -nargs=* SplitTerm call splitterm#open(<f-args>)
command! SplitTermClose call splitterm#close()


fun! splitterm#open(...) abort
    " 分割ウィンドウでターミナルモードを開始する関数
    "      縦分割か横分割かは現在のファイル内の文字数と
    "      ウィンドウサイズとの兼ね合いで決まる
    "      :SplitTerm [Command] で任意のシェルコマンドを実行
    let s:term = {}
    let l:current_dir = expand('%:p:h')
    " 分割ウィンドウの生成
    let l:split = ''
    let l:width = s:vsplitwidth()
    if l:width
        let l:split = 'vnew'
        let l:cmd1 = l:width.l:split
    else
        let l:split = 'new'
        let l:height = s:splitheight()
        let l:cmd1 = l:height ? l:height.l:split : l:split
    endif
    silent exe l:cmd1
    silent exe 'lcd ' . l:current_dir
    " terminalコマンドの実行
    let l:cmd2 = 'terminal'
    if a:0 > 0
        for l:i in a:000
            let l:cmd2 .= ' '.l:i
        endfor
    endif
    silent exe l:cmd2
    " バッファ名を変更
    if a:0 == 0
        silent call s:setnewbufname('bash')
    elseif a:0 > 0
        silent call s:setnewbufname(a:1)
    endif
    " バッファローカルの設定項目
    setlocal nonumber
    setlocal buftype=terminal
    setlocal filetype=terminal
    setlocal bufhidden=wipe
    setlocal nobuflisted
    setlocal nocursorline
    setlocal nocursorcolumn
    setlocal winfixwidth
    setlocal noswapfile
    setlocal nomodifiable
    setlocal nolist
    setlocal nospell
    setlocal lazyredraw
    " ターミナル情報の保持
    let s:term.jobid = b:terminal_job_id
    let s:term.console_winid = win_getid()
    silent exe 'normal G'
    return l:split
endf


fun! s:setnewbufname(name) abort
    " 新規バッファのバッファ名(例: '1:bash')を設定する関数
    "      NewTermとSplitTermで利用している
    let l:num = 1
    let l:name = split(a:name,' ')[0]
    while bufexists(l:num.':'.l:name)
        let l:num += 1
    endwhile
    exe 'file '.l:num.':'.l:name
endf


fun! s:splitheight() abort
    " 新規分割ウィンドウの高さを決める関数
    "      SplitTermで利用している
    let l:min_winheight = 10
    let l:max_winheight = winheight(0)/2
    " count max line length
    let l:height = winheight(0)-line('$')
    let l:height = l:height>l:min_winheight ? l:height : 0
    let l:height = l:height>l:max_winheight ? l:max_winheight : l:height
    return l:height
endf


fun! s:vsplitwidth() abort
    " 新規分割ウィンドウの幅を決める関数
    "      SplitTermで利用している
    let l:min_winwidth = 60
    let l:max_winwidth = winwidth(0)/2
    " count max line length
    let l:all_lines = getline('w0', 'w$')
    let l:max_line_len = 0
    for l:line in l:all_lines
        if len(l:line) > l:max_line_len
            let l:max_line_len = strwidth(l:line)
        endif
    endfor
    let l:max_line_len += 1
    " count line number or ale column width
    let l:linenumwidth = 0
    if &number
        " add line number column width
        let l:linenumwidth = 4
        let l:digits = 0
        let l:linenum = line('$')
        while l:linenum
            let l:digits += 1
            let l:linenum = l:linenum/10
        endwhile
        if l:digits > 3
            let l:linenumwidth += l:digits - 3
        endif
    endif
    " add ale sign line column width
    if exists('*airline#extensions#ale#get_error')
        \&& (airline#extensions#ale#get_error()!=#'' || airline#extensions#ale#get_warning()!=#'')
            \|| exists('*GitGutterGetHunkSummary') && GitGutterGetHunkSummary() != [0, 0, 0]
        let l:linenumwidth += 2
    endif
    let l:width = winwidth(0)-l:max_line_len-l:linenumwidth
    let l:width = l:width>l:min_winwidth ? l:width : 0
    let l:width = l:width>l:max_winwidth ? l:max_winwidth : l:width
    return l:width
endf


fun! splitterm#close()
    " SplitTermを終了する関数
    if splitterm#exist()
        if win_gotoid(s:term.console_winid)
            quit
        endif
    endif
endf


fun! splitterm#exist() abort
    " 分割ウィンドウの存在チェック
    if !exists('s:term')
        let s:term = {}
        return 0
    endif
    let l:current_winid = win_getid()
    if has_key(s:term, 'jobid')
      \&& has_key(s:term, 'console_winid')
        \&& win_gotoid(s:term.console_winid)
        call win_gotoid(l:current_winid)
        return 1
    else
        let s:term = {}
        return 0
    endif
endf


fun! splitterm#jobsend(...) abort
    " 開いているコンソールに引数で与えたコマンドを送る
    if splitterm#exist()
        let l:command = ''
        if a:0 > 0
            let l:command = a:1
            for l:arg in a:000[1:]
                let l:command .= ' ' . l:arg
            endfor
        endif
        try
            call jobsend(s:term.jobid, "\<C-u>".l:command."\<CR>")
        catch
        endtry
    endif
endf
