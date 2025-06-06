set hlsearch
set ruler
syntax on
set re=0
set noswapfile
set list
set listchars=extends:>,precedes:<
set errorformat=%f:%o:%l:%c:%e:%k:%m

nnoremap j gj
nnoremap k gk
nnoremap <Down> gj
nnoremap <Up> gk

nnoremap <Tab> :cclose<Bar>cn<Return>
nnoremap <S-Tab> :cclose<Bar>cp<Return>
" https://stackoverflow.com/q/11198382#comment122398806_63162084
nnoremap <expr> <Space> empty(filter(getwininfo(), 'v:val.quickfix')) ? empty(getqflist()) ? '' : ':%bd<Bar>:copen<Bar>bd#<Return>' : ':cc<Bar>cclose<Return>'
nnoremap <Esc> :w<Bar>cexpr system('type -p quickfix >/dev/null && quickfix')<Return><Space>

autocmd Filetype python setlocal tabstop=4 shiftwidth=4 expandtab autoindent
autocmd Filetype elm setlocal tabstop=4 shiftwidth=4 expandtab autoindent
autocmd Filetype qf nnoremap <buffer> h zh
autocmd Filetype qf nnoremap <buffer> l zl
autocmd Filetype qf nnoremap <buffer> <Left> zh
autocmd Filetype qf nnoremap <buffer> <Right> zl
autocmd BufWinEnter quickfix setlocal nowrap

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
