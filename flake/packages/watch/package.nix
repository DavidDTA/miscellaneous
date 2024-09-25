{ fswatch, python3Packages, writers }:
  writers.writePython3Bin
    "watch"
    {
      libraries = [
      ];
    }
    (
      builtins.replaceStrings
      ["@fswatch@"]
      ["${fswatch}"]
      (builtins.readFile ./watch.py)
    )
