" setup cabal / ghc compilation {{{1
"
" TODO: remove references to tovl#

" vam#DefineAndBind('s:c','g:vim_addon_haskell','{}')
if !exists('g:vim_addon_haskell') | let g:vim_addon_haskell = {} | endif | let s:c = g:vim_addon_haskell
" cabal support is not complete yet: probably there is no need to compile ./Setup .. (TODO)
let s:c.cabal_command = get(s:c, 'cabal_command', executable('cabal') ? ["cabal"] : ["./Setup"] )


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
  let args = actions#ConfirmArgs(args, 'command: ')
  return "call bg#RunQF(".string(args).", 'c', ".string(s:ef).")"
endf

" Cabal {{{2
fun! vim_addon_haskell#RunCabalBuild()
  " errorformat taken from http://www.vim.org/scripts/script.php?script_id=477
  let args = s:c.cabal_command + ["build","--builddir", vim_addon_haskell#DistDir() ]
  let args = actions#ConfirmArgs(args, 'command :')
  let onFinish = funcref#Function('vim_addon_haskell#TryReconfigure', {'args': [args] })
  return "call bg#RunQF(".string(args).", 'c', ".string(s:ef).", ".string(onFinish).")"
endf

fun! vim_addon_haskell#TryReconfigure(buildCommand, status)
  let regex = "Setup: \\S* has been changed, please re-configure\\|Run the 'configure' command first\\."
  for l in getqflist()
    if l.text =~ regex
      let reconfigure =1
    endif
  endfor
  if exists('reconfigure')
    echom 'reconfiguring for you'
    let rerun = funcref#Function('bg#RunQF', {'args': [ a:buildCommand, 'c', s:ef] })
    call bg#RunQF(s:c.cabal_command +["configure", "--builddir", vim_addon_haskell#DistDir()], 'c','dummy', rerun)
  endif
endf

fun! vim_addon_haskell#RunCabalBuildResult()
  let files = []
  for dist in vim_addon_haskell#DistDirs()
    call extend(files, filter(split(glob(dist.'/build/*/*'),"\n"), 'executable(v:val)'))
  endfor

  let ex = tlib#input#List('s', 'select executable :', files)

  let args = [ex]
  let args = actions#ConfirmArgs(args, 'command:')
  return "call bg#RunQF(".string(args).", 'c', ".string(s:ef).")"
endf


" simple cabal completion {{{1

" list is probably incomplete
let s:cabalSettings = 
  \[ 'version:'
  \, 'license:'
  \, 'author:'
  \, 'homepage:'
  \, 'category:'
  \, 'build-depends:'
  \, 'synopsis:'
  \, 'exposed-modules:'
  \, 'other-modules:'
  \, 'hs-source-dirs:'
  \, 'src:'
  \, 'extra-lib-dirs:'
  \, 'extra-libraries:'
  \, 'include-dirs:'
  \, 'ghc-options:'
  \, 'extensions:'
  \, 'cpp-options:'
  \, 'buildable:'
  \, 'build-type:'
  \, 'default-language: Haskell2010'
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


" errorformat taken from http://www.vim.org/scripts/script.php?script_id=477
let s:ef =
        \ '%f:%l:%c:%m'
        \ .',%E%f:%l:%c:'

fun! vim_addon_haskell#RunGHCRHS()

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
  let args = actions#ConfirmArgs(args, 'command :')
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

" QF helpers {{{1
fun! vim_addon_haskell#AddTypeSignaturesFromQF()
  let list = getqflist()
  let l = 0
  let sigs = []
  while l < len(list)
    " find item of qf list which has a filename
    while l < len(list) && list[l].bufnr == 0 | let l += 1 | endwhile
    if l == len(list) | break | endif
    let file = list[l]
    let l += 1
    if l == len(list) | break | endif

    if list[l].text =~ 'Warning: Definition but no type signature for'
      let l += 1
      let type = []
      while list[l].bufnr == 0
        call add(type, substitute(list[l].text,'^             Inferred type: \|^                            ','',''))
        let l += 1
      endwhile
      call add(sigs, [file, type[:-2]])
    else
      let l += 1
    endif
  endwhile
  let names = []
  for l in range(len(sigs)-1,0,-1)
    let sig = sigs[l]
    " goto buf
    exec 'b '.sig[0].bufnr
    " add lines
    call append(sig[0].lnum-1, sig[1])
    call add(names, sig[1][0])
  endfor
  echo 'sigs added to :'
  for l in names | echo l | endfor
endf 

fun! vim_addon_haskell#AddMissingImportsFromQF()
  let list = getqflist()
  let l = 0
  let sigs = []
  let missing = {}
  let reg_missing = 'Not in scope: \%(type constructor or class \|data constructor \)\?`\zs[^'']\+\ze'''
  while l < len(list)
    if list[l].text =~ reg_missing
      let missing[matchstr(list[l].text, reg_missing)]=1
    endif
    let l += 1
  endwhile

  let hardcoded = {
        \ 'MVar': 'Control.Concurrent.Mvar'
        \ }

  for k in keys(missing)
    if has_key(hardcoded, k)
      let module_name = hardcoded[k]
    else
      let tags = taglist('^'.k)
      let f = eval(tlib#input#List('s'
            \ , 'import '.k.' from which module? :'
            \ , map(tags,'string([vim_addon_haskell#ModuleNameFromFile(v:val.filename)])'))
            \ )
      let module_name = f[0]
    endif
    call vim_addon_haskell#AddImport(module_name, k)
  endfor
endf

" }}}

" helper functions {{{1
fun! vim_addon_haskell#AddImport(module_name, thing)
  normal gg
  let nr = search('^import\>','n')
  if nr == 0
    let nr = 2
  endif
  " TODO should handle existing imports etc
  call append(nr-1, input('import line :', 'import '.a:module_name.' ('.a:thing.')'))
endf

fun! vim_addon_haskell#ModuleNameFromFile(file)
  let r = '^module\s\+\zs\S\+\ze'
  let lines = filter(readfile(a:file), 'v:val =~ '.string(r))
  return empty(lines) ? "" : matchstr(lines[0], r)
endf

fun! vim_addon_haskell#DistDirs()
  return map(split(glob("*/setup-config"),"\n"), '"./".fnamemodify(v:val, ":h")')
endf

fun! vim_addon_haskell#DistDir()
  " Ask for dist directory
  if !exists('s:c.cabalDistDir')
    let dirs = vim_addon_haskell#DistDirs()
    if dirs == [] | let dirs = ["dist"] | endif
    let s:c.cabalDistDir = tlib#input#List("s", "Which cabal setup to use ?", dirs)
  endif
  return s:c.cabalDistDir
endf

fun! vim_addon_haskell#CabalFile()
  if !exists('s:c.cabalFile')
    let cabalFiles = split(glob('*.cabal'),"\n")
    " should never happpen ..
    let s:c.cabalFile = tlib#input#List("s", "Which cabal file to use?", cabalFiles)
  endif
  return s:c.cabalFile
endf

"|func intended to be used with ScanAndCache
"|     by now reads a cabal file and returns a line representation
"|     lines are joined. That does mean that every line should contain one
"|     option
"|      way) Thus  option : abc, \n def will become option abc, def
"|     
"|      Can't return a dictionary because a keys may occur more than once (eg hs-source-dirs)
function! vim_addon_haskell#CabalFileRead(lines)
  let lines = []
  let line_to_add = ''
  if len(a:lines) > 0
    for line in a:lines
      if line  !~ ':'
	let line_to_add .= ' '.line
      else
	call add(lines, line_to_add)
	let line_to_add = line
      endif
    endfor
    call add(lines, line_to_add)
  endif
  return lines
endfunction

function! vim_addon_haskell#CabalFileGetExecutableNames(file)
  let result = config#ScanIfNewer(a:file, {'use_cache': 1, 'scan_func':function('vim_addon_haskell#CabalFileRead')})
  let regex = '\cexecutable:\?\s*\zs[^\t \n\r]\+\ze'
  return tovl#regex#regex#MatchAll(join(result, " "), regex)
endfunction

fun! vim_addon_haskell#HackNixReloadEnv()
  let env = matchstr(vim_addon_haskell#DistDir(),'dist\zs.*').'-env'
  if env == "-env"
    let  env = 'default-env'
  endif
  if filereadable(env)
    call env_reload#ReloadEnv(system('sh -c ". ./'.env.' 2> /dev/null; export"'))
    if has_key(s:c,'env_reloaded_hook_fun')
      call call(s:c.env_reloaded_hook_fun, [])
    endif
  else
    throw env.' file not found'
  endif
endf

" vim:fdm=marker
