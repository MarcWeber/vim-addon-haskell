call actions#AddAction('run ghc', {'action': funcref#Function('vim_addon_other_haskell#RunGHCRHS')})
call actions#AddAction('run cabal build', {'action': funcref#Function('vim_addon_other_haskell#RunCabalBuild')})

augroup HASKELL_CABAL
  autocmd BufRead,BufNewFile *.cabal  setlocal ft=cabal
augroup end
