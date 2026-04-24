
{ coreutils, jujutsu, writeShellApplication }:
  writeShellApplication {
    name = "prompt";
    inheritPath = false;
    runtimeInputs =  [
      coreutils
      jujutsu
    ];
    text = builtins.readFile(./prompt);
  }
