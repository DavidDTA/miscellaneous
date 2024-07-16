{ writeScriptBin, python3, fswatch }:
    writeScriptBin "watch" (builtins.replaceStrings ["@python3@" "@fswatch@"] ["${python3}" "${fswatch}"] (builtins.readFile ./watch.py))
