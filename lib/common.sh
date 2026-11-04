# Helpers shared by every step script. Sourced, never executed.

trap 'exit 1' ERR

PROC_NR=$(getconf _NPROCESSORS_ONLN)

# fetch_source <url> <ref> [ref-override]: clones or updates into ./<repo-name>, sets REPO_FOLDER.
fetch_source() {
  local repo_url="$1" repo_ref="$2" ref_override="$3"
  if test -n "$ref_override"; then
    repo_ref="$ref_override"
    printf 'Using requested ref %s\n' "$repo_ref"
  fi

  REPO_FOLDER="$(basename "$repo_url" .git)"

  if test ! -d "$REPO_FOLDER"; then
    git clone --depth 1 -b "$repo_ref" "$repo_url" "$REPO_FOLDER"
    return
  fi

  local have want
  have="$(git -C "$REPO_FOLDER" rev-parse HEAD 2>/dev/null)"
  # ^{} peels an annotated tag to its commit.
  want="$(git ls-remote "$repo_url" "$repo_ref" "$repo_ref^{}" 2>/dev/null | cut -f1 | tail -1)"

  if test -n "$have" && test "$have" = "$want"; then
    printf 'Already at %s (%s)\n' "$repo_ref" "$have"
    return
  fi

  git -C "$REPO_FOLDER" remote set-url origin "$repo_url"
  git -C "$REPO_FOLDER" fetch origin "$repo_ref" --depth=1
  git -C "$REPO_FOLDER" checkout -f FETCH_HEAD
}

check_dependencies() {
  local missing=0 tool
  for tool in git make gcc cmake ninja python3; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      printf 'Missing required tool: %s\n' "$tool" >&2
      missing=1
    fi
  done
  if test "$missing" -ne 0; then
    printf 'Install the tool(s) above before continuing.
' >&2
    exit 1
  fi
}

# run_build <url> <ref> [<url> <ref> ...] -- "$@"
# Fetches every source first so a bad ref fails before any compile, then runs steps/*.sh in order, or only the
# step numbers given in "$@".
run_build() {
  local urls=() refs=()
  while test "$1" != "--"; do
    if test "$#" -lt 2; then
      echo "run_build: malformed fetch list (missing -- terminator)" >&2
      exit 1
    fi
    urls+=("$1")
    refs+=("$2")
    shift 2
  done
  shift

  check_dependencies

  BUILD_ROOT="${BUILD_ROOT:-$TARGET_DIR/build}"
  mkdir -p "$BUILD_ROOT"
  cd "$BUILD_ROOT"

  echo "=== Fetching all sources ==="
  local i
  for ((i = 0; i < ${#urls[@]}; i++)); do
    fetch_source "${urls[$i]}" "${refs[$i]}" ""
  done

  STEPS=($(ls "$TARGET_DIR/steps/"*.sh | sort))

  if test "$#" -gt 0; then
    for n in "$@"; do
      "${STEPS[$((n - 1))]}" || { echo "${STEPS[$((n - 1))]}: failed"; exit 1; }
    done
  else
    for step in "${STEPS[@]}"; do
      "$step" || { echo "$step: failed"; exit 1; }
    done
  fi
}
