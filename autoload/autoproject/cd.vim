" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2022-08-19
" @Revision:    236

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
    " Entries from |g:autoproject#projectrc#buffer_config| are automaticall 
    " added.
    "
    " The variable g:autoproject#cd#markers_user will be concatenated to 
    " this variable.
    " :read: let g:autoproject#cd#markers = {...}   "{{{2
    let g:autoproject#cd#markers = {
                \ '*.Rproj': {'match': 'glob'},
                \ '.cvs': {},
                \ '.git': {},
                \ '.hg': {},
                \ '.svn': {},
                \ '.project': {},
                \ '.classpath': {},
                \ '.iml': {},
                \ 'build.gradle': {},
                \ '.editorconfig': {},
                \ '.obsidian': {},
                \ 'project.json': {},
                \ '.projectvim': {},
                \ '_projectvim': {},
                \ 'project.vim': {},
                \ '.lvimrc': {},
                \ 'setup.py': {},
                \ 'setup.rb': {},
                \ '[\/]pack[\/][^\/]\+[\/]\%(start\|opt\)[\/][^\/]\+$': {'match': 'rx', 'use': 'path'},
                \ 'Makefile': {'fallback': 1},
                \ }
endif
if exists('g:autoproject#cd#markers_user')
    let g:autoproject#cd#markers = extend(g:autoproject#cd#markers, g:autoproject#cd#markers_user)
endif
for s:fname in g:autoproject#projectrc#buffer_config
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


if !exists('g:autoproject#cd#name_map')
    " A map {ROOTDIR => NAME}.
    "
    " By default, a project names is the tail of ROOTDIR (should be all 
    " slashes, no backslashes). Use this dictionary, to assign a 
    " different project name to a rootdir.
    "                                                   *b:autoproject_name*
    " The project NAME will be assigned to `b:autoproject_name` unless 
    " it was already set in the project config file (see 
    " |g:autoproject#projectrc#buffer_config|).
    let g:autoproject#cd#name_map = {}   "{{{2
endif


if !exists('g:autoproject#cd#verbose')
    let g:autoproject#cd#verbose = &verbose > 0   "{{{2
endif


function! autoproject#cd#GetMap() abort "{{{3
    let persist_cname = tlib#persistent#EncodedFilename('autoproject', '*map*', 1)
    let persist = tlib#persistent#Get(persist_cname, {'*version*': 0})
    return [persist_cname, persist]
endf


function! autoproject#cd#SaveMap(persist_cname, persist) abort "{{{3
    call tlib#persistent#Save(a:persist_cname, a:persist)
endf


function! autoproject#cd#MaybeMap(cdir) abort "{{{3
    let [persist_cname, persist] = autoproject#cd#GetMap()
    return get(persist, a:cdir, a:cdir)
endf


function! autoproject#cd#MapDir(redir, ...) abort "{{{3
    let dir = a:0 >= 1 ? a:1 : expand('%')
    let [persist_cname, persist] = autoproject#cd#GetMap()
    let cdir = tlib#file#Canonic(tlib#file#Absolute(dir))
    let credir = tlib#file#Canonic(tlib#file#Absolute(a:redir))
    if !has_key(persist, cdir) || persist[cdir] !=# credir
        let persist[cdir] = credir
        call autoproject#cd#SaveMap(persist_cname, persist)
    endif
    call tlib#buffer#BufDo('if b:autoproject_dir == cdir | call s:SetBufVars(a:credir) | endif')
endf


function! autoproject#cd#ChangeDir(filename, ...) abort "{{{3
    if getbufvar(a:filename, '&buftype') ==# 'nofile'
        return
    endif
    let dir = fnamemodify(a:filename, ':p:h')
    let [reg_cname, reg] = autoproject#list#GetReg()
    Tlibtrace 'autoproject', reg
    if getbufvar(a:filename, 'autoproject_use_bufdir', 0) || (!empty(g:autoproject#cd#buffer_use_bufdir_rx) && a:filename =~ g:autoproject#cd#buffer_use_bufdir_rx)
        let rootdir = dir
        let rootmode = 'bufdir'
    else
        let default = a:0 >= 1 ? a:1 : dir
        Tlibtrace 'autoproject', default
        let rootdir = ''
        let rootmode = ''
        let is_project = 0
        " let rootw = 0
        " let rootdir = a:0 >= 2 ? eval(a:2) : ''
        let markers = items(g:autoproject#cd#markers)
        while dir !~# '^\%(/\|\%([a-zA-Z]\+:\)\)\?$'
            Tlibtrace 'autoproject', dir
            try
                let cdir = tlib#file#Canonic(dir)
                Tlibtrace 'autoproject', cdir
                if index(reg, cdir) != -1
                    let rootmode = '*reg*'
                    let rootdir = dir
                    throw 'ok'
                else
                    let files = globpath(dir, '*', 1, 1) + filter(globpath(dir, '.*', 1, 1), 'v:val !~# ''\%([\/]\|^\)\?\.\+$''')
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
                                    if dir != $HOME
                                        let default = dir
                                        Tlibtrace 'autoproject', 'fallback', default, item, basename, dir
                                    endif
                                else
                                    let rootdir = dir
                                    let rootmode = name
                                    Tlibtrace 'autoproject', 'rootdir', default
                                    throw 'ok'
                                endif
                            endif
                        endfor
                    endfor
                endif
                let dir = substitute(dir, '[\/][^\/]\+$', '', '')
            catch /ok/
                let is_project = 1
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
            let rootmode = 'default'
            " echom 'DBG autoproject#cd#ChangeDir default' default
        endif
    endif
    if !empty(rootdir)
        let realrootdir = autoproject#cd#SetCD(rootmode, rootdir)
        if !empty(realrootdir)
            Tlibtrace 'autoproject', rootdir, $HOME, dir, is_project
            if is_project
                unlet! b:autoproject_name
                if rootmode ==# '*reg*'
                    call autoproject#list#RegisterDir(realrootdir)
                else
                    call autoproject#list#RegisterNameDir(rootmode, realrootdir)
                endif
                if !exists('b:autoproject_name')
                    call s:SetBufVars(realrootdir)
                endif
            endif
        endif
    endif
endf


function! s:SetBufVars(rootdir) abort "{{{3
    let crootdir = tlib#file#Canonic(a:rootdir)
    let b:autoproject_name = autoproject#cd#GetName(crootdir)
    let b:autoproject_dir = crootdir
endf


function! autoproject#cd#GetName(crootdir) abort "{{{3
    return get(g:autoproject#cd#name_map, a:crootdir, matchstr(a:crootdir, '[^\/]\+\ze[\/]\?$'))
endf


if exists(':TStatusregister1') == 2
    TStatusregister --event=BufWinEnter b:autoproject_name=APrj
endif


function! autoproject#cd#SetCD(mode, dir) abort "{{{3
    let cmd = g:autoproject#cd#cmd
    if g:autoproject#cd#verbose
        echom 'autoproject:' cmd a:dir
    endif
    let dir = autoproject#cd#MaybeMap(a:dir)
    Tlibtrace 'autoproject', cmd, a:dir, dir, bufnr('%')
    let w:autoproject_lcd = a:mode
    exec cmd fnameescape(dir)
    if !exists('b:autoproject_lcd')
        let b:autoproject_lcd = a:mode
        call autoproject#projectrc#LoadBufferConfig(dir)
        return dir
    else
        return ''
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
    if !exists('w:autoproject_lcd') && !empty(a:filename) && a:filename !~ g:autoproject#cd#buffer_blacklist_rx
        let default = eval(printf(g:autoproject#cd#buffer_default_exprf, string(a:filename)))
        Tlibtrace 'autoproject', default, a:filename
        call autoproject#cd#ChangeDir(a:filename, default)
    endif
endf

