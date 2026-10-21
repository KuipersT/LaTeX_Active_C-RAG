#!/usr/bin/env bash
set -euo pipefail

# Usage: latexdiff.sh <old-ref> <main-tex-basename>
# Example: latexdiff.sh HEAD~1 main
#   Compares the current working tree's main.tex against the version at HEAD~1.

OLD_REF="${1:-HEAD}"
MAIN="${2:-main}"
PROJECT_DIR="$(pwd)"
DIFF_DIR="${PROJECT_DIR}/diff"

mkdir -p "${DIFF_DIR}"

echo "==> Extracting ${MAIN}.tex from git ref: ${OLD_REF}"
# Export the old version of the project to a temp dir so latexpand can resolve \input paths
OLD_SRC="$(mktemp -d)"
git archive "${OLD_REF}" | tar -x -C "${OLD_SRC}"

echo "==> Flattening old version"
( cd "${OLD_SRC}" && latexpand "${MAIN}.tex" > "${DIFF_DIR}/old-flat.tex" )

echo "==> Flattening current version"
latexpand "${MAIN}.tex" > "${DIFF_DIR}/new-flat.tex"

echo "==> Running latexdiff"
latexdiff \
  --flatten \
  --type=UNDERLINE \
  --exclude-safecmd="cite,citep,citet" \
  "${DIFF_DIR}/old-flat.tex" \
  "${DIFF_DIR}/new-flat.tex" \
  > "${DIFF_DIR}/diff.tex"

echo "==> Compiling diff.tex"
cd "${DIFF_DIR}"
BIBINPUTS="${PROJECT_DIR}:" \
TEXINPUTS="${PROJECT_DIR}:" \
  latexmk -pdf -synctex=1 -interaction=nonstopmode -file-line-error -f diff.tex || true

if [[ -f "${DIFF_DIR}/diff.pdf" ]]; then
  echo "==> Done. Output: ${DIFF_DIR}/diff.pdf"
else
  echo "==> FAILED: diff.pdf was not produced"
  exit 1
fi