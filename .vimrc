set hlsearch
set ruler
syntax on
set re=0

set noswapfile

nnoremap j gj
nnoremap k gk

nnoremap <Tab> :cn<Return>
nnoremap <S-Tab> :cp<Return>
nnoremap <Space> :cc<Return>

autocmd Filetype python setlocal tabstop=4 shiftwidth=4 expandtab autoindent
autocmd Filetype elm setlocal tabstop=4 shiftwidth=4 expandtab autoindent

" VimTip: http://vim.wikia.com/wiki/Search_for_visually_selected_text
" Search for selected text, forwards or backwards.
vnoremap <silent> * :<C-U>
  \let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>
  \gvy/<C-R><C-R>=substitute(
  \escape(@", '/\.*$^~['), '\_s\+', '\\_s\\+', 'g')<CR><CR>
  \gV:call setreg('"', old_reg, old_regtype)<CR>
vnoremap <silent> # :<C-U>
  \let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>
  \gvy?<C-R><C-R>=substitute(
  \escape(@", '?\.*$^~['), '\_s\+', '\\_s\\+', 'g')<CR><CR>
  \gV:call setreg('"', old_reg, old_regtype)<CR>
