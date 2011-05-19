vnoremap g- :call vim_addon_haskell#IndentStuffTheWayPastornWant('-')<cr>
vnoremap g< :call vim_addon_haskell#IndentStuffTheWayPastornWant('<')<cr>
vnoremap g= :call vim_addon_haskell#IndentStuffTheWayPastornWant('<-')<cr>

if !exists('did_import_mapping') && !exists('g:codefellow_no_import_mapping')
  let did_import_mapping = 1
  " note: codefellow is using something similar as well.
  " So if you open a .hx file first you'll get the wrong import hook!
   "autocmd Filetype qf noremap <buffer> i :call<space>haxe#AddImportFromQuickfix()<cr>

  " noremap \i :call<space>Haskell#FindImportByTags()<cr>
endif

noremap <buffer> \ai :HaskellAddMissingImportsFromQF<cr>
noremap <buffer> \at :HaskellAddTypeSigsFromQF<cr>
