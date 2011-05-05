call actions#AddAction('run ghc', {'action': funcref#Function('vim_addon_haskell#RunGHCRHS')})
call actions#AddAction('run ghc compilation result', {'action': funcref#Function('actions#CompileRHSSimple', {'args': [[], [funcref#Function('return "./".expand("%:r:t")')]]})})
call actions#AddAction('run cabal build', {'action': funcref#Function('vim_addon_haskell#RunCabalBuild')})

augroup HASKELL_CABAL
  autocmd BufRead,BufNewFile *.cabal  setlocal ft=cabal
  " not perfect:
  " should only be done if it is a Haskell file (TODO)
  autocmd BufRead,BufNewFile *.x if search('^module\>','n') > 0 | setlocal ft=haskell | endif
  autocmd BufRead,BufNewFile *.y if search('^module\>','n') > 0 | setlocal ft=haskell | endif
augroup end

command! HaskellAddTypeSigsFromQF call vim_addon_haskell#AddTypeSignaturesFromQF()
