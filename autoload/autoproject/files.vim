" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2020-05-29
" @Revision:    18


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


" :display: autoproject#files#Dirs(?bufnr=bufnr('%'))
function! autoproject#files#Dirs(...) abort "{{{3
    let bnr = a:0 >= 1 ? a:1 : bufnr('%')
    let adir = getbufvar(bnr, 'autoproject_dir')
    if !empty(adir)
        let dirs = [adir]
        let rprjs = getbufvar(bnr, 'autoproject_related_projects')
        if !empty(rprjs)
            let [reg_cname, reg] = autoproject#list#GetReg()
            for rdir in reg
                let rname = autoproject#cd#GetName(rdir)
                if index(rprjs, rname) != -1
                    call add(dirs, rdir)
                endif
            endfor
        endif
        let rdirs = getbufvar(bnr, 'autoproject_related_dirs')
        if !empty(rdirs)
            call extend(dirs, rdirs)
        endif
        return dirs
    else
        throw 'autoproject#files#Dirs: Is no autoproject buffer: '. bnr
    endif
endf


" :display: autoproject#files#Findfiles(?pattern = '**', ?bufnr=bufnr('%'))
function! autoproject#files#Findfiles(...) abort "{{{3
    let pattern_ = a:0 >= 1 ? a:1 : ['**']
    let bnr = a:0 >= 2 ? a:2 : bufnr('%')
    if type(pattern_) == 1
        let patterns = [pattern_]
    elseif type(pattern_) == 3
        let patterns = pattern_
    else
        throw 'autoproject#files#Findfiles: pattern must be a string or a list: '. string(a:pattern)
    endif
    let dirs = autoproject#files#Dirs(bnr)
    let path = join(map(dirs, 'escape(v:val, ",")'), ',')
    let files = []
    for pattern in patterns
        call extend(files, globpath(path, pattern, 1, 1))
    endfor
    return files
endf

