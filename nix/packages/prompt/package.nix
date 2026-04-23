
{ jujutsu, writeShellApplication }:
  writeShellApplication {
    name = "prompt";
    runtimeInputs =  [ jujutsu ];
    text = builtins.readFile(./prompt);
  }
