{ fswatch, python3Packages, writers }:
  writers.writePython3Bin
    "watch"
    {
      libraries = [
        python3Packages.psutil
      ];
    }
    (
      builtins.replaceStrings
      ["@fswatch@"]
      ["${fswatch}"]
      (builtins.readFile ./watch.py)
    )
