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

command! -count -complete=shellcmd -nargs=*
            \ SplitTerm call splitterm#open_width(<count>, <f-args>)
command! -nargs=* SplitTermExec call splitterm#jobsend(<f-args>)
command! SplitTermClose call splitterm#close()


fun! splitterm#open_width(width, ...)
    " SplitTermコマンド用の関数
    " [N]にウィンドウ幅を指定可能
    "      :[N]SplitTerm[N] [Command] で任意のシェルコマンドを実行
    let s:term = {}
    let l:current_dir = expand('%:p:h')
    " 分割ウィンドウの生成
    if a:width
        " 数値指定があれば水平分割
        let l:width = a:width ? a:width : l:width
        let l:cmd = a:width.'new'
    else
        " または自動判断し水平か垂直に分割
        let l:width = s:vsplitwidth()
        if l:width
            let l:split = 'vnew'
            let l:cmd = l:width.l:split
        else
            let l:split = 'new'
            let l:height = s:splitheight()
            let l:cmd = l:height ? l:height.l:split : l:split
        endif
    endif
    silent exe l:cmd
    silent exe 'lcd ' . l:current_dir
    silent exe 'terminal '.join(a:000)
    " ターミナルのセットアップ
    call s:termconfig(a:000)
    return s:term
endf


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
        let l:cmd = l:width.l:split
    else
        let l:split = 'new'
        let l:height = s:splitheight()
        let l:cmd = l:height ? l:height.l:split : l:split
    endif
    silent exe l:cmd
    silent exe 'lcd ' . l:current_dir
    silent exe 'terminal '.join(a:000)
    " ターミナルのセットアップ
    call s:termconfig(a:000)
    return s:term
endf


fun! s:termconfig(cmd) abort
    " バッファ名を変更
    if len(a:cmd) == 0
        silent call s:setnewbufname('bash')
    elseif len(a:cmd) > 0
        silent call s:setnewbufname(a:cmd[0])
    endif
    " バッファローカルの設定項目
    setlocal nonumber
    setlocal buftype=terminal
    setlocal filetype=terminal
    setlocal bufhidden=wipe
    setlocal nobuflisted
    setlocal nocursorline
    setlocal nocursorcolumn
    setlocal noswapfile
    setlocal nomodifiable
    setlocal nolist
    setlocal nospell
    setlocal lazyredraw
    " ターミナル情報の保持
    let s:term.jobid = b:terminal_job_id
    let s:term.console_winid = win_getid()
endf


fun! s:setnewbufname(name) abort
    " 新規バッファのバッファ名(例: '1:bash')を設定する関数
    let l:num = 1
    let l:name = split(a:name,' ')[0]
    while bufexists(l:num.':'.l:name)
        let l:num += 1
    endwhile
    exe 'file '.l:num.':'.l:name
endf


fun! s:splitheight() abort
    " 新規分割ウィンドウの高さを決める関数
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


fun! splitterm#close(...)
    " SplitTermを終了する関数
    if a:0 == 0
        if splitterm#exist()
            if win_gotoid(s:term.console_winid)
                let s:term = {}
                quit
            endif
        endif
    else
        if splitterm#exist(a:1)
            if win_gotoid(a:1.console_winid)
                quit
            endif
        endif
    endif
endf


fun! splitterm#exist(...) abort
    " 分割ウィンドウの存在チェック
    " or 指定したコンソールの存在チェック
    "   引数にはsplitterm#getinfo()と同じ型の辞書を渡す
    if a:0 == 0
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
    else
        if type(a:1) != 4
            " 辞書型以外は受け付けない
            return
        endif
        let l:current_winid = win_getid()
        if has_key(a:1, 'jobid')
          \&& has_key(a:1, 'console_winid')
          \&& win_gotoid(a:1.console_winid)
            call win_gotoid(l:current_winid)
            return 1
        else
            return 0
        endif
    endif
endf


fun! splitterm#jobsend(...) abort
    " 一番最近開いたコンソールに引数で与えたコマンドを送る
    if splitterm#exist()
        try
            call jobsend(s:term.jobid, "\<C-u>".join(a:000)."\<CR>")
        catch
        endtry
    endif
endf


fun! splitterm#jobsend_id(info, ...) abort
    " 指定したコンソールに引数で与えたコマンドを送る
    "   引数のinfoにはsplitterm#getinfo()と同じ型の辞書を渡す
    if splitterm#exist(a:info)
        try
            call jobsend(a:info.jobid, "\<C-u>".join(a:000)."\<CR>")
        catch
        endtry
    endif
endf


fun! splitterm#getinfo() abort
    if exists('s:term')
        return s:term
    else
        return {}
    endif
endf
