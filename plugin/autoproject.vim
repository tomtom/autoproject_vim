" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2017-02-11
" @Revision:    14
" GetLatestVimScripts: 0 0 :AutoInstall: autoproject.vim

if &cp || exists("loaded_autoproject")
    finish
endif
let loaded_autoproject = 1

let s:save_cpo = &cpo
set cpo&vim


if !exists('g:autoproject_enable_cd')
    " If true, try to detect a file's project directory.
    let g:autoproject_enable_cd = !(&autochdir)   "{{{2
endif

if !exists('g:autoproject_map_edit')
    " Map to invoke |:edit| with a `%:p:h/` argument.
    let g:autoproject_map_edit = '<Leader>:e'   "{{{2
endif


augroup Autoproject
    autocmd!
    autocmd BufNewFile,BufRead * if g:autoproject_enable_cd | call autoproject#cd#Buffer(expand("<afile>:p")) | else | call autoproject#projectrc#SearchAndLoad(expand('%:p:h')) | endif
augroup END


if !empty(g:autoproject_map_edit)
    exec 'nmap <expr>' g:autoproject_map_edit '":e ". expand("%:p:h") ."/"'
endif


let &cpo = s:save_cpo
unlet s:save_cpo
