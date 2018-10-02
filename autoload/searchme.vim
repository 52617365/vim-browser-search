" @Author: VoldikSS
" @Date: 2018-08-22 17:51:06
" @Last Modified by: VoldikSS
" @Last Modified time: 2018-10-02

function! s:Search(keyword, search_engine)
    if has_key(g:query_map, a:search_engine)
        let l:query_url = g:query_map[a:search_engine]
    else
        echoerr "Unknow search engine."
        return
    endif
    let l:url = substitute(l:query_url, '{query}', a:keyword, 'g')
    let l:url = substitute(l:url, ' ', '%20', 'g')

    " Windows(including mingw)
    if has('win32') || has('win64') || has('win32unix')
        let cmd = 'start rundll32 url.dll,FileProtocolHandler ' . l:url
    elseif has('mac') || has('macunix') || has('gui_macvim') || system('uname') =~? '^darwin'
        let cmd = 'open ' . l:url
    elseif executable('xdg-open')
        let cmd = 'xdg-open ' . l:url
    else
        echoerr "Browser not found."
    endif

    " Async
    if exists('*jobstart')
        call jobstart(cmd)
    elseif exists('*job_start')
        call job_start(cmd)
    else
        call system(cmd)
    endif
endfunction

function! searchme#SearchIn(...)
    " Users can decide which search engine to use
    if a:0 == 1
        let l:text = a:1
        let l:pos = match(l:text,' ')
        "Search engine not specified, use the default
        if l:pos < 0
            echom "Use default engine."
            let l:search_engine = g:search_engine
            let l:keyword = l:text
        else
            let l:search_engine = l:text[: l:pos-1]
            let l:keyword = l:text[l:pos+1 :]
        endif
    else
        let l:keyword = a:1
        let l:search_engine = a:2
    endif
    call <SID>Search(l:keyword, l:search_engine)
endfunction

function! searchme#SearchCurrentText(...)
    if a:0 == 0
        let l:search_engine = tolower(g:search_engine)
    else
        let l:search_engine = tolower(a:1)
    endif
    let l:keyword = expand("<cword>")
    call <SID>Search(l:keyword, l:search_engine)
endfunction

function! searchme#SearchVisualText(...)
    if a:0 == 0
        let l:search_engine = tolower(g:search_engine)
    else
        let l:search_engine = tolower(a:1)
    endif
    try
        let l:save_tmp = @a
        normal! gv"ay
        let l:select_text=@a
    finally
        let @a = l:save_tmp
    endtry
    call <SID>Search(l:select_text, l:search_engine)
endfunction

function! searchme#Complete(arg_lead, cmd_line, cursor_pos)
    let l:cmd_line_before_cursor = a:cmd_line[:a:cursor_pos - 1]
    let l:args = split(l:cmd_line_before_cursor, '\v\\@<!(\\\\)*\zs\s+', 1)
    call remove(l:args, 0) " Remove the command's name
    if len(l:args) == 1 " At search engine's position
        let l:candidates = keys(g:query_map)
        let l:prefix = l:args[0]
        if !empty(l:prefix) " If l:prefix is empty we want to return all options
            let l:candidates = filter(keys(g:query_map), 'v:val[:len(l:prefix) - 1] == l:prefix')
        endif
        return sort(l:candidates)
    endif
endfunction
