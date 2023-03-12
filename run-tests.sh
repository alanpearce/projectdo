#!/bin/sh

# Colors
RED=`tput setaf 1`
BOLD=`tput bold`
RESET=`tput sgr0`

ANY_ERRORS=false

# Make sets this variable when we run it and can influence the test results.
# Since this script is run through `make`, we need to unset it.
unset MAKELEVEL

# Get the directory of the current script, in a POSIX compatible way
# https://stackoverflow.com/a/29835459
script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)

# Set this variable to ensure top level Makefile doesn't affect the results.
export PROJECT_ROOT="${script_directory}/tests"

describe() {
  printf "\n$BOLD$1$RESET"
}

it() {
  printf "\n  $1"
}

assert() {
  if [ $RUN_EXIT -eq 0 ]; then
    printf " ✓"
  else
    printf "\n    Fail\n"
    ANY_ERRORS=true
  fi
}

assertFails() {
  if [ $RUN_EXIT -ne 0 ]; then
    printf " ✓"
  else
    printf "\n    Fail\n"
    ANY_ERRORS=true
  fi
}

assertEqual() {
  if [ "$1" = "$2" ]; then
    printf " ✓"
  else
    printf "\n   $BOLD$RED Error:$RESET Expected \"$1\" to equal \"$2\"\n"
    ANY_ERRORS=true
  fi
}

RUN_RESULT=""
RUN_EXIT=0

do_build_in() {
  RUN_RESULT=$(cd tests/$1 && ../../projectdo -n build)
  RUN_EXIT=$?
}

do_run_in() {
  RUN_RESULT=$(cd tests/$1 && ../../projectdo -n run)
  RUN_EXIT=$?
}

do_test_in() {
  RUN_RESULT=$(cd tests/$1 && ../../projectdo -n test)
  RUN_EXIT=$?
}

do_print_tool_in() {
  RUN_RESULT=$(cd tests/$1 && ../../projectdo print-tool)
  RUN_EXIT=$?
}

if describe "cargo"; then
  if it "can run build"; then
    do_build_in "cargo"; assert
    assertEqual "$RUN_RESULT" "cargo build"
  fi
  if it "can run run"; then
    do_run_in "cargo"; assert
    assertEqual "$RUN_RESULT" "cargo run"
  fi
  if it "can run test"; then
    do_test_in "cargo"; assert
    assertEqual "$RUN_RESULT" "cargo test"
  fi
fi

if describe "stack"; then
  if it "can run build"; then
    do_build_in "stack"; assert
    assertEqual "$RUN_RESULT" "stack build"
  fi
  if it "can run run"; then
    do_run_in "stack"; assert
    assertEqual "$RUN_RESULT" "stack run"
  fi
  if it "can run test"; then
    do_test_in "stack"; assert
    assertEqual "$RUN_RESULT" "stack test"
  fi
  if it "can print tool"; then
    do_print_tool_in "stack"; assert
    assertEqual "$RUN_RESULT" "stack"
  fi
fi

if describe "nodejs"; then
  if it "can run npm build if package.json with build script"; then
    do_build_in "npm"; assert
    assertEqual "$RUN_RESULT" "npm build"
  fi
  if it "can run npm start if package.json with start script"; then
    do_run_in "npm"; assert
    assertEqual "$RUN_RESULT" "npm start"
  fi
  if it "can run npm test if package.json with test script"; then
    do_test_in "npm"; assert
    assertEqual "$RUN_RESULT" "npm test"
  fi
  if it "uses yarn file if yarn.lock is present"; then
    do_test_in "yarn"; assert
    assertEqual "$RUN_RESULT" "yarn test"
  fi
  if it "does not use npm if package.json contains no test script"; then
    do_test_in "npm-without-test"; assert
    assertEqual "$RUN_RESULT" "make test"
  fi
fi

if describe "make"; then
  if it "finds check target"; then
    do_test_in "make-check"; assert
    assertEqual "$RUN_RESULT" "make check"
  fi
  if it "ignores file named check"; then
    do_test_in "make-check-with-check-file"; assertFails
    assertEqual "$RUN_RESULT" "No tests found :'("
  fi
  if it "finds check target if both target and file named check"; then
    do_test_in "make-check-with-check-file-and-target"; assert
    assertEqual "$RUN_RESULT" "make check"
  fi
fi

if describe "go"; then
  if it "finds check target in magefile"; then
    do_test_in "mage"; assert
    assertEqual "$RUN_RESULT" "mage check"
  fi
fi

if describe "python"; then
  if it "runs pytest with poetry"; then
    do_test_in "poetry"; assert
    assertEqual "$RUN_RESULT" "poetry run pytest"
  fi
fi

echo ""

if [ $ANY_ERRORS = true ]; then
  exit 1
fi
