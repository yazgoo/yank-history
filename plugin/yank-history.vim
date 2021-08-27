""
" directory where yank history is stored
let g:yank_history_dir=$HOME . "/.local/share/yank_history"

""
" temporary directory for yank history
let g:yank_history_tmp_dir = yank_history_dir . "-tmp"

""
" maixum number of yank to keep
" (0 or less means keeping all of them)
let g:yank_history_max_size = 20

let s:yank_history_script_dir = expand('<sfile>:p:h')
let s:yank_history_last=""

function! s:yank_history_paste(line)
  execute 'normal!  o' . join(readfile(split(a:line, ':')[0], 'b'), "\n")
endfunction

function! YankHistoryYank() 
  if s:yank_history_last != @0
  let s:yank_history_last = @0
  call mkdir(g:yank_history_dir, "p", 0700)
  call mkdir(g:yank_history_tmp_dir, "p", 0700)
  let tmp = g:yank_history_tmp_dir . '/' . strftime("%d-%m-%y-%H-%M-%S.").&filetype
  call writefile(split(@0, "\n", 1), tmp, 'b')
  let md5=trim(system('md5sum ' . tmp . ' | cut "-d " -f1'))
  let out = g:yank_history_dir.'/'.md5.'.'.&filetype
  if filereadable(out)
    silent execute "!rm " . tmp
  else
    silent execute "!mv " . tmp . " " . out
  endif
  let wc_l = trim(system('ls ' . g:yank_history_dir . ' | wc -l'))
  let num_yanks = str2nr(wc_l)
  if g:yank_history_max_size > 0 && num_yanks > g:yank_history_max_size
    silent execute '!rm "$(ls -t ' . g:yank_history_dir . '/*| tail -1)"'
  endif
  endif
endfunction

if exists('##TextYankPost')
  autocmd! TextYankPost * :call YankHistoryYank()
else
  map y <Plug>(YankHistoryYank)
endif

function! YankHistoryClean()
  silent execute "!rm " . g:yank_history_dir . "/*"
  silent execute "!rm " . g:yank_history_tmp_dir . "/*"
  let s:yank_history_last=""
endfunction

""
" cleanups yank history directory
command! -bang -nargs=0 YankHistoryClean call YankHistoryClean()

""
" opens FZF to select yank history file to be pasted
command! -bang -nargs=0 YankHistoryPaste
  \ call fzf#vim#grep(
  \ 'ls -t ' . g:yank_history_dir .  '/*', 0,
  \   {
  \     'options': ["--prompt", "> ", "--preview",  s:yank_history_script_dir .'/../../fzf.vim/bin/preview.sh {}'],
  \     'sink': function('s:yank_history_paste')
  \   },
  \   <bang>0
  \ )

""
" grep within yank history via FZF and opens the file matching the search
" pattern
command! -bang -nargs=* YankHistoryRg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always --smart-case  -- '.shellescape(<q-args>).' '.g:yank_history_dir, 1,
  \   fzf#vim#with_preview(), <bang>0)

""
" grep within yank history via FZF and paste the content
" of the file matching the search pattern
command! -bang -nargs=* YankHistoryRgPaste
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always --smart-case  -- '.shellescape(<q-args>).' '.g:yank_history_dir, 0,
  \   {
  \     'options': ["--prompt", "> ", "--preview",  s:yank_history_script_dir .'/../../fzf.vim/bin/preview.sh {}'],
  \     'sink': function('s:yank_history_paste')
  \   },
  \ <bang>0)
