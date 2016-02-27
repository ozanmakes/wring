#!/bin/sh

RUN_TESTS='echo "Running tests using Node.js $(node -v) and Phantomjs $(phantomjs -v)" && node output/test.js'

if type nix-shell > /dev/null; then
  EXIT_STATUS=0
  nix-shell -p nodejs-0_10 phantomjs --run "$RUN_TESTS" || EXIT_STATUS=$?
  nix-shell -p nodejs-4_x phantomjs --run "$RUN_TESTS" || EXIT_STATUS=$?
  nix-shell -p nodejs-5_x phantomjs2 --run "$RUN_TESTS" || EXIT_STATUS=$?
  exit $EXIT_STATUS
else
  sh -c "$RUN_TESTS"
fi
