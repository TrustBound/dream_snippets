#!/bin/sh
# What CI runs: the format check, the build, the tests, the docs build and
# the snippet check. "make check" runs this script.
set -eu

gleam format --check src test
gleam build
gleam test
gleam docs build
gleam run -m dream_snippets
