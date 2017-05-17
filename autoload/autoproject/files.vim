" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2017-05-08
" @Revision:    11


if !exists('g:autoproject#files#edit_cmd')
    let g:autoproject#files#edit_cmd = 'exec "tab drop" fnameescape(%s)'   "{{{2
endif


function! autoproject#files#Ensure(filename) abort "{{{3
    Tlibtrace 'autoproject', a:filename
    if bufnr(a:filename) == -1
        let cmd = printf(g:autoproject#files#edit_cmd, string(a:filename))
        Tlibtrace 'autoproject', cmd
        exec cmd
        return 1
    endif
    return 0
endf

