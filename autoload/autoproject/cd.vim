" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2017-02-11
" @Revision:    153

if exists(':Tlibtrace') != 2
    command! -nargs=+ -bang Tlibtrace :
endif


if !exists('g:autoproject#cd#cmd')
    let g:autoproject#cd#cmd = 'lcd'   "{{{2
endif


if !exists('g:autoproject#cd#markers')
    " Supported properties:
    "   match ..... One of 'rx', 'glob', 'fixed' (default)
    "   use ....... One of 'path', 'basename' (default)
    "   fallback .. 0 (default) or 1
    " Entries from |g:autoproject#projectrc#filenames| are automaticall 
    " added.
    "
    " The variable g:autoproject#cd#markers_user will be concatenated to 
    " this variable.
    " :read: let g:tlib#project#file_markers = {...}   "{{{2
    let g:autoproject#cd#markers = {
                \ '.cvs': {},
                \ '.git': {},
                \ '.hg': {},
                \ '.svn': {},
                \ '.project': {},
                \ '.classpath': {},
                \ '.iml': {},
                \ 'build.gradle': {},
                \ 'project.json': {},
                \ 'project.vim': {},
                \ 'setup.py': {},
                \ 'setup.rb': {},
                \ '[\/]pack[\/][^\/]\+[\/]\%(start\|opt\)[\/][^\/]\+$': {'match': 'rx', 'use': 'path'},
                \ 'Makefile': {'fallback': 1},
                \ }
endif
if exists('g:autoproject#cd#markers_user')
    let g:autoproject#cd#markers = extend(g:autoproject#cd#markers, g:autoproject#cd#markers_user)
endif
for s:fname in g:autoproject#projectrc#filenames
    let g:autoproject#cd#markers[s:fname] = {}
endfor
unlet! s:fname


if !exists('g:autoproject#cd#buffer_blacklist_rx')
    let g:autoproject#cd#buffer_blacklist_rx = '\%(^__.\{-}__$\)'   "{{{2
endif


if !exists('g:autoproject#cd#buffer_default_exprf')
    let g:autoproject#cd#buffer_default_exprf = 'fnamemodify(%s, ":p:h")'   "{{{2
endif


if !exists('g:autoproject#cd#buffer_use_bufdir_rx')
    let g:autoproject#cd#buffer_use_bufdir_rx = ''   "{{{2
endif


if !exists('g:autoproject#cd#verbose')
    let g:autoproject#cd#verbose = &verbose > 0   "{{{2
endif


function! autoproject#cd#ChangeDir(filename, ...) abort "{{{3
    if getbufvar(a:filename, '&buftype') ==# 'nofile'
        return
    endif
    let cmd = a:0 >= 1 ? a:1 : g:autoproject#cd#cmd
    Tlibtrace 'autoproject', cmd
    let dir = fnamemodify(a:filename, ':p:h')
    if getbufvar(a:filename, 'autoproject_use_bufdir', 0) || (!empty(g:autoproject#cd#buffer_use_bufdir_rx) && a:filename =~ g:autoproject#cd#buffer_use_bufdir_rx)
        let rootdir = dir
        let rootname = 'bufdir'
    else
        let default = a:0 >= 2 ? a:2 : dir
        Tlibtrace 'autoproject', default
        let rootdir = ''
        let rootname = ''
        " let rootw = 0
        " let rootdir = a:0 >= 2 ? eval(a:2) : ''
        let markers = items(g:autoproject#cd#markers)
        while dir !~ '^\%(/\|\%([a-zA-Z]\+:\)\)\?$'
            Tlibtrace 'autoproject', dir
            try
                let files = globpath(dir, "*", 0, 1) + filter(globpath(dir, ".*", 0, 1), {i, v -> v !~# '\%([\/]\|^\)\?\.\+$'})
                Tlibtrace 'autoproject', files
                for file in files
                    let basename = matchstr(file, '[^\/]\+$')
                    " Tlibtrace 'autoproject', basename
                    for [name, mdef] in markers
                        " Tlibtrace 'autoproject', name, mdef
                        let item = get(mdef, 'use', 'basename') ==# 'path' ? dir : basename
                        " Tlibtrace 'autoproject', item
                        if s:Match(item, name, mdef)
                            Tlibtrace 'autoproject', item, name
                            if get(mdef, 'fallback', 0)
                                if item != $HOME
                                    let default = dir
                                    Tlibtrace 'autoproject', 'fallback', default, item, basename, dir
                                endif
                            else
                                let rootdir = dir
                                let rootname = name
                                Tlibtrace 'autoproject', 'rootdir', default
                            endif
                            throw 'ok'
                        endif
                    endfor
                endfor
                let dir = substitute(dir, '[\/][^\/]\+$', '', '')
            catch /ok/
                break
            catch
                echohl ErrorMsg
                echom v:exception
                echohl NONE
                break
            endtry
        endwh
        Tlibtrace 'autoproject', rootdir, default
        if empty(rootdir)
            let rootdir = default
            let rootname = 'default'
            " echom 'DBG autoproject#cd#ChangeDir default' default
        endif
    endif
    if !empty(rootdir)
        " echom 'DBG autoproject#cd#ChangeDir' cmd rootdir
        if g:autoproject#cd#verbose
            echom 'autoproject:' cmd rootdir
        endif
        Tlibtrace 'autoproject', cmd, rootdir, bufnr('%')
        let b:autoproject_lcd = rootname
        exec cmd fnameescape(rootdir)
        call autoproject#projectrc#Load(rootdir)
    endif
endf


function! s:Match(item, pattern, mdef) abort "{{{3
    let match = get(a:mdef, 'match', 'fixed')
    if match ==# 'glob'
        let pattern = glob2regpat(a:pattern)
        let match = 'rx'
    else
        let pattern = a:pattern
    endif
    if match ==# 'rx'
        if has('fname_case') ? a:item =~# a:pattern : a:item =~? a:pattern
            Tlibtrace 'autoproject', a:item, match, a:pattern
            return 1
        end
    else
        if has('fname_case') ? a:item ==# a:pattern : a:item ==? a:pattern
            Tlibtrace 'autoproject', a:item, match, a:pattern
            return 1
        endif
    endif
    return 0
endf


function! autoproject#cd#Buffer(filename) abort "{{{3
    " echom 'DBG autoproject#cd#Buffer' a:filename
    if !exists('b:autoproject_lcd') && !empty(a:filename) && a:filename !~ g:autoproject#cd#buffer_blacklist_rx
        let default = eval(printf(g:autoproject#cd#buffer_default_exprf, string(a:filename)))
        Tlibtrace 'autoproject', default, a:filename
        call autoproject#cd#ChangeDir(a:filename, 'lcd', default)
    endif
endf

