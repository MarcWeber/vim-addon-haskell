"|func intended to be used with ScanAndCache
"|     by now reads a cabal file and returns a line representation
"|     lines are joined. That does mean that every line should contain one
"|     option
"|      way) Thus  option : abc, \n def will become option abc, def
"|     
"|      Can't return a dictionary because a keys may occur more than once (eg hs-source-dirs)
function! tovl#language_support#cabal#CabalFileRead(lines)
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

function! tovl#language_support#cabal#CabalFileGetExecutableNames(file)
  let result = config#ScanIfNewer(a:file, 1, function('tovl#dev#haskell#cabal#CabalFileRead'))
  let regex = '\cexecutable:\?\s*\zs[^\t \n\r]\+\ze'
  return tovl#regex#regex#MatchAll(join(result, " "), regex)
endfunction

function! tovl#language_support#cabal#DefineCabalfile()
  let cabal_files = split(glob('*.cabal'),"\n")
  if len(cabal_files) > 0
    return tovl#ui#choice#LetUserSelectIfThereIsAChoice("from which cabal file may I take the executable names? ", cabal_files)
  else
    return 0
  endif
endfunction

function! tovl#language_support#cabal#DefineCabalFileToUse()
  return vl#lib#vimscript#scriptsettings#GetOrDefine('g:cabal_file', 'vl#dev#haskell#cabal#DefineCabalfile()')
endfunction

"|func This function is used to get one executable from the cabal file from
"|+    current directory
"|     example usage:
"|code map <F4> : exec '!dist/build/'.GetOrDeclare('g:executable', 'tovl#dev#haskell#cabal#DefineProjectExecutable()')
function! tovl#language_support#cabal#DefineProjectExecutable()
  let executables = vl#dev#haskell#cabal#CabalFileGetExecutableNames(
    \ vl#dev#haskell#cabal#DefineCabalFileToUse() )
  return tovl#ui#choice#LetUserSelectIfThereIsAChoice("Which executable ?", executables)
endfunction

function! tovl#language_support#cabal#CabalFileGetHsSourceDirs(file)
  let result = config#ScanIfNewer(a:file, 1, function('tovl#dev#haskell#cabal#CabalFileRead'))
  let regex = '\s*\chs-source-dirs:\s*\zs.*\ze'
  let dir_lists = map( filter(deepcopy( result ), " v:val  =~ ".string(regex))
		\ , " matchstr(v:val, ".string(regex).")")
  let dirs = []
  for line in dir_lists
    for dir in split(line,'\s*,\s*')
      call add(dirs, dir)
    endfor
  endfor
  return vl#lib#listdict#list#Unique(dirs)
endfunction

" sepLists = 1 means 
" blah : a b , d e
"        f
" blah : f
" will become [ a, b , d, f, f]
" cabal does use ',' to separate them, ghc-pkg describe doesn't
function! tovl#language_support#cabal#MergeOption(file, option, sepLists)
  let regex = '\c\s*'.a:option.':\s*\zs.*\ze'
  let result = a:file
  call filter( result," v:val  =~ ".string(regex)) 
  call map(  result," matchstr(v:val, ".string(regex).")")
  if a:sepLists
    call map(result, "split(v:val,'\\s\\+\\|\\s*,\\s*')")
    return vl#lib#listdict#list#JoinLists(result)
  else
    return result
  endif
endfunction

" collects all lines defining one setting value (eg build-depndencies)
" and returns a list
function! tovl#language_support#cabal#CabalFileMergedOption(option, sepLists)
  let result = deepcopy(config#ScanIfNewer(
        \ vl#dev#haskell#cabal#DefineCabalFileToUse(), 1
        \ , function('tovl#dev#haskell#cabal#CabalFileRead')))
  return vl#dev#haskell#cabal#MergeOption(result, a:option, a:sepLists)
endfunction

"| returns the package depndencies from the cabal file
function! tovl#language_support#cabal#CabalFileGetPkgDeps()
  return vl#dev#haskell#cabal#CabalFileMergedOption('build-depends',1)
endfunction

function! tovl#language_support#cabal#DefineTagFilesBasedOnPacakges()
  let tag_files = []
  for i in g:UsedGhcPackages
    call extend(tag_files, split(glob("/home/marc/.nix-profile/src/*".i."*/*_haskell_tags"),"\n"))
  endfor
  exec 'set tags=tags,TAGS,'.join(tag_files,',')
endfunction

function! tovl#language_support#cabal#AllTags()
  let tag_files = []
  let g:old_tags=&tags
    call extend(tag_files, split(glob("/home/marc/.nix-profile/src/*/*_haskell_tags"),"\n"))
  exec 'set tags=tags,TAGS,'.join(tag_files,',')
endfunction

function! tovl#language_support#cabal#SetCabalMappingsIfIsCabalDir()
  " project settings haskell :
  " set makeprg if we are in a Setup.[l]hs direoctry:
  let s:files = filter(split(glob('*etup.*hs'),"\n"),'v:val  =~ "^\\csetup.l\\=hs$"')
  call add(s:files,"")
  let file=s:files[0]
  if filereadable(file)
    let g:setupfile=file
  endif
  if exists('g:setupfile') && &makeprg=='make'
    let file2=filter(split(glob('*etup'),"\n"),'v:val  =~ "^\\csetup$"')
    if len(file2)>0
      let g:setup_executable=file2[0]
    else
      let g:setup_executable=substitute(g:setupfile,'.l\?hs','','')
    endif
    " F1 mapping to create setup executable using ghc
    " F2 ./setup configure
    " F3 ./setup compile
    " F5 execute executable build by cabal
    " F12 ./setup clean
    map <F1> :wa <bar> call tovl#lib#quickfix#runtaskinbackground#RunInBGQFAW(
      \ [g:ghc, '--make', '-o', 'setup', g:setupfile])<cr>
    map <F2> :wa <bar> call tovl#lib#quickfix#runtaskinbackground#RunInBGQFAW(
      \ ['./'.g:setup_executable,'configure','--with-compiler='.g:ghc, '--with-hc-pkg='.g:ghcpkg,'--user'])<cr>
    map <F3> :wa <bar> call tovl#lib#quickfix#runtaskinbackground#RunInBGQFAW(
                            \ ['./'.g:setup_executable, 'build', "--distdir=".vl#dev#haskell#cabal#DistDir()]
                            \ , { 'efm' : 'ghc', 'onFinish' : ['call tovl#dev#haskell#qffixfixable#FixFixable(a:status)', "call vl#dev#haskell#cabal#AfterCabalBuild(a:status)" ] } )<cr>
    map <F5> :exec '!'.g:cabalDistDir.'/build/*/'.vl#lib#vimscript#scriptsettings#GetOrDefineFromString(
      \ 'g:executable', 'vl#dev#haskell#cabal#DefineProjectExecutable()')<cr>
    map <F12> :wa <bar> call tovl#lib#quickfix#runtaskinbackground#RunInBGQFAW(
      \ ['./'.g:setup_executable.'clean'])<cr>
    let folder=substitute(getcwd(),'.*\%(/\|\\\)','','')
    exec ' map <F11> :!dist/build/'.folder.'/'.folder.'<cr>'
    exec ' map <F10> :call tovl#lib#quickfix#runtaskinbackground#RunMakeInBG("dist/build/'.folder.'/'.folder.'")<cr>'
    Noremap <m-e><m-c> :e *.cabal<tab><cr>
    let g:UsedGhcPackages = vl#dev#haskell#cabal#CabalFileGetPkgDeps()
    if join(readfile(vl#dev#haskell#cabal#DefineCabalFileToUse()),"\n") =~ '\chapps-server'
      echo "automatically restarting HAppS server after sucessful cabal built"
      let g:afterCabalBuild = "call vl#dev#haskell#cabal#RestartHAppSServer(a:status)"
    endif
    return [1, ""]
  endif
    return [0, 'no setup file found']
endfunction

function! tovl#language_support#cabal#AfterCabalBuild(status)
  if exists('g:afterCabalBuild')
    exec g:afterCabalBuild
  endif
endfunction

" Maybe I should write some abstraction for this? Should I put it into a an
" extra file? 
function! tovl#language_support#cabal#RestartHAppSServer(status)
  if a:status == 0
    let executable =  vl#lib#vimscript#scriptsettings#GetOrDefineFromString(
      \ 'g:afterCabalBuildToBeRestarted', 'vl#dev#haskell#cabal#DefineProjectExecutable()')
    let file = g:afterCabalBuildToBeRestarted
    let filename = vl#lib#files#filefunctions#FileName(file)
    echo system('pkill -9 '.filename.'; sleep 1; dist/build/'.file.'/'.file.' &> /tmp/happs-log-'.filename.' &')
  endif 
endfunction

" globs the current directories for hs/ lhs files and inserts them in cabal
" format
function! tovl#language_support#cabal#InstertModules()
  let files = split(glob("**/*.*hs"), "\n")
  call map(files, "', '.substitute(substitute(v:val,'\\.\\%(l\\)\\=hs$','','g'),'[/\\\\]','\\.','g')")
  let @"=join(files,"\n")
  exec "normal i\<c-r>\"\<esc>"
endfunction
