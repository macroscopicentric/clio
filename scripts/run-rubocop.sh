#!/usr/bin/env bash

set -euo pipefail

# go to top of project
cd "${0%/*}/.."

# might be worth bumping this up to -A at some point?
# currently unsure about what gets considered small
# vs. big.
echo "Running rubocop"
bundle exec rubocop -a
