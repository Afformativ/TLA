To run the initial code you need to use next command:

java -XX:+UseParallelGC -cp ~/.vscode/extensions/tlaplus.vscode-ide-2025.9.251809/tools/tla2tools.jar \
  tlc2.TLC -deadlock -workers 8 -config XrplEscrow_A1.cfg XrplEscrow.tla