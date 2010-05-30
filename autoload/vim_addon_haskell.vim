" setup cabal / ghc compilation {{{1

let s:ef =
        \ '%f:%l:%c:%m'
        \ .',%E%f:%l:%c:'

" GHC {{{2
fun! vim_addon_haskell#RunGHCRHS()
  " errorformat taken from http://www.vim.org/scripts/script.php?script_id=477

  let options = filter( getline(1, line('$')), "v:val =~ '--\\s*ghc-options:'" )
  if len(options) == 1
    let ghcOptions = split( matchstr( options[0], 'ghc-options:\s*\zs.*'), '\s*,\s*')
  elseif len(options) > 1
    echo "ambiguous options definitions"
    let ghcOptions = []
  else
    let ghcOptions = []
  endif

  let args = ["ghc","--make"] + ghcOptions + [ expand('%') ]
  let args = eval(input('command: ', string(args)))
  return "call bg#RunQF(".string(args).", 'c', ".string(s:ef).")"
endf

" Cabal {{{2
fun! vim_addon_haskell#RunCabalBuild()
  " errorformat taken from http://www.vim.org/scripts/script.php?script_id=477

  let args = ["./Setup","build"]
  let args = eval(input('command: ', string(args)))
  return "call bg#RunQF(".string(args).", 'c', ".string(s:ef).")"
endf

" simple cabal completion {{{1

" list is probably incomplete
let s:cabalSettings = 
  \[ 'version: '
  \, 'license: '
  \, 'author: '
  \, 'homepage: '
  \, 'category: '
  \, 'build-depends: '
  \, 'synopsis: '
  \, 'exposed-modules: '
  \, 'other-modules: '
  \, 'hs-source-dirs: '
  \, 'src: '
  \, 'extra-lib-dirs: .: '
  \, 'extra-libraries: '
  \, 'include-dirs: '
  \, 'ghc-options: '
  \, 'extensions: '
  \, 'cpp-options: '
  \, 'bulidable: '
  \, 'build-type : '
  \]


fun! s:SplitCurrentLineAtCursor()
  let pos = col('.') -1
  let line = getline('.')
  return [strpart(line,0,pos), strpart(line, pos, len(line)-pos)]
endfunction

fun! vim_addon_haskell#CompleteCabalSetting(findstart, base)
  if a:findstart
    let [bc,ac] = s:SplitCurrentLineAtCursor()
    return len(bc)-len(matchstr(bc,'\S*$'))
  else
    " find months matching with "a:base"
    let res = []
    for m in s:cabalSettings
      if m =~ '^' . a:base
        call add(res, m)
      endif
    endfor
    return res
  endif
endfun


" folding {{{1
fun! vim_addon_haskell#Folding(...)
  let lnum = a:0 > 0 ? a:1 : v:lnum
  let line = getline(lnum)
  if line =~ '\c^Library\|^Executable' || lnum == 1
    return ">1"
  endif
  return "="
endf


let s:ef =
        \ '%f:%l:%c:%m'
        \ .',%E%f:%l:%c:'

fun! vim_addon_haskell#RunGHCRHS()
  " errorformat taken from http://www.vim.org/scripts/script.php?script_id=477

  let options = filter( getline(1, line('$')), "v:val =~ '--\\s*ghc-options:'" )
  if len(options) == 1
    let ghcOptions = split( matchstr( options[0], 'ghc-options:\s*\zs.*'), '\s*,\s*')
  elseif len(options) > 1
    echo "ambiguous options definitions"
    let ghcOptions = []
  else
    let ghcOptions = []
  endif

  let args = ["ghc","--make"] + ghcOptions + [ expand('%') ]
  let args = eval(input('command: ', string(args)))
  return "call bg#RunQF(".string(args).", 'c', ".string(s:ef).")"
endf

fun! vim_addon_haskell#RunCabalBuild()
  " errorformat taken from http://www.vim.org/scripts/script.php?script_id=477

  let args = ["./Setup","build"]
  let args = eval(input('command: ', string(args)))
  return "call bg#RunQF(".string(args).", 'c', ".string(s:ef).")"
endf


" new stuff  {{{1
fun! vim_addon_haskell#IndentStuffTheWayPastornWant(i_c) range
  " get the lines we want to indent:
  let range = range(a:firstline, a:lastline)
  let lines = getline(a:firstline, a:lastline)
  let i_c = a:i_c
  " max index based on indentation
  let max_indent = {}
  for idx in range
    let l = getline(idx)
    let ind = indent(idx)
    let lis = matchlist(l, '\([^<'.i_c.']\{-}\)\(['.i_c.'].*\)')
    if len(lis) < 3 || lis[2] == "" | break | endif
    let l = matchstr(lis[1],'^\zs.\{-}\ze\s*$') " part of the line before separator and remove trailing spaces
    let r = lis[2] " part of line beginning with separator
    " TODO: remove spaces before ->
    let l = len(l)
    if l > get(max_indent, ind, 0) | let max_indent[ind] = l | endif
  endfor
  " now do the indentation, missing spaces
  let offset = 0
  for idx in range
    let l = getline(idx)
    let ind = indent(idx)
    let lis = matchlist(l, '\([^<'.i_c.']\{-}\)\(['.i_c.'].*\)')
    if len(lis) < 3 || lis[2] == "" | break | endif
    let l = matchstr(lis[1],'^\zs.\{-}\ze\s*$') " part of the line before separator and remove trailing spaces
    let r = lis[2]
    let diff = max_indent[ind] - len(l) + 1
    call setline(a:firstline + offset, l . repeat(' ', diff). r )
    let offset = offset + 1
  endfor
endfun

" vim:fdm=marker
