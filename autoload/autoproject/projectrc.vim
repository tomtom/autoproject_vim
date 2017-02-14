" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2017-02-11
" @Revision:    13


if !exists('g:autoproject#projectrc#filenames')
    " A list of files for project-related settings. Only the first 
    " matching file will be loaded.
    let g:autoproject#projectrc#filenames = ['project.vim']   "{{{2
endif


if !exists('g:autoproject#projectrc#sandbox')
    " If true, evaluate a file from |g:autoproject#projectrc#filenames| 
    " in a |sandbox|.
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


function! autoproject#projectrc#SearchAndLoad(rootdir) abort "{{{3
    " TODO
    return autoproject#projectrc#Load(a:rootdir)
endf

