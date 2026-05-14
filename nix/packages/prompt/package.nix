
{ coreutils, jujutsu, writeShellApplication }:
  writeShellApplication {
    name = "prompt";
    inheritPath = false;
    runtimeInputs =  [
      coreutils
      jujutsu
      gnused
    ];
    text = builtins.readFile(./prompt);
  }
