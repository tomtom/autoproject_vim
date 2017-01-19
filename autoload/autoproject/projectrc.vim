" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2017-01-18
" @Revision:    9


if !exists('g:autoproject#projectrc#filenames')
    let g:autoproject#projectrc#filenames = ['project.vim']   "{{{2
endif


if !exists('g:autoproject#projectrc#sandbox')
    let g:autoproject#projectrc#sandbox = 1   "{{{2
endif

let s:sandbox_cmd = g:autoproject#projectrc#sandbox ? 'sandbox' : ''


function! autoproject#projectrc#Load(rootdir) abort "{{{3
    if !exists('b:autoproject_pvim')
        Tlibtrace 'autoproject', a:rootdir
        for filename in g:autoproject#projectrc#filenames
            let filename = a:rootdir .'/'. filename
            Tlibtrace 'autoproject', filename, filereadable(filename)
            if filereadable(filename)
                exec s:sandbox_cmd 'source' fnameescape(filename)
                break
            endif
        endfor
        let b:autoproject_pvim = 1
    endif
endf

