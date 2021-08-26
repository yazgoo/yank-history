let g:yank_history=[]
let g:yank_history_dir=$HOME . "/.local/share/yank_history"
let g:yank_history_tmp_dir = yank_history_dir . "-tmp"
let s:yank_history_script_dir = expand('<sfile>:p:h')

function! s:yank_history_paste(line)
  execute 'normal!  o' . join(readfile(split(a:line, ':')[0], 'b'), "\n")
endfunction

function! YankHistoryYank() 
  if index(g:yank_history, @0) < 0
  let g:yank_history = add(g:yank_history, @0)
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
  endif
endfunction

autocmd! TextYankPost * :call YankHistoryYank()

command! -bang -nargs=0 YankHistoryClean
  \ execute "!rm " . g:yank_history_dir . "/*"

command! -bang -nargs=0 YankHistoryPaste
  \ call fzf#vim#grep(
  \ 'ls -t ' . g:yank_history_dir .  '/*', 0,
  \   {
  \     'options': ["--prompt", "> ", "--preview",  s:yank_history_script_dir .'/../../fzf.vim/bin/preview.sh {}'],
  \     'sink': function('s:yank_history_paste')
  \   },
  \   <bang>0
  \ )

command! -bang -nargs=* YankHistoryRg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always --smart-case  -- '.shellescape(<q-args>).' '.g:yank_history_dir, 1,
  \   fzf#vim#with_preview(), <bang>0)

command! -bang -nargs=* YankHistoryRgPaste
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always --smart-case  -- '.shellescape(<q-args>).' '.g:yank_history_dir, 0,
  \   {
  \     'options': ["--prompt", "> ", "--preview",  s:yank_history_script_dir .'/../../fzf.vim/bin/preview.sh {}'],
  \     'sink': function('s:yank_history_paste')
  \   },
  \ <bang>0)
