if exists("g:loaded_vim_demo_textobj") || &cp || v:version < 700
    finish
endif
let g:loaded_vim_demo_textobj = 1


" https://vim.fandom.com/wiki/Regex_lookahead_and_lookbehind
call textobj#user#plugin('mydemoobj', {
            \   'attr-i': {
            \     'pattern': '<start>\zs\_.\{-}\ze<end>',
            \     'select': 'it',
            \   },
            \   'attr-a': {
            \     'pattern': '<start>\_.\{-}<end>',
            \     'select': 'at',
            \   },
            \ })


" vim:set ft=vim et sw=4:

