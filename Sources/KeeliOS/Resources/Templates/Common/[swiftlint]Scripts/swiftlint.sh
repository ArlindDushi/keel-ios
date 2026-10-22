#!/bin/sh
#
# Lints the sources on every build. Install SwiftLint with `brew install swiftlint`.
#

export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"

if command -v swiftlint >/dev/null 2>&1; then
  swiftlint lint --config "${SRCROOT}/.swiftlint.yml"
else
  echo "warning: SwiftLint is not installed. Run 'brew install swiftlint'."
fi
