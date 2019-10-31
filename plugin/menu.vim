" Version:      1.0

if exists('g:loaded_mymenu1') || &compatible
  finish
else
  let g:loaded_mymenu1 = 'yes'
endif


" Restore cursor when enter buffer {{{2
function! ResCur()
    let save_cursor = getcurpos()

    let text = getline('.')
    normal! be
    let end_pos = getcurpos()
    call search('\s\|[,;\(\)]','b')
    call search('\S')
    let start_pos = getcurpos()

    call setpos('.', save_cursor)
endfunction

function! ResCur()
    if line("'\"") <= line("$")
        normal! g`"
        return 1
    endif
endfunction

augroup resCur
    autocmd!
    autocmd BufWinEnter * silent! call ResCur()
augroup END
"}}}


" Autocmd {{{2

    function! AdjustWindowHeight(minheight, maxheight)
        let l = 1
        let n_lines = 0
        let w_width = winwidth(0)
        while l <= line('$')
            " number to float for division
            let l_len = strlen(getline(l)) + 0.0
            let line_width = l_len/w_width
            let n_lines += float2nr(ceil(line_width))
            let l += 1
        endw
        let exp_height = max([min([n_lines, a:maxheight]), a:minheight])
        if (abs(winheight(0) - exp_height)) > 2
            exe max([min([n_lines, a:maxheight]), a:minheight]) . "wincmd _"
        endif
    endfunction

    function! Indent(linenum, islog)
        if a:islog
            let cur_str = getline(a:linenum)
            if cur_str =~? '^T@'
                " Non-greed: replace '.*' with '.\{-}'
                let cur_str2 = substitute(cur_str, '^T@.\{-}-  ', '  ', '')
                let off_set = match(cur_str, cur_str2)
                let indent = match(cur_str2, '\S')
                return off_set + indent
            endif
        endif
        return indent(a:linenum)
    endfunction

    " Jump to the next or previous line that has the same level or a lower
    " level of indentation than the current line.
    "
    " exclusive (bool): true: Motion is exclusive
    "                   false: Motion is inclusive
    " fwd (bool): true: Go to next line
    "             false: Go to previous line
    " lowerlevel (bool): true: Go to line with lower indentation level
    "                    false: Go to line with the same indentation level
    " skipblanks (bool): true: Skip blank lines
    "                    false: Don't skip blank lines
    function! NextIndent(exclusive, fwd, lowerlevel, skipblanks)
        let line = line('.')
        let column = col('.')
        let lastline = line('$')

        " check logfile
        let is_log = 0
        let cur_str = getline('.')
        if cur_str =~? '^T@'
            let is_log = 1
        endif

        " indent by cursor position (only by-space), or by builtin indent (by-space/tab)
        if is_log
            let indent = column - 1
        else
            let indent = Indent(line, is_log)
        endif

        let stepvalue = a:fwd ? 1 : -1
        while (line > 0 && line <= lastline)
            let line = line + stepvalue

            " if logfile, skip non-log lines
            if is_log == 1
                let cur_str = getline(line)
                if cur_str !~? '^T@'
                    continue
                endif
            endif

            if ( ! a:lowerlevel && Indent(line, is_log) == indent ||
                        \ a:lowerlevel && Indent(line, is_log) < indent)
                if (! a:skipblanks || strlen(getline(line)) > 0)
                    if (a:exclusive)
                        let line = line - stepvalue
                    endif
                    "exe line
                    " column different when tabs
                    "   exe "normal " column . "|"
                    "exe "normal " column . "l"
                    call cursor(line, column)
                    return
                endif
            endif
        endwhile
    endfunction

    " Moving back and forth between lines of same or lower indentation.
    nnoremap <silent> <a-p> :call NextIndent(0, 0, 0, 1)<CR>
    nnoremap <silent> <a-n> :call NextIndent(0, 1, 0, 1)<CR>
    nnoremap <silent> <a-P> :call NextIndent(0, 0, 1, 1)<CR>
    nnoremap <silent> <a-N> :call NextIndent(0, 1, 1, 1)<CR>
    vnoremap <silent> <a-p> <Esc>:call NextIndent(0, 0, 0, 1)<CR>m'gv''
    vnoremap <silent> <a-n> <Esc>:call NextIndent(0, 1, 0, 1)<CR>m'gv''
    vnoremap <silent> <a-P> <Esc>:call NextIndent(0, 0, 1, 1)<CR>m'gv''
    vnoremap <silent> <a-N> <Esc>:call NextIndent(0, 1, 1, 1)<CR>m'gv''
    onoremap <silent> <a-p> :call NextIndent(0, 0, 0, 1)<CR>
    onoremap <silent> <a-n> :call NextIndent(0, 1, 0, 1)<CR>
    onoremap <silent> <a-P> :call NextIndent(1, 0, 1, 1)<CR>
    onoremap <silent> <a-N> :call NextIndent(1, 1, 1, 1)<CR>
    "nnoremap <silent> [l :call NextIndent(0, 0, 0, 1)<CR>
    "nnoremap <silent> ]l :call NextIndent(0, 1, 0, 1)<CR>
    "nnoremap <silent> [L :call NextIndent(0, 0, 1, 1)<CR>
    "nnoremap <silent> ]L :call NextIndent(0, 1, 1, 1)<CR>
    "vnoremap <silent> [l <Esc>:call NextIndent(0, 0, 0, 1)<CR>m'gv''
    "vnoremap <silent> ]l <Esc>:call NextIndent(0, 1, 0, 1)<CR>m'gv''
    "vnoremap <silent> [L <Esc>:call NextIndent(0, 0, 1, 1)<CR>m'gv''
    "vnoremap <silent> ]L <Esc>:call NextIndent(0, 1, 1, 1)<CR>m'gv''
    "onoremap <silent> [l :call NextIndent(0, 0, 0, 1)<CR>
    "onoremap <silent> ]l :call NextIndent(0, 1, 0, 1)<CR>
    "onoremap <silent> [L :call NextIndent(1, 0, 1, 1)<CR>
    "onoremap <silent> ]L :call NextIndent(1, 1, 1, 1)<CR>

    function SelectIndent()
        let cur_line = line(".")
        let cur_ind = indent(cur_line)
        let line = cur_line
        while indent(line - 1) >= cur_ind
            let line = line - 1
        endw
        " Select above line
        let line = line - 1
        exe "normal " . line . "G"
        exe "normal V"
        let line = cur_line
        while indent(line + 1) >= cur_ind
            let line = line + 1
        endw
        " Select below line
        let line = line + 1
        exe "normal " . line . "G"
    endfunction
    nnoremap vip :call SelectIndent()<CR>

    " Maximizes the current window if it is not the quickfix window.
    function! SetIndentTabForCfiletype()
        " auto into terminal-mode
        if &buftype == 'terminal'
            startinsert
            return
        elseif &buftype == 'quickfix'
            call AdjustWindowHeight(2, 10)
            return
        endif

        let my_ft = &filetype
        if (my_ft == "c" || my_ft == "cpp" || my_ft == "diff" )
            execute ':C8'

            " If logfile reset NonText bright, this will override it.
            "" The 'NonText' highlighting will be used for 'eol', 'extends' and 'precedes'
            "" The 'SpecialKey' for 'nbsp', 'tab' and 'trail'.
            "hi NonText          ctermfg=238
            "hi SpecialKey       ctermfg=238
        elseif (my_ft == 'vimwiki')
            execute ':C0'
        endif
    endfunction

    function! OnEventBufEnter()
        " auto into terminal-mode
        if &buftype == 'terminal'
            startinsert
        else
            stopinsert
        endif

        "call SetIndentTabForCfiletype()
    endfunction

    "" Easier and better than plugin 'autotag'
    "let s:retag_time = localtime()
    "function! RetagFile()
    "    if   (!filereadable(g:autotagTagsFile))
    "       \ || (localtime() - s:retag_time) < s:autotag_inter
    "        return
    "    endif
    "    let cdir = getcwd()
    "    let file = expand('%:p')
    "    let ext = expand('%:e')
    "    if g:asyncrun_status =~ 'running' || empty(ext) || file !~ cdir. '/'
    "        return
    "    elseif index(g:autotagExcSuff, ext) < 0
    "        execute ":AsyncRun tagme ". expand('%:p')
    "    endif
    "endfunction

    function! ToggleCalendar()
        execute ":Calendar"
        if exists("g:calendar_open")
            if g:calendar_open == 1
                execute "q"
                unlet g:calendar_open
            else
                g:calendar_open = 1
            end
        else
            let g:calendar_open = 1
        end
    endfunction


    augroup fieltype_automap
        " Voom/VOom:
        " <Enter>             selects node the cursor is on and then cycles between Tree and Body.
        " <Tab>               cycles between Tree and Body windows without selecting node.
        " <C-Up>, <C-Down>    move node or a range of sibling nodes Up/Down.
        " <C-Left>, <C-Right> move nodes Left/Right (promote/demote).
        "
        autocmd!

        "autocmd VimLeavePre * cclose | lclose
        autocmd InsertEnter,InsertLeave * set cul!
        " Sometime crack the tag file
        "autocmd BufWritePost,FileWritePost * call RetagFile()

        " current position in jumplist
        autocmd CursorHold * normal! m'

        autocmd BufEnter * call OnEventBufEnter()

        " Always show sign column
        autocmd BufEnter * sign define dummy
        autocmd BufEnter * execute 'sign place 9999 line=1 name=dummy buffer=' . bufnr('')

        autocmd BufRead *.rs :setlocal tags=./rusty-tags.vi;/
        autocmd BufNewFile,BufRead *.c.rej,*.c.orig,h.rej,*.h.orig,patch.*,*.diff,*.patch set ft=diff
        autocmd BufNewFile,BufRead *.c,*.c,*.h,*.cpp,*.C,*.CXX,*.CPP set ft=c
        autocmd BufNewFile,BufRead *.wiki set syntax=markdown
        "autocmd BufNewFile,BufRead *.wiki set ft=markdown
        autocmd BufWritePre [\,:;'"\]\)\}]* throw 'Forbidden file name: ' . expand('<afile>')

        "autocmd filetype vimwiki  nnoremap <buffer> <a-o> :VoomToggle vimwiki<CR>
        autocmd filetype vimwiki  nnoremap <buffer> <a-'> :VoomToggle markdown<CR>
        "autocmd filetype vimwiki  nnoremap <a-n> :VimwikiMakeDiaryNote<CR>
        "autocmd filetype vimwiki  nnoremap <a-i> :VimwikiDiaryGenerateLinks<CR>
        "autocmd filetype vimwiki  nnoremap <a-c> :call ToggleCalendar()<CR>

        autocmd filetype markdown nnoremap <buffer> <a-'> :VoomToggle markdown<CR>
        autocmd filetype python   nnoremap <buffer> <a-'> :VoomToggle python<CR>

        autocmd filetype qf call AdjustWindowHeight(2, 10)
        autocmd filetype c,cpp,diff C8
        autocmd filetype zsh,bash C2
        autocmd filetype vim,markdown C08
        autocmd filetype vimwiki,txt C0

        "autocmd filetype log nnoremap <buffer> <leader>la :call log#filter(expand('%'), 'all')<CR>
        "autocmd filetype log nnoremap <buffer> <leader>le :call log#filter(expand('%'), 'error')<CR>
        "autocmd filetype log nnoremap <buffer> <leader>lf :call log#filter(expand('%'), 'flow')<CR>
        "autocmd filetype log nnoremap <buffer> <leader>lt :call log#filter(expand('%'), 'tcp')<CR>

        " vim-eval
        let g:eval_viml_map_keys = 0
        autocmd FileType vim nnoremap <buffer> <leader>ec <Plug>eval_viml
        autocmd FileType vim vnoremap <buffer> <leader>ec <Plug>eval_viml_region

        " Test
        "nnoremap <silent> <leader>t :<c-u>R <C-R>=printf("python -m doctest -m trace --listfuncs --trackcalls %s \| tee log.test", expand('%:p'))<cr><cr>
        autocmd FileType python nnoremap <buffer> <leader>tt :<c-u>R <C-R>=printf("python -m doctest %s \| tee log.test", expand('%:p'))<cr><cr>
        autocmd FileType python nnoremap <buffer> <leader>tr :<c-u>R <C-R>=printf("python -m trace --trace %s \|  grep %s", expand('%:p'), expand('%'))<cr><cr>

        autocmd FileType c nnoremap <buffer> <leader>tt :<c-u>AsyncRun! tagme<cr>

        autocmd FileType javascript nnoremap <buffer> <leader>ee  :DB mongodb:///test < %
        autocmd FileType javascript vnoremap <buffer> <leader>ee  :'<,'>w! /tmp/vim.js<cr><cr> \| :DB mongodb:///test < /tmp/vim.js<cr><cr>

    augroup END

"}}}

" Quick Jump {{{1
    function! s:JumpI(mode)
        if v:count == 0
            if a:mode
                let ans = input("FuzzySymbol ", utils#GetSelected(''))
                exec 'FuzzySymb '. ans
            else
                FuzzySymb
            endif
        else
        endif
    endfunction
    function! s:JumpO(mode)
        if v:count == 0
            if a:mode
                let ans = input("FuzzyOpen ", utils#GetSelected(''))
                exec 'FuzzyOpen '. ans
            else
                FuzzyOpen
            endif
        else
            exec ':silent! b'. v:count
        endif
    endfunction
    function! s:JumpH(mode)
    endfunction
    function! s:JumpJ(mode)
        if v:count == 0
            if a:mode
                let ans = input("FuzzyFunction ", utils#GetSelected(''))
                exec 'FuzzyFunc '. ans
            else
                FuzzyFunc
            endif
        else
            exec 'silent! '. v:count. 'wincmd w'
        endif
    endfunction
    function! s:JumpK(mode)
        if v:count == 0
        else
            exec 'normal! '. v:count. 'gt'
        endif
    endfunction
    function! s:JumpComma(mode)
        if v:count == 0
            "silent call utils#Declaration()
            call utils#Declaration()
        else
        endif
    endfunction

    " Must install fzy tool(https://github.com/jhawthorn/fzy)
    nnoremap <silent> <leader>i  :<c-u>call <SID>JumpI(0)<cr>
    vnoremap          <leader>i  :<c-u>call <SID>JumpI(1)<cr>
    nnoremap <silent> <leader>o  :<c-u>call <SID>JumpO(0)<cr>
    vnoremap          <leader>o  :<c-u>call <SID>JumpO(1)<cr>
    "nnoremap <silent> <leader>h  :<c-u>call <SID>JumpH(0)<cr>
    "vnoremap          <leader>h  :<c-u>call <SID>JumpH(1)<cr>
    "nnoremap <silent> <leader>j  :<c-u>call <SID>JumpJ(0)<cr>
    "vnoremap          <leader>j  :<c-u>call <SID>JumpJ(1)<cr>
    nnoremap          <leader>f  :ls<cr>:b<Space>
    nnoremap <silent> <leader>;  :<c-u>call <SID>JumpComma(0)<cr>
    vnoremap          <leader>;  :<c-u>call <SID>JumpComma(1)<cr>
"}}}


" View keymap {{{1
    "autocmd WinEnter * if !utils#IsLeftMostWindow() | let g:tagbar_left = 0 | else | let g:tagbar_left = 1 | endif
    function! s:ToggleTagbar()
        " Detect which plugins are open
        if exists('t:NERDTreeBufName')
            let nerdtree_open = bufwinnr(t:NERDTreeBufName) != -1
        else
            let nerdtree_open = 0
        endif

        if nerdtree_open
            let g:tagbar_left = 0
            "let g:tagbar_vertical = 25
            "let NERDTreeWinPos = 'left'
        else
            if utils#IsLeftMostWindow()
                let g:tagbar_left = 1
            else
                let g:tagbar_left = 0
            endif
            "let g:tagbar_vertical = 0
        endif

        TagbarToggle
        "let tagbar_open = bufwinnr('__Tagbar__') != -1
        "if tagbar_open
        "  TagbarClose
        "else
        "  TagbarOpen
        "endif

        "" Jump back to the original window
        "let w:jumpbacktohere = 1
        "for window in range(1, winnr('$'))
        "  execute window . 'wincmd w'
        "  if exists('w:jumpbacktohere')
        "    unlet w:jumpbacktohere
        "    break
        "  endif
        "endfor
    endfunction

    function! s:R(cap, ...)
        if a:cap
            tabnew
            setlocal buftype=nofile bufhidden=hide syn=diff noswapfile
            exec ":r !". join(a:000)
        else
            tabnew | enew | exec ":term ". join(a:000)
        endif
    endfunction

    "nnoremap <f3> :VimwikiFollowLink
    nnoremap <silent> <a-w> :MaximizerToggle<CR>
    nnoremap <silent> <a-e> :NERDTreeTabsToggle<cr>
    nnoremap <silent> <a-f> :NERDTreeFind<cr>
    nnoremap <silent> <a-u> :GundoToggle<CR>

    nnoremap <silent> <a-'> :VoomToggle<cr>
    nnoremap <silent> <a-;> :<c-u>call <SID>ToggleTagbar()<CR>
    "nnoremap <silent> <a-;> :TMToggle<CR>
    "nnoremap <silent> <a-.> :BuffergatorToggle<CR>
    "nnoremap <silent> <a-,> :VoomToggle<CR>
    "nnoremap <silent> <a-[> :Null<CR>
    "nnoremap <silent> <a-]> :Null<CR>
    "nnoremap <silent> <a-\> :Null<CR>

"}}}


" Other Keymaps {{{2
    " Toggle source/header
    "nnoremap <silent> <leader>a  :<c-u>FuzzyOpen <C-R>=printf("%s\\.", expand('%:t:r'))<cr><cr>
    nnoremap <silent> <leader>a  :<c-u>call CurtineIncSw()<cr>

    " Set log
    "nnoremap <silent> <leader>ll :<c-u>call log#log(expand('%'))<CR>
    "vnoremap <silent> <leader>ll :<c-u>call log#log(expand('%'))<CR>
    " Lint: -i ignore-error and continue, -s --silent --quiet

    "bookmark
    nnoremap <silent> <leader>mm :silent! call mark#MarkCurrentWord(expand('cword'))<CR>
    "nnoremap <leader>mf :echo(statusline#GetFuncName())<CR>
    "nnoremap <leader>mo :BookmarkLoad Default
    "nnoremap <leader>ma :BookmarkShowAll <CR>
    "nnoremap <leader>mg :BookmarkGoto <C-R><c-w>
    "nnoremap <leader>mc :BookmarkDel <C-R><c-w>
    "
    map W <Plug>(expand_region_expand)
    map B <Plug>(expand_region_shrink)

    nnoremap <silent> <leader>v] :NeomakeSh! tagme<cr>
    nnoremap <silent> <leader>vi :call utils#VoomInsert(0) <CR>
    vnoremap <silent> <leader>vi :call utils#VoomInsert(1) <CR>

    nnoremap <silent> <leader>gg :<C-\>e utilgrep#Grep(2,0)<cr><cr>
    vnoremap <silent> <leader>gg :<C-\>e utilgrep#Grep(2,1)<cr><cr>
    nnoremap <silent> <leader>vv :<C-\>e utilgrep#Grep(1,0)<cr><cr>
    vnoremap <silent> <leader>vv :<C-\>e utilgrep#Grep(1,1)<cr><cr>

    " script-eval
    "vnoremap <silent> <leader>ee :<c-u>call vimuxscript#ExecuteSelection(1)<CR>
    "nnoremap <silent> <leader>ee :<c-u>call vimuxscript#ExecuteSelection(0)<CR>
    "nnoremap <silent> <leader>eg :<c-u>call vimuxscript#ExecuteGroup()<CR>

    "" execute file that I'm editing in Vi(m) and get output in split window
    "nnoremap <silent> <leader>x :w<CR>:silent !chmod 755 %<CR>:silent !./% > /tmp/vim.tmpx<CR>
    "            \ :tabnew<CR>:r /tmp/vim.tmpx<CR>:silent !rm /tmp/vim.tmpx<CR>:redraw!<CR>
    nnoremap <silent> <leader>ee :call SingleCompileSplit() \| SCCompileRun<CR>
    nnoremap <silent> <leader>eo :SCViewResult<CR>
    "vnoremap <silent> <unique> <leader>ee :NR<CR> \| :w! /tmp/1.c<cr> \| :e /tmp/1.c<cr>

    function! SingleCompileSplit()
        if winwidth(0) > 200
            let g:SingleCompile_split = "vsplit"
            let g:SingleCompile_resultsize = winwidth(0)/2
        else
            let g:SingleCompile_split = "split"
            let g:SingleCompile_resultsize = winheight(0)/3
        endif
    endfunction

    vnoremap <silent> <leader>yy :<c-u>call utils#GetSelected("/tmp/vim.yank")<CR>
    nnoremap <silent> <leader>yy  :<c-u>call vimuxscript#Copy() <CR>
    nnoremap <silent> <leader>yp :r! cat /tmp/vim.yank<CR>

    xnoremap * :<C-u>call utils#VSetSearch('/')<CR>/<C-R>=@/<CR>
    xnoremap # :<C-u>call utils#VSetSearch('?')<CR>?<C-R>=@/<CR>
    vnoremap // y:vim /\<<C-R>"\C/gj %

    " Search-mode: hit cs, replace first match, and hit <Esc>
    "   then hit n to review and replace
    vnoremap <silent> s //e<C-r>=&selection=='exclusive'?'+1':''<CR><CR>
          \:<C-u>call histdel('search',-1)<Bar>let @/=histget('search',-1)<CR>gv
    onoremap s :normal vs<CR>

    nnoremap gf :<c-u>call utils#GotoFileWithLineNum()<CR>
    nnoremap <silent> <leader>gf :<c-u>call utils#GotoFileWithPreview()<CR>

    nnoremap <silent> mm :<c-u>call utils#MarkSelected('n')<CR>
    vnoremap <silent> mm :<c-u>call utils#MarkSelected('v')<CR>
"}}}

" Commands {{{2
    command! -nargs=* Wrap set wrap linebreak nolist
    "command! -nargs=* Wrap PencilSoft
    "command! -bang -nargs=* -complete=file Make AsyncRun -program=make @ <args>
    command! -nargs=+ -bang -complete=shellcmd
          \ Make execute ':NeomakeCmd make '. <q-args>

    command! -nargs=1 Silent
      \ | execute ':silent !'.<q-args>
      \ | execute ':redraw!'

    command! -nargs=* C0  setlocal autoindent cindent expandtab   tabstop=4 shiftwidth=4 softtabstop=4
    command! -nargs=* C08 setlocal autoindent cindent expandtab   tabstop=8 shiftwidth=2 softtabstop=8
    command! -nargs=* C2  setlocal autoindent cindent expandtab   tabstop=2 shiftwidth=2 softtabstop=2
    command! -nargs=* C4  setlocal autoindent cindent noexpandtab tabstop=4 shiftwidth=4 softtabstop=4
    command! -nargs=* C8  setlocal autoindent cindent noexpandtab tabstop=8 shiftwidth=8 softtabstop=8

    " :R ls -l   grab command output int new buffer
    " :R! ls -l   only show output in another tab
    "command! -nargs=+ -bang -complete=shellcmd R call s:R(<bang>1, <q-args>)
    command! -nargs=+ -bang -complete=shellcmd R execute ':NeomakeRun! '.<q-args>

"}}}


" vim-venu: depend Plug 'Timoses/vim-venu' {{{1
    let s:menu1 = venu#create('My first V̂enu')
    call venu#addItem(s:menu1, 'Item of first menu', 'echo "Called first item"')
    call venu#register(s:menu1)

    function! s:myfunction() abort
        echo "I called myfunction"
    endfunction

    let s:menu2 = venu#create('My second V̂enu')
    call venu#addItem(s:menu2, 'Call a function ref', function("s:myfunction"))

    let s:submenu = venu#create('My awesome subV̂enu')
    call venu#addItem(s:submenu, 'Item 1', ':echo "First item of submenu!"')
    call venu#addItem(s:submenu, 'Item 2', ':echo "Second item of submenu!"')

    " Add the submenu to the second menu
    call venu#addItem(s:menu2, 'Sub menu', s:submenu)
    call venu#register(s:menu2)
"}}}

" Quickmenu & KeyMap: depend Plug 'daniel-samson/quickmenu.vim' {{{1
    noremap <silent><F1> :call quickmenu#toggle(0)<cr>
    "noremap <silent><F1> :call quickmenu#bottom(0)<cr>

    "noremap <silent> <leader><space> :call quickmenu#bottom(0)<cr>
    "noremap <silent> <leader>1 :call quickmenu#bottom(1)<cr>

    function MyMenuExec(...)
        let strCmd = join(a:000, '')
        silent! call s:log.info('MyExecArgs: "', strCmd, '"')
        exec strCmd
    endfunc

    function! SelectedReplace()
        let sel_str = utils#GetSelected('')

        let nr = winnr()
        if getwinvar(nr, '&syntax') == 'qf'
            call setpos('.', l:save_cursor)
            return "%s/\\<". sel_str. '\>/'. sel_str. '/gI'
        else
            delmarks un
            normal [[mu%mn
            call signature#sign#Refresh(1)
            redraw
            return "'u,'ns/\\<". sel_str. '\>/'. sel_str. '/gI'
        endif
    endfunction

    " enable cursorline (L) and cmdline help (H)
    let g:quickmenu_options = ""
    "call quickmenu#header("Helper")
    " Clear all the items
    call quickmenu#reset()

    " Section 'Execute'
        nnoremap <leader>mk :Make -i -s -j6 -C daemon/wad <CR>
        nnoremap <leader>ma :Make -i -s -j6 -C sysinit <CR>
        nnoremap <leader>mw :R! ~/tools/dict <C-R>=expand('<cword>') <cr>
        nnoremap <leader>mf :call utilquickfix#QuickFixFilter() <CR>
        nnoremap <leader>mc :call utilquickfix#QuickFixFunction() <CR>

    " new section: empty action with text starts with "#" represent a new section
    call quickmenu#append("# Execute", '')
        "call quickmenu#append(text="Run %{expand('%:t')}", action='!./%', help="Run current file", ft="c,cpp,objc,objcpp")
        call quickmenu#append("Update TAGs",          "NeomakeSh! tagme", "")
        call quickmenu#append("(mw) dict <word>",     'call MyMenuExec("R! ~/tools/dict ", expand("<cword>"))', "")
        call quickmenu#append("Run %{expand('%:t')}", '!./%', "Run current file")
        call quickmenu#append("(ma) make init",       "Make -j6 -i -s  -C sysinit", "")
        call quickmenu#append("(mk) make wad",        "Make -i -s -j6 -C daemon/wad", "")
        call quickmenu#append("(mf) qfix filter",     "call utilquickfix#QuickFixFilter()", "")
        call quickmenu#append("(mc) qfix function",   "call utilquickfix#QuickFixFunction()", "")

    call quickmenu#append("# Tmux marked pane", '')
        call quickmenu#append("(tf) Exec file",     'VtrSendFile',  "Execute the file itself bin: python, awk")
        call quickmenu#append("(tt) Send mark/sel", 'call VtrSendCommandEx("n")', "only execute the command")
        call quickmenu#append("(tw) Exec mark/sel", 'call VtrExecuteCommand("n")', "execute the command, also insert the output")
        call quickmenu#append("(tc) clear",         'VtrClearRunner', "")

    call quickmenu#append("# View", '')
        call quickmenu#append("Outline",   'VoomToggle markdown',  "use fugitive's Gvdiff on current document")
        call quickmenu#append("Maximizer", 'MaximizerToggle',  "use fugitive's Gvdiff on current document")
        call quickmenu#append("NERDTree",  'NERDTreeTabsToggle',  "use fugitive's Gvdiff on current document")
        call quickmenu#append("TagBar",    "TagbarToggle", "Switch Tagbar on/off")

    " Section 'Git'
        "nnoremap <leader>bb :VCBlame<cr>
        nnoremap <leader>bb :Gblame<cr>
        nnoremap <leader>bl :GV

    call quickmenu#append("# Git", '')
        call quickmenu#append("git diff",   'Gvdiff',  "use fugitive's Gvdiff on current document")
        call quickmenu#append("git status", 'Gstatus', "use fugitive's Gstatus on current document")
        call quickmenu#append("git blame",  'Gblame',  "use fugitive's Gblame on current document")

    " Section 'String'
        "map <leader>ds :call Asm() <CR>
        nnoremap <leader>df :%s/\s\+$//g
        nnoremap <leader>dd :g/<C-R><C-w>/ norm dd
        vnoremap <leader>dd :<c-u>g/<C-R>*/ norm dd
        " For local replace
        "nnoremap <leader>vm [[ma%mb:call signature#sign#Refresh(1) <CR>
        nnoremap <leader>vr :<C-\>e SelectedReplace()<CR><left><left><left>
        vnoremap <leader>vr :<C-\>e SelectedReplace()<CR><left><left><left>
        " remove space from emptyline
        "nnoremap <leader>v<space> :%s/^\s\s*$//<CR>
        "vnoremap <leader>v<space> :s/^\s\s*$//<cr>

        " count the number of occurrences of a word
        "nnoremap <leader>vc :%s/<C-R>=expand('<cword>')<cr>//gn<cr>

        " For global replace
        nnoremap <leader>vR gD:%s/<C-R>///g<left><left>
        "
        "nnoremap <leader>vr :Replace <C-R>=expand('<cword>') <CR> <C-R>=expand('<cword>') <cr>
        "vnoremap <leader>vr ""y:%s/<C-R>=escape(@", '/\')<CR>/<C-R>=escape(@", '/\')<CR>/g<Left><Left>
        "
        "vnoremap <leader>vr :<C-\>e tmp#CurrentReplace() <CR>
        "nnoremap <leader>vr :Replace <C-R>=expand('<cword>') <CR> <C-R>=expand('<cword>') <cr>

    call quickmenu#append("# String", '')
        call quickmenu#append("Replace last search",                        "execute '%s///gc'", "")
        call quickmenu#append("Replace search with `%{expand('<cword>')}`", 'call MyMenuExec("%s//", expand("<cword>"), "/gc")', "")
        call quickmenu#append("Replace last search",                        "execute '%s///gc'", "")
        call quickmenu#append("Remove empty lines",                         "g/^$/d", "delete blank lines, remove multi blank line")
        call quickmenu#append("Remove extra empty lines",                   "%s/\\n\\{3,}/\\r\\r/e", "replace three or more consecutive line endings with two line endings (a single blank line)")
        call quickmenu#append("(df) Remove ending space",                   "%s/\\s\\+$//g", "remove unwanted whitespace from line end")
        call quickmenu#append("(dd) Remove lines of last search",           "g//norm dd", '')

    " Section 'Misc'
    call quickmenu#append("# Misc", '')
        "call quickmenu#append("Turn paste %{&paste? 'off':'on'}",           "set paste!", "enable/disable paste mode (:set paste!)")
        "call quickmenu#append("Turn spell %{&spell? 'off':'on'}",           "set spell!", "enable/disable spell check (:set spell!)")
        call quickmenu#append("Count of selected",            "g Ctrl-G", "Show the number of lines, words and bytes selected")
        call quickmenu#append("Count `%{expand('<cword>')}`", 'call MyMenuExec("%s/", expand("<cword>"), "//gn")', '')
        call quickmenu#append("Convert number",               "normal gA", "")

"}}}

" vim:set ft=vim et sw=4: