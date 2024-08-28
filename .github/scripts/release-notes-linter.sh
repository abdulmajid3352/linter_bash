#!/bin/bash

# Allowed labels for curated release notes
ALLOWED_LABELS=("kind/bug-fix" "kind/feature" "kind/upgrade-consideration" "kind/breaking-change" "kind/api-change" "kind/deprecation" "impact/high" "impact/medium")

# Find changed files in the PR
changed_files=$(git diff --name-only --diff-filter=d origin/main)

# Function to check if an element is in an array
function contains() {
  local n=$#
  local value=${!n}
  for ((i=1;i < $#;i++)) {
    if [ "${!i}" == "${value}" ]; then
      return 0
    fi
  }
  return 1
}

# Loop through each changed file
for file in $changed_files; do
  if [[ $file == addons/* ]]; then
    # Check for raw and curated directories
    if [[ $file == *"/raw/"* ]] || [[ $file == *"/curated/"* ]]; then
      version_dir=$(echo "$file" | awk -F/ '{print $(NF-1)}')

      # Ensure directory starts with vX.X.X format
      if ! [[ $version_dir =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Directory $version_dir does not match the vX.X.X version format."
        exit 1
      fi
    fi

    # Check curated release notes for allowed labels
    if [[ $file == *"/curated/"* && $file == *.json ]]; then
      # Extract labels from JSON file
      labels=$(jq -r '.notes[].label[]' "$file")

      # Validate each label
      for label in $labels; do
        if ! contains "${ALLOWED_LABELS[@]}" "$label"; then
          echo "Error: Invalid label '$label' in file $file. Allowed labels are: ${ALLOWED_LABELS[*]}"
          exit 1
        fi
      done
    fi
  fi
done

echo "Linter passed successfully."
