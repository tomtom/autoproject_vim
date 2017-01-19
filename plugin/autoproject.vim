" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2017-01-19
" @Revision:    9
" GetLatestVimScripts: 0 0 :AutoInstall: autoproject.vim

if &cp || exists("loaded_autoproject")
    finish
endif
let loaded_autoproject = 1

let s:save_cpo = &cpo
set cpo&vim


if !exists('g:autoproject_enable_cd')
    let g:autoproject_enable_cd = !(&autochdir)   "{{{2
endif


augroup Autoproject
    autocmd!
    autocmd BufNewFile,BufRead * if g:autoproject_enable_cd | call autoproject#cd#Buffer(expand("<afile>:p")) | endif
augroup END


let &cpo = s:save_cpo
unlet s:save_cpo
