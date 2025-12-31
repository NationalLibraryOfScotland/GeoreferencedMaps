#!/bin/bash

# Usage: ./extract_loggers.sh <source_file> [<default_level>]
# Looks for first version line and incoroportes in output filename
# This should be the version of GpPlugins
SOURCE_FILE="$1"
DEFAULT_LEVEL="${2:-SILENT}"

if [ -z "$SOURCE_FILE" ]; then
  echo "Usage: $0 <source_file> [<default_level>]"
  exit 1
fi

# Extract the first version from the first 50 lines of the source file
VERSION=$(head -50 "$SOURCE_FILE" | grep -m1 -oE '@version[[:space:]]+[0-9]+\.[0-9]+\.[0-9]+' | awk '{print $2}' | tr '.' '-')

# Construct output file name
if [ -n "$VERSION" ]; then
  OUTPUT_FILE="loggers-GpPlugins-v${VERSION}.json"
else
  OUTPUT_FILE="loggers-GpPlugins.json"
fi

if [ -f "$OUTPUT_FILE" ]; then
  echo "$OUTPUT_FILE already exists, aborting to avoid overwriting."
  exit 1
fi

# Match getLogger("...") or getLogger('...')
logger_names=$(grep -oE "getLogger\((\"[^\"]+\"|'[^']+')\)" "$SOURCE_FILE" | \
  sed -E "s/getLogger\([\"']([^\"']+)[\"']\)/\1/" | \
  sort -u)

# Build JSON array of objects with default level
jq -n --arg level "$DEFAULT_LEVEL" --argjson names "$(echo "$logger_names" | jq -R -s -c 'split("\n")[:-1]')" \
'[$names[] | {name: ., level: $level}]' > "$OUTPUT_FILE"

echo "Logger names extracted to $OUTPUT_FILE with default level $DEFAULT_LEVEL"

