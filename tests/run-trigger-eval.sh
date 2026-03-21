#!/usr/bin/env bash
set -euo pipefail

# Evaluates trigger-evals.yaml by scoring keyword overlap between
# each prompt and skill descriptions+body. Heuristic signal for
# whether descriptions contain the right trigger terms.

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"
EVALS="$REPO_ROOT/tests/trigger-evals.yaml"

red()    { printf '\033[0;31m%s\033[0m\n' "$*"; }
yellow() { printf '\033[0;33m%s\033[0m\n' "$*"; }
green()  { printf '\033[0;32m%s\033[0m\n' "$*"; }
bold()   { printf '\033[1m%s\033[0m\n' "$*"; }

# Collect skill names and build temp files with their searchable text
SKILL_NAMES=()
TMPDIR_EVAL=$(mktemp -d)
trap 'rm -rf "$TMPDIR_EVAL"' EXIT

for skill_dir in "$SKILLS_DIR"/*/; do
  name="$(basename "$skill_dir")"
  SKILL_NAMES+=("$name")
  {
    # description line
    awk 'BEGIN{n=0} /^---$/{n++; next} n==1{print}' "$skill_dir/SKILL.md" | grep -i '^description:' | sed 's/^description:[[:space:]]*//'
    # body
    awk 'BEGIN{n=0} /^---$/{n++; next} n>=2{print}' "$skill_dir/SKILL.md"
  } | tr '[:upper:]' '[:lower:]' > "$TMPDIR_EVAL/$name.txt"
done

# Score: count how many 4+ char words from the prompt appear in skill text
score_match() {
  local prompt="$1"
  local skill_file="$2"
  local score=0
  for word in $prompt; do
    [[ ${#word} -lt 4 ]] && continue
    word_lower=$(echo "$word" | tr '[:upper:]' '[:lower:]')
    if grep -qi "$word_lower" "$skill_file" 2>/dev/null; then
      ((score++)) || true
    fi
  done
  echo "$score"
}

TOTAL=0
CORRECT=0
WRONG=0
TIES=0

bold "=== Trigger Evaluation ==="
echo ""

eval_case() {
  local prompt="$1"
  local expected="$2"
  local notes="$3"

  ((TOTAL++)) || true

  local best_skill=""
  local best_score=0
  local second_score=0
  local scores=""

  for skill in "${SKILL_NAMES[@]}"; do
    local s
    s=$(score_match "$prompt" "$TMPDIR_EVAL/$skill.txt")
    scores="$scores $skill=$s"
    if [[ "$s" -gt "$best_score" ]]; then
      second_score=$best_score
      best_score=$s
      best_skill=$skill
    elif [[ "$s" -gt "$second_score" ]]; then
      second_score=$s
    fi
  done

  local margin=$((best_score - second_score))

  if [[ "$best_skill" == "$expected" ]]; then
    if [[ "$margin" -le 1 ]]; then
      yellow "  WEAK  \"$prompt\""
      yellow "        → $best_skill (margin: $margin) [$scores ]"
      ((CORRECT++)) || true
    else
      green "  PASS  \"$prompt\""
      green "        → $best_skill (margin: $margin)"
      ((CORRECT++)) || true
    fi
  else
    if [[ "$margin" -le 1 ]]; then
      yellow "  TIE   \"$prompt\""
      yellow "        → got $best_skill, expected $expected (margin: $margin) [$scores ]"
      [[ -n "$notes" ]] && yellow "        notes: $notes"
      ((TIES++)) || true
    else
      red "  FAIL  \"$prompt\""
      red "        → got $best_skill, expected $expected (margin: $margin) [$scores ]"
      [[ -n "$notes" ]] && red "        notes: $notes"
      ((WRONG++)) || true
    fi
  fi
}

# Parse YAML
current_prompt=""
current_expected=""
current_notes=""

while IFS= read -r line; do
  trimmed="${line#"${line%%[![:space:]]*}"}"

  if [[ "$trimmed" =~ ^-\ prompt:\ *(.*) ]]; then
    if [[ -n "$current_prompt" ]]; then
      eval_case "$current_prompt" "$current_expected" "$current_notes"
    fi
    current_prompt="${BASH_REMATCH[1]}"
    current_prompt="${current_prompt#\"}"
    current_prompt="${current_prompt%\"}"
    current_expected=""
    current_notes=""
  elif [[ "$trimmed" =~ ^expected:\ *(.*) ]]; then
    current_expected="${BASH_REMATCH[1]}"
  elif [[ "$trimmed" =~ ^notes:\ *(.*) ]]; then
    current_notes="${BASH_REMATCH[1]}"
    current_notes="${current_notes#\"}"
    current_notes="${current_notes%\"}"
  fi
done < "$EVALS"

if [[ -n "$current_prompt" ]]; then
  eval_case "$current_prompt" "$current_expected" "$current_notes"
fi

echo ""
bold "=== Results ==="
echo "Total: $TOTAL"
green "Correct: $CORRECT"
[[ "$TIES" -gt 0 ]] && yellow "Ties: $TIES (margin ≤1, ambiguous)"
[[ "$WRONG" -gt 0 ]] && red "Wrong: $WRONG"

SCORE=$((CORRECT * 100 / TOTAL))
echo ""
if [[ "$WRONG" -eq 0 ]]; then
  green "Score: ${SCORE}% ($CORRECT/$TOTAL correct, $TIES ties)"
else
  yellow "Score: ${SCORE}% ($CORRECT/$TOTAL correct, $WRONG wrong, $TIES ties)"
fi
