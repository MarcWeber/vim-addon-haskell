call actions#AddAction('run ghc', {'action': funcref#Function('vim_addon_haskell#RunGHCRHS')})
call actions#AddAction('run ghc compilation result', {'action': funcref#Function('actions#CompileRHSSimple', {'args': [[], [funcref#Function('return "./".expand("%:r:t")')]]})})
call actions#AddAction('run cabal build', {'action': funcref#Function('vim_addon_haskell#RunCabalBuild')})

augroup HASKELL_CABAL
  autocmd BufRead,BufNewFile *.cabal  setlocal ft=cabal
augroup end
