To run the initial code you need to use next command:

java -cp ~/.vscode/extensions/tlaplus.vscode-ide-2025.9.251809/tools/tla2tools.jar \
  -XX:+UseParallelGC tlc2.TLC XrplEscrow.tla -config XrplEscrow.cfg -deadlock -workers 8