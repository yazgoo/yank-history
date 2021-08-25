let g:yank_history=[]
let g:yank_history_dir=$HOME . "/.local/share/yank_history"
let g:yank_history_tmp_dir = yank_history_dir . "-tmp"

function! s:yank_history_paste(line)
  execute 'normal!  o' . join(readfile(a:line, 'b'), "\n")
endfunction

function! s:yank_history_yank() 
  if index(g:yank_history, @0) < 0
  let g:yank_history = add(g:yank_history, @0)
  call mkdir(yank_history_dir, "p", 0700)
  call mkdir(yank_history_tmp_dir, "p", 0700)
  let tmp = yank_history_tmp_dir . '/' . strftime("%d-%m-%y-%H-%M-%S.").&filetype
  call writefile(split(@0, "\n", 1), tmp, 'b')
  let md5=trim(system('md5sum ' . tmp . ' | cut "-d " -f1'))
  let out = yank_history_dir.'/'.md5.'.'.&filetype
  if filereadable(out)
    silent execute "!rm " . tmp
  else
    silent execute "!mv " . tmp . " " . out
  endif
  endif
endfunction

autocmd TextYankPost * :call s:yank_history_yank()
command! -bang -nargs=0 YankHistoryClean
  \ execute "!rm " . g:yank_history_dir . "/*"
command! -bang -nargs=0 YankHistoryPaste
  \ call fzf#vim#grep(
  \ 'ls -t ' . g:yank_history_dir .  '/*', 0,
  \   {
  \     'options': ["--prompt", "> ", "--preview",  expand('<sfile>:p:h') . '/../../fzf.vim/bin/preview.sh {}'],
  \     'sink': function('s:yank_history_paste')
  \   },
  \   <bang>0
  \ )
