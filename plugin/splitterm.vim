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

let g:splitterm_auto_close_window = get(g:, "splitterm_auto_close_window", 1)

if g:splitterm_auto_close_window
    aug SplitTermTabClose
        au!
        au TermClose * exe 'bdelete! '.expand('<abuf>') | redraw!
    aug END
endif


fun! splitterm#open_width(width, ...)
    " SplitTermコマンド用の関数
    " [N]にウィンドウ幅を指定可能
    "      :[N]SplitTerm[N] [Command] で任意のシェルコマンドを実行
    if !exists('s:term')
        let s:term = {}
    endif
    " let l:current_dir = expand('%:p:h')
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
    if a:width
        setlocal noequalalways
    endif
    " silent exe 'lcd ' . l:current_dir
    silent exe 'terminal '.join(a:000)
    " ターミナルのセットアップ
    call s:termconfig(a:000)
    return s:term[tabpagenr()][-1]
endf


fun! splitterm#open(...) abort
    " 分割ウィンドウでターミナルモードを開始する関数
    "      縦分割か横分割かは現在のファイル内の文字数と
    "      ウィンドウサイズとの兼ね合いで決まる
    "      :SplitTerm [Command] で任意のシェルコマンドを実行
    if !exists('s:term')
        let s:term = {}
    endif
    " let l:current_dir = expand('%:p:h')
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
    " silent exe 'lcd ' . l:current_dir
    silent exe 'terminal '.join(a:000)
    " ターミナルのセットアップ
    call s:termconfig(a:000)
    return s:term[tabpagenr()][-1]
endf


fun! s:termconfig(cmd) abort
    " バッファ名を変更
    if len(a:cmd) == 0
        silent call s:setnewbufname('SplitTerm')
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
    setlocal nolazyredraw
    " ターミナル情報の保持
    let l:tnr = tabpagenr()
    if !has_key(s:term, l:tnr)
        " 現在のタブページのSplitTermオブジェクトが存在しなければ新たに作成
        let s:term[l:tnr] = []
    endif
    " 追加するオブジェクトの中身
    let l:term_new = {}
    let l:term_new.tabnr = l:tnr
    let l:term_new.jobid = b:terminal_job_id
    let l:term_new.console_winid = win_getid()
    " 現在のタブページのSplitTermオブジェクトの末尾に追加
    let s:term[l:tnr] += [l:term_new]
endf


fun! s:setnewbufname(name) abort
    " 新規バッファのバッファ名(例: '1:SplitTerm')を設定する関数
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
            let l:tnr = tabpagenr()
            if win_gotoid(s:term[l:tnr][-1].console_winid)
                call remove(s:term[l:tnr], -1)
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
    if !exists('s:term')
        " s:term(SplitTermの実態)が無ければFalseを返す
        let s:term = {}
        return 0
    endif
    let l:tnr = tabpagenr()
    if !has_key(s:term, l:tnr)
        " 現在のタブページのSplitTermオブジェクトが存在しなければFalseを返す
        return 0
    elseif !len(s:term[l:tnr])
        " 現在のタブページのSplitTermオブジェクトの中身が無ければFalseを返す
        return 0
    endif
    if tabpagenr('$') > 1
        " タブページを開いている場合
        "   現在のタブ内のウィンドウIDを取得
        let l:winid_list =
                    \ map(range(1, tabpagewinnr(l:tnr, '$')), 'win_getid(v:val, l:tnr)')
        let l:exist_in_this_tab =
                    \ match(l:winid_list, s:term[l:tnr][-1].console_winid)==-1? 0:1
        "   最新のSplitTermオブジェクトと一致するウィンドウIDがあればTrueを保持
        "   以下の処理で実際に移動できることを確認し、存在確認とする
    else
        " タブページが１つ(=タブページを使っていない)場合
        let l:exist_in_this_tab = 1
    endif
    let l:current_winid = win_getid()
    if a:0 == 0
        " 関数の引数がなかった場合
        if has_key(s:term[l:tnr][-1], 'jobid')
          \&& has_key(s:term[l:tnr][-1], 'console_winid')
            \&& win_gotoid(s:term[l:tnr][-1].console_winid)
            call win_gotoid(l:current_winid)
            " 保持しているウィンドウIDに移動できればTrueを返す
            return 1 && l:exist_in_this_tab
        else
            " 移動できなかった場合、オブジェクトを削除しFalseを返す
            call remove(s:term[l:tnr], -1)
            return 0
        endif
    else
        " 引数で指定する場合は、コンソール作成時にsplitterm#open()
        " またはsplitterm#open_width()が返す辞書オブジェクトを渡す
        " 'jobid'、'console_winid'を持っている必要がある
        if type(a:1) != 4
            " 辞書型以外は受け付けない
            echoerr
        endif
        if has_key(a:1, 'jobid')
          \&& has_key(a:1, 'console_winid')
          \&& win_gotoid(a:1.console_winid)
            call win_gotoid(l:current_winid)
            return 1 && l:exist_in_this_tab
        else
            return 0
        endif
    endif
endf


fun! splitterm#jobsend(...) abort
    " 一番最近開いたコンソールに引数で与えたコマンドを送る
    if splitterm#exist()
        try
            call jobsend(s:term[tabpagenr()][-1].jobid, "\<C-e>\<C-u>".join(a:000)."\<CR>")
        catch
        endtry
    endif
endf


fun! splitterm#jobsend_id(info, ...) abort
    " 指定したコンソールに引数で与えたコマンドを送る
    "   引数のinfoにはsplitterm#getinfo()と同じ型の辞書を渡す
    if splitterm#exist(a:info)
        try
            call jobsend(a:info.jobid, "\<C-e>\<C-u>".join(a:000)."\<CR>")
        catch
        endtry
    endif
endf


fun! splitterm#jobsend_freestyle(...) abort
    " 一番最近開いたコンソールに引数で与えたコマンドを送る
    if splitterm#exist()
        try
            call jobsend(s:term[tabpagenr()][-1].jobid, join(a:000))
        catch
        endtry
    endif
endf


fun! splitterm#jobsend_id_freestyle(info, ...) abort
    " 指定したコンソールに引数で与えたコマンドを送る
    "   引数のinfoにはsplitterm#getinfo()と同じ型の辞書を渡す
    if splitterm#exist(a:info)
        try
            call jobsend(a:info.jobid, join(a:000))
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
