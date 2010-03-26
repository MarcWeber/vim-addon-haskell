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

fun! vim_addon_haskell#CompleteCabalSetting(findstart, base)
  if a:findstart
    let [bc,ac] = tovl#buffer#SplitCurrentLineAtCursor()
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

" vim:fdm=marker
