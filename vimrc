" vim: fdm=marker ts=2 sts=2 sw=2 fdl=0

" detect OS {{{
  let s:is_macvim = has('gui_macvim')
"}}}

" dotvim settings {{{
  if !exists('g:dotvim_settings') || !exists('g:dotvim_settings.version')
    echom 'The g:dotvim_settings and g:dotvim_settings.version variables must be defined.  Please consult the README.'
    finish
  endif

  if g:dotvim_settings.version != 2
    echom 'The version number in your shim does not match the distribution version.  Please consult the README changelog section.'
    finish
  endif

  " initialize default settings
  let s:settings = {}
  let s:settings.default_indent = 2
  let s:settings.max_column = 120
  let s:settings.autocomplete_method = 'neocomplcache'
  let s:settings.enable_cursorcolumn = 0
  let s:settings.colorscheme = 'jellybeans'
  if has('lua')
    let s:settings.autocomplete_method = 'neocomplete'
  elseif filereadable(expand("~/.vim/bundle/YouCompleteMe/python/ycm_core.*"))
    let s:settings.autocomplete_method = 'ycm'
  endif

  if exists('g:dotvim_settings.plugin_groups')
    let s:settings.plugin_groups = g:dotvim_settings.plugin_groups
  else
    let s:settings.plugin_groups = []
    call add(s:settings.plugin_groups, 'core')
    call add(s:settings.plugin_groups, 'web')
    call add(s:settings.plugin_groups, 'javascript')
    call add(s:settings.plugin_groups, 'ruby')
    call add(s:settings.plugin_groups, 'python')
    call add(s:settings.plugin_groups, 'scm')
    call add(s:settings.plugin_groups, 'editing')
    call add(s:settings.plugin_groups, 'indents')
    call add(s:settings.plugin_groups, 'navigation')
    call add(s:settings.plugin_groups, 'unite')
    call add(s:settings.plugin_groups, 'autocomplete')
    call add(s:settings.plugin_groups, 'osx')
    call add(s:settings.plugin_groups, 'misc')

    " exclude all language-specific plugins by default
    if !exists('g:dotvim_settings.plugin_groups_exclude')
      let g:dotvim_settings.plugin_groups_exclude = ['web','javascript','ruby','python','osx']
    endif
    for group in g:dotvim_settings.plugin_groups_exclude
      let i = index(s:settings.plugin_groups, group)
      if i != -1
        call remove(s:settings.plugin_groups, i)
      endif
    endfor

    if exists('g:dotvim_settings.plugin_groups_include')
      for group in g:dotvim_settings.plugin_groups_include
        call add(s:settings.plugin_groups, group)
      endfor
    endif
  endif

  " override defaults with the ones specified in g:dotvim_settings
  for key in keys(s:settings)
    if has_key(g:dotvim_settings, key)
      let s:settings[key] = g:dotvim_settings[key]
    endif
  endfor
"}}}

" setup & neobundle {{{
  set nocompatible
  set all& "reset everything to their defaults
  set rtp+=~/.vim/bundle/neobundle.vim
  call neobundle#rc(expand('~/.vim/bundle/'))
  NeoBundleFetch 'Shougo/neobundle.vim'
"}}}

" functions {{{
  function! Preserve(command) "{{{
    " preparation: save last search, and cursor position.
    let _s=@/
    let l = line(".")
    let c = col(".")
    " do the business:
    execute a:command
    " clean up: restore previous search history, and cursor position
    let @/=_s
    call cursor(l, c)
  endfunction "}}}
  function! StripTrailingWhitespace() "{{{
    call Preserve("%s/\\s\\+$//e")
  endfunction "}}}
  function! EnsureExists(path) "{{{
    if !isdirectory(expand(a:path))
      call mkdir(expand(a:path))
    endif
  endfunction "}}}
  function! CloseWindowOrKillBuffer() "{{{
    let number_of_windows_to_this_buffer = len(filter(range(1, winnr('$')), "winbufnr(v:val) == bufnr('%')"))

    " never bdelete a nerd tree
    if matchstr(expand("%"), 'NERD') == 'NERD'
      wincmd c
      return
    endif

    if number_of_windows_to_this_buffer > 1
      wincmd c
    else
      bdelete
    endif
  endfunction "}}}
 "Next and Last "{{{

  " Motion for "next/last object".  "Last" here means "previous", not final".
  " Unfortunately the "p" motion was already taken for paragraphs.
  "
  " Next acts on the next object of the given type in the current line, last acts
  " on the previous object of the given type in the current line.
  "
  " Currently only works for (, [, {, b, r, B, ', and ".
  "
  " Some examples (C marks cursor positions, V means visually selected):
  "
  " din'  -> delete in next single quotes                foo = bar('spam')
  "                                                      C
  "                                                      foo = bar('')
  "                                                                C
  "
  " canb  -> change around next parens                   foo = bar('spam')
  "                                                      C
  "                                                      foo = bar
  "                                                               C
  "
  " vil"  -> select inside last double quotes            print "hello ", name
  "                                                                        C
  "                                                      print "hello ", name
  "                                                             VVVVVV

  onoremap an :<c-u>call <SID>NextTextObject('a', 'f')<cr>
  xnoremap an :<c-u>call <SID>NextTextObject('a', 'f')<cr>
  onoremap in :<c-u>call <SID>NextTextObject('i', 'f')<cr>
  xnoremap in :<c-u>call <SID>NextTextObject('i', 'f')<cr>

  onoremap al :<c-u>call <SID>NextTextObject('a', 'F')<cr>
  xnoremap al :<c-u>call <SID>NextTextObject('a', 'F')<cr>
  onoremap il :<c-u>call <SID>NextTextObject('i', 'F')<cr>
  xnoremap il :<c-u>call <SID>NextTextObject('i', 'F')<cr>

  function! s:NextTextObject(motion, dir)
    let c = nr2char(getchar())

    if c ==# "b"
        let c = "("
    elseif c ==# "B"
        let c = "{"
    elseif c ==# "r"
         let c = "["
    endif

    exe "normal! ".a:dir.c."v".a:motion.c
  endfunction

   "}}}
 "}}}

" base configuration {{{
  set timeoutlen=1000                                  "mapping timeout
  set ttimeoutlen=100                                  "keycode timeout
  set cryptmethod=blowfish

  set mouse=a                                         "enable mouse
  set mousehide                                       "hide when characters are typed
  set history=1000                                    "number of command lines to remember
  set ttyfast                                         "assume fast terminal connection
  set viewoptions=folds,options,cursor,unix,slash     "unix/windows compatibility
  set encoding=utf-8                                  "set encoding for text
  if exists('$TMUX')
    set clipboard=
  else
    set clipboard=unnamed                             "sync with OS clipboard
  endif
  set hidden                                          "allow buffer switching without saving
  set autoread                                        "auto reload if file saved externally
  set fileformats+=mac                                "add mac to auto-detection of file format line endings
  set nrformats-=octal                                "always assume decimal numbers
  set showcmd
  set tags=tags;/
  set showfulltag
  set modeline
  set modelines=5

  " whitespace
  set backspace=indent,eol,start                      "allow backspacing everything in insert mode
  set autoindent                                      "automatically indent to match adjacent lines
  set expandtab                                       "spaces instead of tabs
  set smarttab                                        "use shiftwidth to enter tabs
  let &tabstop=s:settings.default_indent              "number of spaces per tab for display
  let &softtabstop=s:settings.default_indent          "number of spaces per tab in insert mode
  let &shiftwidth=s:settings.default_indent           "number of spaces when indenting
  set list                                            "highlight whitespace
  set listchars=tab:│\ ,trail:•,extends:❯,precedes:❮
  set shiftround
  set linebreak
  let &showbreak='↪ '

  set scrolloff=1                                     "always show content after scroll
  set scrolljump=5                                    "minimum number of lines to scroll
  set display+=lastline
  set wildmenu                                        "show list for autocomplete
  set wildmode=list:full
  set wildignorecase
  set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/.idea/*,*/.DS_Store,*/.pyc,*/.o

  set splitbelow
  set splitright

  " disable sounds
  set noerrorbells
  set novisualbell
  set t_vb=

  " searching
  set hlsearch                                        "highlight searches
  set incsearch                                       "incremental searching
  set ignorecase                                      "ignore case for searching
  set smartcase                                       "do case-sensitive if there's a capital letter
  if executable('ack')
    set grepprg=ack\ --nogroup\ --column\ --smart-case\ --nocolor\ --follow\ $*
    set grepformat=%f:%l:%c:%m
  endif
  if executable('ag')
    set grepprg=ag\ --nogroup\ --column\ --smart-case\ --nocolor\ --follow
    set grepformat=%f:%l:%c:%m
  endif

  " vim file/folder management {{{
    " persistent undo
    if exists('+undofile')
      set undofile
      set undodir=~/.vim/.cache/undo
    endif

    " backups
    set backup
    set backupdir=~/.vim/.cache/backup

    " swap files
    set directory=~/.vim/.cache/swap
    set noswapfile

    call EnsureExists(expand ('~/.vim/.cache'))
    call EnsureExists(&undodir)
    call EnsureExists(&backupdir)
    call EnsureExists(&directory)
  "}}}

  let mapleader = ","
  let g:mapleader = ","
  let maplocalleader = "\\"
  let g:maplocalleader = "\\"
"}}}

" ui configuration {{{
  set showmatch                                       "automatically highlight matching braces/brackets/etc.
  set matchtime=2                                     "tens of a second to show matching parentheses
  set number
  set lazyredraw
  set laststatus=2
  set noshowmode
  set foldenable                                      "enable folds by default
  set foldmethod=syntax                               "fold via syntax of files
  set foldlevelstart=99                               "open all folds by default
  let g:xml_syntax_folding=1                          "enable xml folding
  " Don't screw up folds when inserting text that might affect them, until
  " leaving insert mode. Foldmethod is local to the window. Protect against
  " screwing up folding when switching between windows.
  augroup fold_fix
    autocmd InsertEnter * let b:oldfdm = &l:fdm | setlocal fdm=manual
    autocmd InsertLeave * let &l:fdm = b:oldfdm
  augroup END
  set cursorline
  augroup win_actions
    autocmd!
    autocmd WinLeave * setlocal nocursorline
    autocmd WinEnter * setlocal cursorline
  augroup END
  let &colorcolumn=s:settings.max_column
  if s:settings.enable_cursorcolumn
    set nocursorcolumn
    augroup win_actions_cursor
      autocmd!
      autocmd InsertLeave * setlocal nocursorcolumn
      autocmd WinLeave * setlocal nocursorcolumn
      autocmd InsertEnter * setlocal cursorcolumn
      autocmd WinEnter * setlocal cursorcolumn
    augroup END
  endif

  if has('conceal')
    set conceallevel=1
    set listchars+=conceal:Δ
  endif

  if has('gui_running')
    " open maximized
    set lines=999 columns=9999

    set guioptions+=t                                 "tear off menu items
    set guioptions-=T                                 "toolbar icons

    if s:is_macvim
      set gfn=Menlo\ for\ Powerline:h14
      "set gfn=Envy\ Code\ R\ for\ Powerline:h16
      set transparency=0
    endif

    if has('gui_gtk')
      set gfn=Ubuntu\ Mono\ 11
    endif
  else
    if $COLORTERM == 'gnome-terminal'
      set t_Co=256 "why you no tell me correct colors?!?!
    endif
    if $TERM_PROGRAM == 'iTerm.app'
      " different cursors for insert vs normal mode
      if exists('$TMUX')
        let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=1\x7\<Esc>\\"
        let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=0\x7\<Esc>\\"
      else
        let &t_SI = "\<Esc>]50;CursorShape=1\x7"
        let &t_EI = "\<Esc>]50;CursorShape=0\x7"
      endif
    endif
  endif
"}}}

" plugin/mapping configuration {{{
  if count(s:settings.plugin_groups, 'core') "{{{
    NeoBundle 'matchit.zip'
    NeoBundle 'bling/vim-airline' "{{{
      let g:airline#extensions#tmuxline#snapshot_file = "~/.tmux/tmux_snapshot.sh"
      let g:airline_theme = 'wombat'
      if !exists('g:airline_symbols')
        let g:airline_symbols = {}
      endif
      let g:airline_symbols.space = "\ua0"
      let g:airline_powerline_fonts = 1
      " old vim-powerline symbols
      let g:airline_left_sep = '⮀'
      let g:airline_left_alt_sep = '⮁'
      let g:airline_right_sep = '⮂'
      let g:airline_right_alt_sep = '⮃'
      let g:airline_symbols.branch = '⭠'
      let g:airline_symbols.readonly = '⭤'
      let g:airline_symbols.linenr = '⭡'
      let g:airline#extensions#tabline#enabled = 1
      let g:airline#extensions#tabline#left_sep=' '
      let g:airline#extensions#tabline#left_alt_sep='¦'
    "}}}
    if exists('$TMUX') "{{{
      NeoBundle 'edkolev/tmuxline.vim' "{{{
        let g:tmuxline_preset = 'full'
        let g:tmuxline_separators = {
          \ 'left' : '⮀',
          \ 'left_alt' : '⮁',
          \ 'right' : '⮂',
          \ 'right_alt' : '⮃',
          \ 'space' : "\ua0"
          \ }
      "}}}
    endif "}}}
    NeoBundle 'tpope/vim-surround'
    NeoBundle 'tpope/vim-repeat'
    NeoBundle 'tpope/vim-dispatch'
    NeoBundle 'tpope/vim-unimpaired' "{{{
      nmap <c-up> [e
      nmap <c-down> ]e
      vmap <c-up> [egv
      vmap <c-down> ]egv
    "}}}
    NeoBundle 'tpope/vim-eunuch'
    NeoBundle 'Shougo/vimproc.vim', {
      \ 'build': {
        \ 'mac': 'make -f make_mac.mak',
        \ 'unix': 'make -f make_unix.mak',
      \ },
    \ }
  endif "}}}
  if count(s:settings.plugin_groups, 'web') "{{{
    NeoBundleLazy 'groenewege/vim-less', {'autoload':{'filetypes':['less']}}
    NeoBundleLazy 'cakebaker/scss-syntax.vim', {'autoload':{'filetypes':['scss','sass']}}
    NeoBundleLazy 'hail2u/vim-css3-syntax', {'autoload':{'filetypes':['css','scss','sass']}}
    NeoBundleLazy 'ap/vim-css-color', {'autoload':{'filetypes':['css','scss','sass','less','styl']}}
    NeoBundleLazy 'othree/html5.vim', {'autoload':{'filetypes':['html']}}
    NeoBundleLazy 'wavded/vim-stylus', {'autoload':{'filetypes':['styl']}}
    NeoBundleLazy 'digitaltoad/vim-jade', {'autoload':{'filetypes':['jade']}}
    NeoBundleLazy 'juvenn/mustache.vim', {'autoload':{'filetypes':['mustache']}}
    NeoBundleLazy 'gregsexton/MatchTag', {'autoload':{'filetypes':['html','xml']}}
    NeoBundleLazy 'mattn/emmet-vim', {'autoload':{'filetypes':['html','xml','xsl','xslt','xsd','css','sass','scss','less','mustache']}} "{{{
      function! s:zen_html_tab()
        let line = getline('.')
        if match(line, '<.*>') < 0
          return "\<c-y>,"
        endif
        return "\<c-y>n"
      endfunction
      augroup web_group
        autocmd!
        autocmd FileType xml,xsl,xslt,xsd,css,sass,scss,less,mustache imap <buffer><tab> <c-y>,
        autocmd FileType html imap <buffer><expr><tab> <sid>zen_html_tab()
      augroup END
    "}}}
  endif "}}}
  if count(s:settings.plugin_groups, 'javascript') "{{{
    NeoBundleLazy 'marijnh/tern_for_vim', {
      \ 'autoload': { 'filetypes': ['javascript'] },
      \ 'build': {
        \ 'mac': 'npm install',
        \ 'unix': 'npm install',
      \ },
    \ }
    NeoBundleLazy 'pangloss/vim-javascript', {'autoload':{'filetypes':['javascript']}}
    NeoBundleLazy 'maksimr/vim-jsbeautify', {'autoload':{'filetypes':['javascript']}} "{{{
      nnoremap <leader>fjs :call JsBeautify()<cr>
    "}}}
    NeoBundleLazy 'leafgarland/typescript-vim', {'autoload':{'filetypes':['typescript']}}
    NeoBundleLazy 'kchmck/vim-coffee-script', {'autoload':{'filetypes':['coffee']}}
    NeoBundleLazy 'mmalecki/vim-node.js', {'autoload':{'filetypes':['javascript']}}
    NeoBundleLazy 'leshill/vim-json', {'autoload':{'filetypes':['javascript','json']}}
    NeoBundleLazy 'tpope/vim-jdaddy', {'autoload':{'filetypes':['javascript','json']}}
    NeoBundleLazy 'othree/javascript-libraries-syntax.vim', {'autoload':{'filetypes':['javascript','coffee','ls','typescript']}}
  endif "}}}
  if count(s:settings.plugin_groups, 'ruby') "{{{
    NeoBundle 'tpope/vim-rails'
    NeoBundle 'tpope/vim-bundler'
  endif "}}}
  if count(s:settings.plugin_groups, 'python') "{{{
    NeoBundleLazy 'klen/python-mode', {'autoload':{'filetypes':['python']}} "{{{
      let g:pymode_rope = 0
      let g:pymode_lint = 1
      let g:pymode_lint_ignore = "E501,C0301,C0302,C0110,C1001"
      let g:pymode_lint_checkers = ['pyflakes', 'pep8']
      let g:pymode_lint_write = 1
      let g:pymode_trim_whitespaces = 1
      let g:pymode_syntax = 1
      let g:pymode_syntax_all = 1
      let g:pymode_syntax_indent_errors = g:pymode_syntax_all
      let g:pymode_syntax_space_errors = g:pymode_syntax_all
      let g:pymode_folding = 0
    "}}}
    NeoBundleLazy 'davidhalter/jedi-vim', {'autoload':{'filetypes':['python']}} "{{{
      let g:jedi#popup_on_dot=0
    "}}}
  endif "}}}
  if count(s:settings.plugin_groups, 'scm') "{{{
    if executable('hg')
      NeoBundle 'bitbucket:ludovicchabant/vim-lawrencium'
    endif
    NeoBundle 'mhinz/vim-signify' "{{{
      let g:signify_update_on_bufenter=0
      let g:signify_vcs_list = [ 'git', 'hg' ]
    "}}}
    NeoBundle 'tpope/vim-fugitive' "{{{
      nnoremap <silent> <leader>gs :Gstatus<CR>
      nnoremap <silent> <leader>gd :Gdiff<CR>
      nnoremap <silent> <leader>gc :Gcommit<CR>
      nnoremap <silent> <leader>gb :Gblame<CR>
      nnoremap <silent> <leader>gl :Glog<CR>
      nnoremap <silent> <leader>gp :Git push<CR>
      nnoremap <silent> <leader>gw :Gwrite<CR>
      nnoremap <silent> <leader>gr :Gremove<CR>
      augroup fugitive
        autocmd!
        autocmd FileType gitcommit nmap <buffer> U :Git checkout -- <C-r><C-g><CR>
        autocmd BufReadPost fugitive://* set bufhidden=delete
      augroup END
    "}}}
    NeoBundleLazy 'gregsexton/gitv', {'depends':['tpope/vim-fugitive'], 'autoload':{'commands':'Gitv'}} "{{{
      nnoremap <silent> <leader>gv :Gitv<CR>
      nnoremap <silent> <leader>gV :Gitv!<CR>
    "}}}
  endif "}}}
  if count(s:settings.plugin_groups, 'autocomplete') "{{{
    NeoBundle 'honza/vim-snippets'
    if s:settings.autocomplete_method == 'ycm' "{{{
      NeoBundle 'Valloric/YouCompleteMe', {'vim_version':'7.3.584',
            \ 'build' : {
            \     'mac' : './install.sh --clang-completer --system-libclang',
            \     'unix' : './install.sh --clang-completer --system-libclang'
            \ }
            \}
      "{{{
        let g:ycm_complete_in_comments_and_strings=1
        let g:ycm_key_list_select_completion=['<C-n>', '<Down>']
        let g:ycm_key_list_previous_completion=['<C-p>', '<Up>']
        let g:ycm_filetype_blacklist={'unite': 1}
      "}}}
    "}}}
      NeoBundle 'SirVer/ultisnips' "{{{
        let g:UltiSnipsExpandTrigger="<tab>"
        let g:UltiSnipsJumpForwardTrigger="<tab>"
        let g:UltiSnipsJumpBackwardTrigger="<s-tab>"
        let g:UltiSnipsSnippetsDir='~/.vim/snippets'
      "}}}
    else
      NeoBundle 'Shougo/neosnippet-snippets'
      NeoBundle 'Shougo/neosnippet.vim' "{{{
        let g:neosnippet#snippets_directory='~/.vim/bundle/vim-snippets/snippets,~/.vim/snippets'
        let g:neosnippet#enable_snipmate_compatibility=1

        imap <expr><TAB> neosnippet#expandable_or_jumpable() ? "\<Plug>(neosnippet_expand_or_jump)" : (pumvisible() ? "\<C-n>" : "\<TAB>")
        smap <expr><TAB> neosnippet#expandable_or_jumpable() ? "\<Plug>(neosnippet_expand_or_jump)" : "\<TAB>"
        imap <expr><S-TAB> pumvisible() ? "\<C-p>" : ""
        smap <expr><S-TAB> pumvisible() ? "\<C-p>" : ""
      "}}}
      NeoBundle 'Shougo/context_filetype.vim'
      if s:settings.autocomplete_method == 'neocomplete' "{{{
        NeoBundleLazy 'Shougo/neocomplete.vim', {'autoload':{'insert':1}, 'vim_version':'7.3.885'} "{{{
          let g:neocomplete#enable_at_startup=1
          let g:neocomplete#data_directory='~/.vim/.cache/neocomplete'
        "}}}
      endif "}}}
      if s:settings.autocomplete_method == 'neocomplcache' "{{{
        NeoBundleLazy 'Shougo/neocomplcache.vim', {'autoload':{'insert':1}} "{{{
          let g:neocomplcache_enable_at_startup=1
          let g:neocomplcache_temporary_dir='~/.vim/.cache/neocomplcache'
          let g:neocomplcache_enable_fuzzy_completion=1
        "}}}
      endif "}}}
    endif
  endif "}}}
  if count(s:settings.plugin_groups, 'editing') "{{{
    NeoBundleLazy 'editorconfig/editorconfig-vim', {'autoload':{'insert':1}}
    NeoBundle 'tpope/vim-endwise'
    NeoBundle 'tpope/vim-speeddating'
    NeoBundle 'thinca/vim-visualstar'
    NeoBundle 'tomtom/tcomment_vim'
    NeoBundle 'terryma/vim-expand-region'
    NeoBundle 'terryma/vim-multiple-cursors'
    NeoBundle 'chrisbra/NrrwRgn'
    NeoBundleLazy 'godlygeek/tabular', {'autoload':{'commands':'Tabularize'}} "{{{
      nmap <Leader>a& :Tabularize /&<CR>
      vmap <Leader>a& :Tabularize /&<CR>
      nmap <Leader>a= :Tabularize /=<CR>
      vmap <Leader>a= :Tabularize /=<CR>
      nmap <Leader>a: :Tabularize /:<CR>
      vmap <Leader>a: :Tabularize /:<CR>
      nmap <Leader>a:: :Tabularize /:\zs<CR>
      vmap <Leader>a:: :Tabularize /:\zs<CR>
      nmap <Leader>a, :Tabularize /,<CR>
      vmap <Leader>a, :Tabularize /,<CR>
      nmap <Leader>a<Bar> :Tabularize /<Bar><CR>
      vmap <Leader>a<Bar> :Tabularize /<Bar><CR>
    "}}}
    NeoBundle 'jiangmiao/auto-pairs'
    NeoBundle 'justinmk/vim-sneak' "{{{
      let g:sneak#streak = 1
    "}}}
  endif "}}}
  if count(s:settings.plugin_groups, 'navigation') "{{{
    NeoBundle 'rking/ag.vim' "{{{
      let g:agprg="/usr/local/bin/ag --column"
    "}}}
    " DISABLED::NeoBundleLazy 'mbbill/undotree', {'autoload':{'commands':'UndotreeToggle'}} "{{{
    "   let g:undotree_SplitLocation='botright'
    "   let g:undotree_SetFocusWhenToggle=1
    "   nnoremap <silent> <F5> :UndotreeToggle<CR>
    " "}}}
    NeoBundleLazy 'sjl/gundo.vim', {'autoload':{'commands':'GundoToggle'}} "{{{
      let g:gundo_right=1
      nnoremap <silent> <F5> :GundoToggle<CR>
    "}}}
    NeoBundleLazy 'EasyGrep', {'autoload':{'commands':'GrepOptions'}} "{{{
      let g:EasyGrepRecursive=1
      let g:EasyGrepAllOptionsInExplorer=1
      let g:EasyGrepCommand=1
      nnoremap <leader>vo :GrepOptions<cr>
    "}}}
    NeoBundle 'kien/ctrlp.vim', { 'depends': 'tacahiroy/ctrlp-funky' } "{{{

      let g:ctrlp_clear_cache_on_exit=1
      let g:ctrlp_max_height=40
      let g:ctrlp_show_hidden=0
      let g:ctrlp_follow_symlinks=1
      let g:ctrlp_working_path_mode=0
      let g:ctrlp_max_files=20000
      let g:ctrlp_cache_dir='~/.vim/.cache/ctrlp'
      let g:ctrlp_reuse_window='startify'
      let g:ctrlp_extensions=['funky']
      if executable('ag')
        let g:ctrlp_user_command='ag %s -l --nocolor -g ""'
      endif

      nmap <Leader>p [ctrlp]
      nnoremap [ctrlp] <nop>

      nnoremap [ctrlp]p :CtrlPMRU<cr>
      nnoremap [ctrlp]t :CtrlPBufTag<cr>
      nnoremap [ctrlp]T :CtrlPTag<cr>
      nnoremap [ctrlp]l :CtrlPLine<cr>
      nnoremap [ctrlp]o :CtrlPFunky<cr>
      nnoremap [ctrlp]b :CtrlPBuffer<cr>
    "}}}
    NeoBundleLazy 'scrooloose/nerdtree', {'autoload':{'commands':['NERDTreeToggle','NERDTreeFind']}} "{{{
      let NERDTreeShowHidden=1
      let NERDTreeQuitOnOpen=0
      let NERDTreeShowLineNumbers=1
      let NERDTreeChDirMode=0
      let NERDTreeShowBookmarks=1
      let NERDTreeIgnore=['\.git','\.hg']
      let NERDTreeBookmarksFile='~/.vim/.cache/NERDTreeBookmarks'
      nnoremap <F2> :NERDTreeToggle<CR>
      nnoremap <F3> :NERDTreeFind<CR>
    "}}}
    NeoBundleLazy 'majutsushi/tagbar', {'autoload':{'commands':'TagbarToggle'}} "{{{
      let g:tagbar_autoclose=0
      let g:tagbar_autofocus=1
      nnoremap <silent> <F7> :TagbarToggle<CR>
    "}}}
  endif "}}}
  if count(s:settings.plugin_groups, 'unite') "{{{
    NeoBundle 'Shougo/neomru.vim'
    NeoBundle 'Shougo/unite.vim' "{{{
      let bundle = neobundle#get('unite.vim')
      function! bundle.hooks.on_source(bundle)
        call unite#filters#matcher_default#use(['matcher_fuzzy'])
        call unite#filters#sorter_default#use(['sorter_rank'])
        call unite#set_profile('files', 'smartcase', 1)
        call unite#custom#source('line,outline','matchers','matcher_fuzzy')
      endfunction

      let g:unite_data_directory='~/.vim/.cache/unite'
      let g:unite_enable_start_insert=1
      let g:unite_source_history_yank_enable=1
      let g:unite_source_rec_max_cache_files=5000
      let g:unite_prompt='» '

      if executable('ag')
        let g:unite_source_grep_command='ag'
        let g:unite_source_grep_default_opts='--nocolor --nogroup -S -C4'
        let g:unite_source_grep_recursive_opt=''
        let g:unite_source_rec_async_command='ag --nocolor --nogroup --hidden -g ""'
      elseif executable('ack')
        let g:unite_source_grep_command='ack'
        let g:unite_source_grep_default_opts='--no-heading --no-color -a -C4'
        let g:unite_source_grep_recursive_opt=''
      endif

      function! s:unite_settings()
        nmap <buffer> Q <plug>(unite_exit)
        nmap <buffer> <esc> <plug>(unite_exit)
        imap <buffer> <esc> <plug>(unite_exit)
      endfunction
      augroup unite
        autocmd!
        autocmd FileType unite call s:unite_settings()
      augroup END

      nmap <space> [unite]
      nnoremap [unite] <nop>

      nnoremap <silent> [unite]<space> :<C-u>Unite -toggle -auto-resize -buffer-name=mixed file_rec/async buffer file_mru bookmark<cr><c-u>
      nnoremap <silent> [unite]f :<C-u>Unite -toggle -auto-resize -buffer-name=files file<cr><c-u>
      nnoremap <silent> [unite]F :<C-u>Unite -toggle -auto-resize -buffer-name=files file_rec/async<cr><c-u>
      nnoremap <silent> [unite]r :<C-u>Unite -toggle -auto-resize -buffer-name=file_mru file_mru<cr><c-u>
      nnoremap <silent> [unite]R :<C-u>Unite -toggle -auto-resize -buffer-name=directory_mru directory_mru<cr><c-u>
      nnoremap <silent> [unite]y :<C-u>Unite -buffer-name=yanks history/yank<cr>
      nnoremap <silent> [unite]l :<C-u>Unite -auto-resize -buffer-name=line line<cr>
      nnoremap <silent> [unite]b :<C-u>Unite -auto-resize -buffer-name=buffers buffer<cr>
      nnoremap <silent> [unite]B :<C-u>Unite -auto-resize -buffer-name=bookmark bookmark<cr>
      nnoremap <silent> [unite]t :<C-u>Unite -auto-resize -buffer-name=tabs tab<cr>
      nnoremap <silent> [unite]/ :<C-u>Unite -no-quit -buffer-name=search grep:.<cr>
      nnoremap <silent> [unite]m :<C-u>Unite -auto-resize -buffer-name=mappings mapping<cr>
      nnoremap <silent> [unite]s :<C-u>Unite -quick-match buffer<cr>
    "}}}
    NeoBundleLazy 'osyo-manga/unite-airline_themes', {'autoload':{'unite_sources':'airline_themes'}} "{{{
      nnoremap <silent> [unite]a :<C-u>Unite -winheight=10 -auto-preview -buffer-name=airline_themes airline_themes<cr>
    "}}}
    NeoBundleLazy 'ujihisa/unite-colorscheme', {'autoload':{'unite_sources':'colorscheme'}} "{{{
      nnoremap <silent> [unite]c :<C-u>Unite -winheight=10 -auto-preview -buffer-name=colorschemes colorscheme<cr>
    "}}}
    NeoBundleLazy 'tsukkee/unite-tag', {'autoload':{'unite_sources':['tag','tag/file']}} "{{{
      nnoremap <silent> [unite]t :<C-u>Unite -auto-resize -buffer-name=tag tag tag/file<cr>
    "}}}
    NeoBundleLazy 'Shougo/unite-outline', {'autoload':{'unite_sources':'outline'}} "{{{
      nnoremap <silent> [unite]o :<C-u>Unite -auto-resize -buffer-name=outline outline<cr>
    "}}}
    NeoBundleLazy 'Shougo/unite-help.git', {'autoload':{'unite_sources':'help'}} "{{{
      nnoremap <silent> [unite]h :<C-u>Unite -auto-resize -buffer-name=help help<cr>
    "}}}
    NeoBundleLazy 'Shougo/junkfile.vim', {'autoload':{'commands':'JunkfileOpen','unite_sources':['junkfile','junkfile/new']}} "{{{
      let g:junkfile#directory=expand("~/.vim/.cache/junk")
      nnoremap <silent> [unite]j :<C-u>Unite -auto-resize -buffer-name=junk junkfile junkfile/new<cr>
    "}}}
    NeoBundleLazy 'thinca/vim-unite-history', {'autoload':{'unite_sources':['history/command', 'history/search']}}
    NeoBundleLazy 'ujihisa/unite-locate', {'autoload':{'unite_sources':'locate'}}
    NeoBundleLazy 'tacroe/unite-mark', {'autoload':{'unite_sources':'mark'}}
    NeoBundleLazy 'Shougo/vimfiler', {'autoload':{'commands':['VimFiler']}}
    NeoBundleLazy 'osyo-manga/unite-fold', {'autoload':{'unite_sources':'fold'}}
    NeoBundleLazy 'osyo-manga/unite-filetype', {'autoload':{'unite_sources':'filetype'}}
    NeoBundleLazy 'osyo-manga/unite-quickfix', {'autoload':{'unite_sources':['quickfix','location_list']}}
    NeoBundleLazy 'godlygeek/csapprox', {'autoload':{'commands':['CSApprox', 'CSApproxSnapshot']}}

    " unite menus {{{
      let g:unite_source_menu_menus = {}
      " menu prefix key (for all Unite menus) {{{
        nnoremap [menu] <Nop>
        nmap <Leader><Leader> [menu]
      " }}}
      " menus menu
        nnoremap <silent>[menu]u :Unite -silent -auto-resize menu<cr>

      " files and dirs menu {{{
        let g:unite_source_menu_menus.files = {
            \ 'description' : '          files & dirs
                \                                          ⌘ [space]o',
            \}
        let g:unite_source_menu_menus.files.command_candidates = [
            \['▷ open file                                                  ⌘ ,o',
                \'Unite -start-insert file'],
            \['▷ open more recently used files                              ⌘ ,m',
                \'Unite file_mru'],
            \['▷ open file with recursive search                            ⌘ ,O',
                \'Unite -start-insert file_rec/async'],
            \['▷ edit new file',
                \'Unite file/new'],
            \['▷ search directory',
                \'Unite directory'],
            \['▷ search recently used directories',
                \'Unite directory_mru'],
            \['▷ search directory with recursive search',
                \'Unite directory_rec/async'],
            \['▷ make new directory',
                \'Unite directory/new'],
            \['▷ change working directory',
                \'Unite -default-action=lcd directory'],
            \['▷ know current working directory',
                \'Unite output:pwd'],
            \['▷ junk files                                                 ⌘ ,d',
                \'Unite junkfile/new junkfile'],
            \['▷ save as root                                               ⌘ :w!!',
                \'exe "write !sudo tee % >/dev/null"'],
            \['▷ quick save                                                 ⌘ ,w',
                \'normal ,w'],
            \['▷ open vimfiler                                              ⌘ ,X',
                \'VimFiler'],
            \]
        nnoremap <silent>[menu]o :Unite -silent -winheight=17 -start-insert
                    \ menu:files<CR>
      " }}}
      "
      " file searching menu {{{
      let g:unite_source_menu_menus.grep = {
          \ 'description' : '           search files
              \                                          ⌘ [space]a',
          \}
      let g:unite_source_menu_menus.grep.command_candidates = [
          \['▷ grep (ag → ack → grep)                                     ⌘ ,a',
              \'Unite -no-quit grep'],
          \['▷ find',
              \'Unite find'],
          \['▷ locate',
              \'Unite -start-insert locate'],
          \['▷ vimgrep (very slow)',
              \'Unite vimgrep'],
          \]
      nnoremap <silent>[menu]a :Unite -silent menu:grep<CR>
      " }}}

      " buffers, tabs & windows menu {{{
      let g:unite_source_menu_menus.navigation = {
          \ 'description' : '     navigate by buffers, tabs & windows
              \                   ⌘ [space]b',
          \}
      let g:unite_source_menu_menus.navigation.command_candidates = [
          \['▷ buffers                                                    ⌘ ,b',
              \'Unite buffer'],
          \['▷ tabs                                                       ⌘ ,B',
              \'Unite tab'],
          \['▷ windows',
              \'Unite window'],
          \['▷ location list',
              \'Unite location_list'],
          \['▷ quickfix',
              \'Unite quickfix'],
          \['▷ resize windows                                             ⌘ C-C C-W',
              \'WinResizerStartResize'],
          \['▷ new vertical window                                        ⌘ ,v',
              \'vsplit'],
          \['▷ new horizontal window                                      ⌘ ,h',
              \'split'],
          \['▷ close current window                                       ⌘ ,k',
              \'close'],
          \['▷ toggle quickfix window                                     ⌘ ,q',
              \'normal ,q'],
          \['▷ zoom                                                       ⌘ ,z',
              \'ZoomWinTabToggle'],
          \['▷ delete buffer                                              ⌘ ,K',
              \'bd'],
          \]
      nnoremap <silent>[menu]b :Unite -silent menu:navigation<CR>
      " }}}

      " buffer internal searching menu {{{
      let g:unite_source_menu_menus.searching = {
          \ 'description' : '      searchs inside the current buffer
              \                     ⌘ [space]f',
          \}
      let g:unite_source_menu_menus.searching.command_candidates = [
          \['▷ search line                                                ⌘ ,f',
              \'Unite -auto-preview -start-insert line'],
          \['▷ search word under the cursor                               ⌘ [space]8',
              \'UniteWithCursorWord -no-split -auto-preview line'],
          \['▷ search outlines & tags (ctags)                             ⌘ ,t',
              \'Unite -vertical -winwidth=40 -direction=topleft -toggle outline'],
          \['▷ search marks',
              \'Unite -auto-preview mark'],
          \['▷ search folds',
              \'Unite -vertical -winwidth=30 -auto-highlight fold'],
          \['▷ search changes',
              \'Unite change'],
          \['▷ search jumps',
              \'Unite jump'],
          \['▷ search undos',
              \'Unite undo'],
          \['▷ search tasks                                               ⌘ ,;',
              \'Unite -toggle grep:%::FIXME|TODO|NOTE|XXX|COMBAK|@todo'],
          \]
      nnoremap <silent>[menu]f :Unite -silent menu:searching<CR>
      " }}}

      " yanks, registers & history menu {{{
      let g:unite_source_menu_menus.registers = {
          \ 'description' : '      yanks, registers & history
              \                            ⌘ [space]i',
          \}
      let g:unite_source_menu_menus.registers.command_candidates = [
          \['▷ yanks                                                      ⌘ ,i',
              \'Unite history/yank'],
          \['▷ commands       (history)                                   ⌘ q:',
              \'Unite history/command'],
          \['▷ searches       (history)                                   ⌘ q/',
              \'Unite history/search'],
          \['▷ registers',
              \'Unite register'],
          \['▷ messages',
              \'Unite output:messages'],
          \['▷ undo tree      (gundo)                                     ⌘ ,u',
              \'GundoToggle'],
          \]
      nnoremap <silent>[menu]i :Unite -silent menu:registers<CR>
      " }}}

      " spelling menu {{{
      let g:unite_source_menu_menus.spelling = {
          \ 'description' : '       spell checking
              \                                        ⌘ [space]s',
          \}
      let g:unite_source_menu_menus.spelling.command_candidates = [
          \['▷ spell checking in English                                  ⌘ ,se',
              \'setlocal spell spelllang=en'],
          \['▷ turn off spell checking                                    ⌘ ,so',
              \'setlocal nospell'],
          \['▷ jumps to next bad spell word and show suggestions          ⌘ ,sc',
              \'normal ,sc'],
          \['▷ jumps to next bad spell word                               ⌘ ,sn',
              \'normal ,sn'],
          \['▷ suggestions                                                ⌘ ,sp',
              \'normal ,sp'],
          \['▷ add word to dictionary                                     ⌘ ,sa',
              \'normal ,sa'],
          \]
      nnoremap <silent>[menu]s :Unite -silent menu:spelling<CR>
      " }}}

      " text edition menu {{{
      let g:unite_source_menu_menus.text = {
          \ 'description' : '           text edition
              \                                          ⌘ [space]e',
          \}
      let g:unite_source_menu_menus.text.command_candidates = [
          \['▷ toggle search results highlight                            ⌘ ,eq',
              \'set invhlsearch'],
          \['▷ toggle line numbers                                        ⌘ ,l',
              \'call ToggleRelativeAbsoluteNumber()'],
          \['▷ toggle wrapping                                            ⌘ ,ew',
              \'call ToggleWrap()'],
          \['▷ show hidden chars                                          ⌘ ,eh',
              \'set list!'],
          \['▷ toggle fold                                                ⌘ /',
              \'normal za'],
          \['▷ open all folds                                             ⌘ zR',
              \'normal zR'],
          \['▷ close all folds                                            ⌘ zM',
              \'normal zM'],
          \['▷ copy to the clipboard                                      ⌘ ,y',
              \'normal ,y'],
          \['▷ paste from the clipboard                                   ⌘ ,p',
              \'normal ,p'],
          \['▷ toggle paste mode                                          ⌘ ,P',
              \'normal ,P'],
          \['▷ remove trailing whitespaces                                ⌘ ,et',
              \'normal ,et'],
          \['▷ text statistics                                            ⌘ ,es',
              \'Unite output:normal\ ,es -no-cursor-line'],
          \['▷ show word frequency                                        ⌘ ,ef',
              \'Unite output:WordFrequency'],
          \['▷ show available digraphs',
              \'digraphs'],
          \['▷ insert lorem ipsum text',
              \'exe "Loremipsum" input("numero de palabras: ")'],
          \['▷ show current char info                                     ⌘ ga',
              \'normal ga'],
          \]
      nnoremap <silent>[menu]e :Unite -silent -winheight=20 menu:text <CR>
      " }}}

      " neobundle menu {{{
      let g:unite_source_menu_menus.neobundle = {
          \ 'description' : '      plugins administration with neobundle
              \                 ⌘ [space]n',
          \}
      let g:unite_source_menu_menus.neobundle.command_candidates = [
          \['▷ neobundle',
              \'Unite neobundle'],
          \['▷ neobundle log',
              \'Unite neobundle/log'],
          \['▷ neobundle lazy',
              \'Unite neobundle/lazy'],
          \['▷ neobundle update',
              \'Unite neobundle/update'],
          \['▷ neobundle update:all',
              \'Unite neobundle/update:all'],
          \['▷ neobundle search',
              \'Unite neobundle/search'],
          \['▷ neobundle install',
              \'Unite neobundle/install'],
          \['▷ neobundle check',
              \'Unite -no-empty output:NeoBundleCheck'],
          \['▷ neobundle docs',
              \'Unite output:NeoBundleDocs'],
          \['▷ neobundle clean',
              \'NeoBundleClean'],
          \['▷ neobundle list',
              \'Unite output:NeoBundleList'],
          \['▷ neobundle direct edit',
              \'NeoBundleDirectEdit'],
          \]
      nnoremap <silent>[menu]n :Unite -silent -start-insert menu:neobundle<CR>
      " }}}

      " git menu {{{
      let g:unite_source_menu_menus.git = {
          \ 'description' : '            admin git repositories
              \                                ⌘ [space]g',
          \}
      let g:unite_source_menu_menus.git.command_candidates = [
          \['▷ git viewer             (gitv)                              ⌘ ,gv',
              \'normal ,gv'],
          \['▷ git viewer - buffer    (gitv)                              ⌘ ,gV',
              \'normal ,gV'],
          \['▷ git status             (fugitive)                          ⌘ ,gs',
              \'Gstatus'],
          \['▷ git diff               (fugitive)                          ⌘ ,gd',
              \'Gdiff'],
          \['▷ git commit             (fugitive)                          ⌘ ,gc',
              \'Gcommit'],
          \['▷ git log                (fugitive)                          ⌘ ,gl',
              \'exe "silent Glog | Unite -no-quit quickfix"'],
          \['▷ git log - all          (fugitive)                          ⌘ ,gL',
              \'exe "silent Glog -all | Unite -no-quit quickfix"'],
          \['▷ git blame              (fugitive)                          ⌘ ,gb',
              \'Gblame'],
          \['▷ git add/stage          (fugitive)                          ⌘ ,gw',
              \'Gwrite'],
          \['▷ git checkout           (fugitive)                          ⌘ ,go',
              \'Gread'],
          \['▷ git rm                 (fugitive)                          ⌘ ,gR',
              \'Gremove'],
          \['▷ git mv                 (fugitive)                          ⌘ ,gm',
              \'exe "Gmove " input("destino: ")'],
          \['▷ git push               (fugitive, buffer output)           ⌘ ,gp',
              \'Git! push'],
          \['▷ git pull               (fugitive, buffer output)           ⌘ ,gP',
              \'Git! pull'],
          \['▷ git command            (fugitive, buffer output)           ⌘ ,gi',
              \'exe "Git! " input("comando git: ")'],
          \['▷ git edit               (fugitive)                          ⌘ ,gE',
              \'exe "command Gedit " input(":Gedit ")'],
          \['▷ git grep               (fugitive)                          ⌘ ,gg',
              \'exe "silent Ggrep -i ".input("Pattern: ") | Unite -no-quit quickfix'],
          \['▷ git grep - messages    (fugitive)                          ⌘ ,ggm',
              \'exe "silent Glog --grep=".input("Pattern: ")." | Unite -no-quit quickfix"'],
          \['▷ git grep - text        (fugitive)                          ⌘ ,ggt',
              \'exe "silent Glog -S".input("Pattern: ")." | Unite -no-quit quickfix"'],
          \['▷ git init                                                   ⌘ ,gn',
              \'Unite output:echo\ system("git\ init")'],
          \['▷ git cd                 (fugitive)',
              \'Gcd'],
          \['▷ git lcd                (fugitive)',
              \'Glcd'],
          \['▷ git browse             (fugitive)                          ⌘ ,gB',
              \'Gbrowse'],
          \['▷ github dashboard       (github-dashboard)                  ⌘ ,gD',
              \'exe "GHD! " input("Username: ")'],
          \['▷ github activity        (github-dashboard)                  ⌘ ,gA',
              \'exe "GHA! " input("Username or repository: ")'],
          \['▷ github issues & PR                                         ⌘ ,gS',
              \'normal ,gS'],
          \]
      nnoremap <silent>[menu]g :Unite -silent -winheight=29 -start-insert menu:git<CR>
      " }}}

      " code menu {{{
      let g:unite_source_menu_menus.code = {
          \ 'description' : '           code tools
              \                                            ⌘ [space]p',
          \}
      let g:unite_source_menu_menus.code.command_candidates = [
          \['▷ run python code                            (pymode)        ⌘ ,r',
              \'PymodeRun'],
          \['▷ show docs for the current word             (pymode)        ⌘ K',
              \'normal K'],
          \['▷ insert a breakpoint                        (pymode)        ⌘ ,B',
              \'normal ,B'],
          \['▷ pylint check                               (pymode)        ⌘ ,n',
              \'PymodeLint'],
          \['▷ run with python2 in tmux panel             (vimux)         ⌘ ,rr',
              \'normal ,rr'],
          \['▷ run with python3 in tmux panel             (vimux)         ⌘ ,r3',
              \'normal ,r3'],
          \['▷ run with python2 & time in tmux panel      (vimux)         ⌘ ,rt',
              \'normal ,rt'],
          \['▷ run with pypy & time in tmux panel         (vimux)         ⌘ ,rp',
              \'normal ,rp'],
          \['▷ command prompt to run in a tmux panel      (vimux)         ⌘ ,rc',
              \'VimuxPromptCommand'],
          \['▷ repeat last command                        (vimux)         ⌘ ,rl',
              \'VimuxRunLastCommand'],
          \['▷ stop command execution in tmux panel       (vimux)         ⌘ ,rs',
              \'VimuxInterruptRunner'],
          \['▷ inspect tmux panel                         (vimux)         ⌘ ,ri',
              \'VimuxInspectRunner'],
          \['▷ close tmux panel                           (vimux)         ⌘ ,rq',
              \'VimuxCloseRunner'],
          \['▷ sort imports                               (isort)',
              \'Isort'],
          \['▷ go to definition                           (pymode-rope)   ⌘ C-C g',
              \'call pymode#rope#goto_definition()'],
          \['▷ find where a function is used              (pymode-rope)   ⌘ C-C f',
              \'call pymode#rope#find_it()'],
          \['▷ show docs for current word                 (pymode-rope)   ⌘ C-C d',
              \'call pymode#rope#show_doc()'],
          \['▷ reorganize imports                         (pymode-rope)   ⌘ C-C r o',
              \'call pymode#rope#organize_imports()'],
          \['▷ refactorize - rename                       (pymode-rope)   ⌘ C-C r r',
              \'call pymode#rope#rename()'],
          \['▷ refactorize - inline                       (pymode-rope)   ⌘ C-C r i',
              \'call pymode#rope#inline()'],
          \['▷ refactorize - move                         (pymode-rope)   ⌘ C-C r v',
              \'call pymode#rope#move()'],
          \['▷ refactorize - use function                 (pymode-rope)   ⌘ C-C r u',
              \'call pymode#rope#use_function()'],
          \['▷ refactorize - change signature             (pymode-rope)   ⌘ C-C r s',
              \'call pymode#rope#signature()'],
          \['▷ refactorize - rename current module        (pymode-rope)   ⌘ C-C r 1 r',
              \'PymodeRopeRenameModule'],
          \['▷ refactorize - module to package            (pymode-rope)   ⌘ C-C r 1 p',
              \'PymodeRopeModuleToPackage'],
          \['▷ syntastic toggle                           (syntastic)',
              \'SyntasticToggleMode'],
          \['▷ syntastic check & errors                   (syntastic)     ⌘ ,N',
              \'normal ,N'],
          \['▷ list virtualenvs                           (virtualenv)',
              \'Unite output:VirtualEnvList'],
          \['▷ activate virtualenv                        (virtualenv)',
              \'VirtualEnvActivate'],
          \['▷ deactivate virtualenv                      (virtualenv)',
              \'VirtualEnvDeactivate'],
          \['▷ run coverage2                              (coveragepy)',
              \'call system("coverage2 run ".bufname("%")) | Coveragepy report'],
          \['▷ run coverage3                              (coveragepy)',
              \'call system("coverage3 run ".bufname("%")) | Coveragepy report'],
          \['▷ toggle coverage report                     (coveragepy)',
              \'Coveragepy session'],
          \['▷ toggle coverage marks                      (coveragepy)',
              \'Coveragepy show'],
          \['▷ coffeewatch                                (coffeescript)  ⌘ ,rw',
              \'CoffeeWatch vert'],
          \['▷ count lines of code',
              \'Unite -default-action= output:call\\ LinesOfCode()'],
          \['▷ toggle indent lines                                        ⌘ ,L',
              \'IndentLinesToggle'],
          \]
      nnoremap <silent>[menu]p :Unite -silent -winheight=42 menu:code<CR>
      " }}}

      " markdown menu {{{
      let g:unite_source_menu_menus.markdown = {
          \ 'description' : '       preview markdown extra docs
              \                           ⌘ [space]k',
          \}
      let g:unite_source_menu_menus.markdown.command_candidates = [
          \['▷ preview',
              \'Me'],
          \['▷ refresh',
              \'Mer'],
          \]
      nnoremap <silent>[menu]k :Unite -silent menu:markdown<CR>
      " }}}

      " bookmarks menu {{{
      let g:unite_source_menu_menus.bookmarks = {
          \ 'description' : '      bookmarks
              \                                             ⌘ [space]m',
          \}
      let g:unite_source_menu_menus.bookmarks.command_candidates = [
          \['▷ open bookmarks',
              \'Unite bookmark:*'],
          \['▷ add bookmark',
              \'UniteBookmarkAdd'],
          \]
      nnoremap <silent>[menu]m :Unite -silent menu:bookmarks<CR>
      " }}}

      " colorv menu {{{
      function! GetColorFormat()
          let formats = {'r' : 'RGB',
                        \'n' : 'NAME',
                        \'s' : 'HEX',
                        \'ar': 'RGBA',
                        \'pr': 'RGBP',
                        \'pa': 'RGBAP',
                        \'m' : 'CMYK',
                        \'l' : 'HSL',
                        \'la' : 'HSLA',
                        \'h' : 'HSV',
                        \}
          let formats_menu = ["\n"]
          for [k, v] in items(formats)
              call add(formats_menu, "  ".k."\t".v."\n")
          endfor
          let fsel = get(formats, input('Choose a format: '.join(formats_menu).'? '))
          return fsel
      endfunction

      function! GetColorMethod()
          let methods = {
                         \'h' : 'Hue',
                         \'s' : 'Saturation',
                         \'v' : 'Value',
                         \'m' : 'Monochromatic',
                         \'a' : 'Analogous',
                         \'3' : 'Triadic',
                         \'4' : 'Tetradic',
                         \'n' : 'Neutral',
                         \'c' : 'Clash',
                         \'q' : 'Square',
                         \'5' : 'Five-Tone',
                         \'6' : 'Six-Tone',
                         \'2' : 'Complementary',
                         \'p' : 'Split-Complementary',
                         \'l' : 'Luma',
                         \'g' : 'Turn-To',
                         \}
          let methods_menu = ["\n"]
          for [k, v] in items(methods)
              call add(methods_menu, "  ".k."\t".v."\n")
          endfor
          let msel = get(methods, input('Choose a method: '.join(methods_menu).'? '))
          return msel
      endfunction

      let g:unite_source_menu_menus.colorv = {
          \ 'description' : '         color management
              \                                      ⌘ [space]c',
          \}
      let g:unite_source_menu_menus.colorv.command_candidates = [
          \['▷ open colorv                                                ⌘ ,cv',
              \'ColorV'],
          \['▷ open colorv with the color under the cursor                ⌘ ,cw',
              \'ColorVView'],
          \['▷ preview colors                                             ⌘ ,cpp',
              \'ColorVPreview'],
          \['▷ color picker                                               ⌘ ,cd',
              \'ColorVPicker'],
          \['▷ edit the color under the cursor                            ⌘ ,ce',
              \'ColorVEdit'],
          \['▷ edit the color under the cursor (and all the concurrences) ⌘ ,cE',
              \'ColorVEditAll'],
          \['▷ insert a color                                             ⌘ ,cii',
              \'exe "ColorVInsert " .GetColorFormat()'],
          \['▷ color list relative to the current                         ⌘ ,cgh',
              \'exe "ColorVList " .GetColorMethod() "
              \ ".input("number of colors? (optional): ")
              \ " ".input("number of steps?  (optional): ")'],
          \['▷ show colors list (Web W3C colors)                          ⌘ ,cn',
              \'ColorVName'],
          \['▷ choose color scheme (ColourLovers, Kuler)                  ⌘ ,css',
              \'ColorVScheme'],
          \['▷ show favorite color schemes                                ⌘ ,csf',
              \'ColorVSchemeFav'],
          \['▷ new color scheme                                           ⌘ ,csn',
              \'ColorVSchemeNew'],
          \['▷ create hue gradation between two colors',
              \'exe "ColorVTurn2 " " ".input("Color 1 (hex): ")
              \" ".input("Color 2 (hex): ")'],
          \]
      nnoremap <silent>[menu]c :Unite -silent menu:colorv<CR>
      " }}}

      " vim menu {{{
      let g:unite_source_menu_menus.vim = {
          \ 'description' : '            vim
              \                                                   ⌘ [space]v',
          \}
      let g:unite_source_menu_menus.vim.command_candidates = [
          \['▷ choose colorscheme',
              \'Unite colorscheme -auto-preview'],
          \['▷ mappings',
              \'Unite mapping -start-insert'],
          \['▷ edit configuration file (vimrc)',
              \'edit $MYVIMRC'],
          \['▷ choose filetype',
              \'Unite -start-insert filetype'],
          \['▷ vim help',
              \'Unite -start-insert help'],
          \['▷ vim commands',
              \'Unite -start-insert command'],
          \['▷ vim functions',
              \'Unite -start-insert function'],
          \['▷ vim runtimepath',
              \'Unite -start-insert runtimepath'],
          \['▷ vim command output',
              \'Unite output'],
          \['▷ unite sources',
              \'Unite source'],
          \['▷ kill process',
              \'Unite -default-action=sigkill -start-insert process'],
          \['▷ launch executable (dmenu like)',
              \'Unite -start-insert launcher'],
          \]
      nnoremap <silent>[menu]v :Unite menu:vim -silent -start-insert<CR>
      " }}}
    " }}}
  endif "}}}
  if count(s:settings.plugin_groups, 'indents') "{{{
    NeoBundle 'nathanaelkane/vim-indent-guides' "{{{
      let g:indent_guides_start_level=1
      let g:indent_guides_guide_size=1
      let g:indent_guides_enable_on_vim_startup=0
      let g:indent_guides_color_change_percent=3
      if !has('gui_running')
        let g:indent_guides_auto_colors=0
        function! s:indent_set_console_colors()
          hi IndentGuidesOdd ctermbg=235
          hi IndentGuidesEven ctermbg=236
        endfunction
        augroup indent
          autocmd!
          autocmd VimEnter,Colorscheme * call s:indent_set_console_colors()
        augroup END
      endif
    "}}}
  endif "}}}
  if count(s:settings.plugin_groups, 'osx') "{{{
    NeoBundle 'rizzatti/funcoo.vim'
    NeoBundle 'rizzatti/dash.vim' "{{{
      let g:dash_map = {
        \ 'python' : 'python2',
        \ 'perl' : 'perl'
        \ }
      nmap <silent> <localleader>d <Plug>DashSearch
    "}}}
  endif "}}}
  if count(s:settings.plugin_groups, 'misc') "{{{
    if exists('$TMUX') "{{{
      NeoBundle 'christoomey/vim-tmux-navigator'
      NeoBundle 'benmills/vimux'
    endif "}}}
    NeoBundle 'kana/vim-vspec'
    NeoBundleLazy 'tpope/vim-scriptease', {'autoload':{'filetypes':['vim']}}
    NeoBundleLazy 'tpope/vim-markdown', {'autoload':{'filetypes':['markdown']}}
    if executable('redcarpet') && executable('instant-markdown-d') "{{{
      NeoBundleLazy 'suan/vim-instant-markdown', {'autoload':{'filetypes':['markdown']}}
    endif "}}}
    NeoBundleLazy 'guns/xterm-color-table.vim', {'autoload':{'commands':'XtermColorTable'}}
    NeoBundle 'chrisbra/vim_faq'
    NeoBundle 'vimwiki'
    NeoBundle 'bufkill.vim'
    NeoBundle 'vim-scripts/perl-support.vim'
    NeoBundle 'chrisbra/csv.vim'
    NeoBundle 'junegunn/goyo.vim'
    NeoBundle 'amix/vim-zenroom2'
    NeoBundleLazy 'vimoutliner/vimoutliner', {'autoload':{'filetypes':['vo_base']}}
    NeoBundle 'vim-scripts/DrawIt'
    NeoBundle 'regedarek/ZoomWin'
    NeoBundle 'myusuf3/numbers.vim'
    NeoBundle 'sjl/splice.vim'
    NeoBundle 'tpope/vim-characterize'
    NeoBundle 'Shougo/wildfire.vim'
    NeoBundle 'laurentgoudet/vim-howdoi'
    NeoBundle 't9md/vim-chef'
    NeoBundleLazy 'dag/vim-fish', {'autoload':{'filetypes':['fish']}}
    NeoBundle 't9md/vim-choosewin' "{{{
      nmap  -  <Plug>(choosewin)
      let g:choosewin_overlay_enable = 1
    "}}}
    NeoBundle 'fmoralesc/vim-pad' "{{{
      let g:pad_dir = "~/Dropbox/Notational Data"
      let g:pad_use_default_mappings = 0
      let g:pad_search_backend = 'ack'
      let g:pad_open_in_split = 0
      nmap <leader>nl <Plug>ListPads
      nmap <leader>no <Plug>OpenPad
      nmap <leader>ns <Plug>SearchPads
    "}}}
    NeoBundle 'mhinz/vim-startify' "{{{
      let g:startify_session_dir = '~/.vim/.cache/sessions'
      let g:startify_change_to_vcs_root = 1
      let g:startify_show_sessions = 1
      nnoremap <F1> :Startify<cr>
    "}}}
    NeoBundle 'scrooloose/syntastic' "{{{
      let g:syntastic_error_symbol = '✗'
      let g:syntastic_style_error_symbol = '✠'
      let g:syntastic_warning_symbol = '∆'
      let g:syntastic_style_warning_symbol = '≈'
    "}}}
    NeoBundleLazy 'mattn/gist-vim', { 'depends': 'mattn/webapi-vim', 'autoload': { 'commands': 'Gist' } } "{{{
      let g:gist_post_private=1
      let g:gist_show_privates=1
    "}}}
    NeoBundleLazy 'Shougo/vimshell.vim', {'autoload':{'commands':[ 'VimShell', 'VimShellInteractive', 'VimShellPop' ]}} "{{{
      if s:is_macvim
        let g:vimshell_editor_command='mvim'
      else
        let g:vimshell_editor_command='vim'
      endif
      let g:vimshell_right_prompt='getcwd()'
      let g:vimshell_temporary_directory=expand('~/.vim/.cache/vimshell')
      let g:vimshell_vimshrc_path=expand('~/.vim/vimshrc')

      nnoremap <leader>c :VimShell -split<cr>
      nnoremap <leader>cc :VimShell -split<cr>
      nnoremap <leader>cn :VimShellInteractive node<cr>
      nnoremap <leader>cl :VimShellInteractive lua<cr>
      nnoremap <leader>cr :VimShellInteractive irb<cr>
      nnoremap <leader>cp :VimShellInteractive python<cr>
    "}}}
    NeoBundleLazy 'zhaocai/GoldenView.Vim', {'autoload':{'mappings':['<Plug>ToggleGoldenViewAutoResize']}} "{{{
      let g:goldenview__enable_default_mapping=0
      nmap <F4> <Plug>ToggleGoldenViewAutoResize
    "}}}
    nnoremap <leader>nbu :Unite neobundle/update:all -vertical -no-start-insert<cr>
    nmap <leader>h <Plug>Howdoi
  endif "}}}
"}}}

" mappings {{{
  " formatting shortcuts
  nmap <leader>fef :call Preserve("normal gg=G")<CR>
  nmap <leader>f$ :call StripTrailingWhitespace()<CR>
  nmap <leader>j :%! python -m json.tool<CR>
  vmap <leader>s :sort<cr>
  vmap v <Plug>(expand_region_expand)
  vmap <C-v> <Plug>(expand_region_shrink)

  nnoremap <leader>w :w<cr>

  " toggle paste
  map <F6> :set invpaste<CR>:set paste?<CR>

  " remap arrow keys
  nnoremap <left> :bprev<CR>
  nnoremap <right> :bnext<CR>
  nnoremap <up> :tabnext<CR>
  nnoremap <down> :tabprev<CR>

  " smash escape
  inoremap jk <esc>
  inoremap kj <esc>

  " change cursor position in insert mode
  inoremap <C-h> <left>
  inoremap <C-l> <right>

  inoremap <C-u> <C-g>u<C-u>

  " Mappings for VisualDrag plugin
  runtime plugin/dragvisuals.vim

  vmap  <expr>  <S-left>   DVB_Drag('left')
  vmap  <expr>  <S-right>  DVB_Drag('right')
  vmap  <expr>  <S-down>   DVB_Drag('down')
  vmap  <expr>  <S-up>     DVB_Drag('up')
  vmap  <expr>  D          DVB_Duplicate()

  if mapcheck('<space>/') == ''
    nnoremap <space>/ :vimgrep //gj **/*<left><left><left><left><left><left><left><left>
  endif

  " sane regex {{{
    nnoremap / /\v
    vnoremap / /\v
    nnoremap ? ?\v
    vnoremap ? ?\v
    nnoremap :s/ :s/\v
  " }}}

  " command-line window {{{
    nnoremap q: q:i
    nnoremap q/ q/i
    nnoremap q? q?i
  " }}}

  " folds {{{
    nnoremap zr zr:echo &foldlevel<cr>
    nnoremap zm zm:echo &foldlevel<cr>
    nnoremap zR zR:echo &foldlevel<cr>
    nnoremap zM zM:echo &foldlevel<cr>
    nnoremap <leader><Space> za
  " }}}

  " screen line scroll
  nnoremap <silent> j gj
  nnoremap <silent> k gk

  " auto center {{{
    nnoremap <silent> n nzz
    nnoremap <silent> N Nzz
    nnoremap <silent> * *zz
    nnoremap <silent> # #zz
    nnoremap <silent> g* g*zz
    nnoremap <silent> g# g#zz
    nnoremap <silent> <C-o> <C-o>zz
    nnoremap <silent> <C-i> <C-i>zz
  "}}}

  " reselect visual block after indent
  vnoremap < <gv
  vnoremap > >gv

  " reselect last paste
  nnoremap <expr> gp '`[' . strpart(getregtype(), 0, 1) . '`]'

  " find current word in quickfix
  nnoremap <leader>fw :execute "vimgrep ".expand("<cword>")." %"<cr>:copen<cr>

  " find last search in quickfix
  nnoremap <leader>ff :execute 'vimgrep /'.@/.'/g %'<cr>:copen<cr>

 " shortcuts for window handling  {{{
    nnoremap <leader>v <C-w>v<C-w>l
    nnoremap <leader>s <C-w>s
    nmap <leader>z <Plug>ZoomWin
    nnoremap <leader>vsa :vert sba<cr>
    nnoremap <C-h> <C-w>h
    nnoremap <C-j> <C-w>j
    nnoremap <C-k> <C-w>k
    nnoremap <C-l> <C-w>l
  "}}}

  " tab shortcuts
  map <leader>tn :tabnew<CR>
  map <leader>tc :tabclose<CR>

  " make Y consistent with C and D. See :help Y.
  nnoremap Y y$

  " hide annoying quit message
  nnoremap <C-c> <C-c>:echo<cr>

  " window killer
  nnoremap <silent> Q :call CloseWindowOrKillBuffer()<cr>

  " quick buffer open
  nnoremap gb :ls<cr>:e #

  if neobundle#is_sourced('vim-dispatch')
    nnoremap <leader>tag :Dispatch ctags -R<cr>
  endif

  " Open markdown files in Marked
  nnoremap <leader>md :silent !open -a Marked.app '%:p'<cr>

  " general
  nmap <leader>l :set list! list?<cr>
  nnoremap <BS> :set hlsearch! hlsearch?<cr>

  map <F10> :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<'
        \ . synIDattr(synID(line("."),col("."),0),"name") . "> lo<"
        \ . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<CR>

  " helpers for profiling {{{
    nnoremap <silent> <leader>DD :exe ":profile start profile.log"<cr>:exe ":profile func *"<cr>:exe ":profile file *"<cr>
    nnoremap <silent> <leader>DP :exe ":profile pause"<cr>
    nnoremap <silent> <leader>DC :exe ":profile continue"<cr>
    nnoremap <silent> <leader>DQ :exe ":profile pause"<cr>:noautocmd qall!<cr>
  "}}}
"}}}

" commands {{{
  command! -bang Q q<bang>
  command! -bang QA qa<bang>
  command! -bang Qa qa<bang>
"}}}

" autocmd {{{
  " go back to previous position of cursor if any
  augroup autocmd_group
    autocmd!
    autocmd BufReadPost *
      \ if line("'\"") > 0 && line("'\"") <= line("$") |
      \  exe 'normal! g`"zvzz' |
      \ endif

    autocmd FileType css,scss setlocal foldmethod=marker foldmarker={,}
    autocmd FileType python setlocal foldmethod=indent tabstop=8 expandtab shiftwidth=4 softtabstop=4
    autocmd FileType markdown setlocal nolist
    autocmd FileType vo_base setlocal nonumber
    autocmd FileType make setlocal noexpandtab
    autocmd FileType vim setlocal foldmethod=marker keywordprg=:help
    autocmd FileWritePre    * :call StripTrailingWhitespace()
    autocmd FileAppendPre   * :call StripTrailingWhitespace()
    autocmd FilterWritePre  * :call StripTrailingWhitespace()
    autocmd BufWritePre     * :call StripTrailingWhitespace()
  augroup END
"}}}

" color schemes {{{
  NeoBundle 'altercation/vim-colors-solarized' "{{{
    let g:solarized_termcolors=256
    let g:solarized_termtrans=1
  "}}}
  NeoBundle 'nanotech/jellybeans.vim'
  NeoBundle 'tomasr/molokai'
  NeoBundle 'chriskempson/vim-tomorrow-theme'
  NeoBundle 'chriskempson/base16-vim'
  NeoBundle 'w0ng/vim-hybrid'
  NeoBundle 'sjl/badwolf'
  NeoBundle 'Lokaltog/vim-distinguished'
  NeoBundle 'tpope/vim-vividchalk'
  NeoBundle 'jnurmine/Zenburn'
  NeoBundle 'zeis/vim-kolor' "{{{
    let g:kolor_underlined=1
  "}}}

  exec 'colorscheme '.s:settings.colorscheme
"}}}

" finish loading {{{
  if exists('g:dotvim_settings.disabled_plugins')
    for plugin in g:dotvim_settings.disabled_plugins
      exec 'NeoBundleDisable '.plugin
    endfor
  endif

  filetype plugin indent on
  syntax enable
  NeoBundleCheck
"}}}
