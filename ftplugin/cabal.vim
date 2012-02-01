if exists('did_cabal') || &cp || version < 700
  finish
endif
let did_cabal = 1

setlocal foldmethod=expr
setlocal foldexpr=vim_addon_haskell#Folding()
setlocal omnifunc=vim_addon_haskell#CompleteCabalSetting
setlocal comments=b:--\ %s
