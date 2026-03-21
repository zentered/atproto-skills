#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"
ERRORS=0
WARNINGS=0

red()    { printf '\033[0;31m%s\033[0m\n' "$*"; }
yellow() { printf '\033[0;33m%s\033[0m\n' "$*"; }
green()  { printf '\033[0;32m%s\033[0m\n' "$*"; }
bold()   { printf '\033[1m%s\033[0m\n' "$*"; }

fail() { red "  FAIL: $1"; ((ERRORS++)); }
warn() { yellow "  WARN: $1"; ((WARNINGS++)); }
pass() { green "  PASS: $1"; }

# Check plugin.json exists
bold "=== Plugin Structure ==="
if [[ -f "$REPO_ROOT/.claude-plugin/plugin.json" ]]; then
  pass "plugin.json exists"
else
  fail "missing .claude-plugin/plugin.json"
fi

# Check skills directory exists
if [[ -d "$SKILLS_DIR" ]]; then
  pass "skills/ directory exists"
else
  fail "missing skills/ directory"
  red "\nNo skills directory found. Aborting."
  exit 1
fi

# Iterate over each skill
for skill_dir in "$SKILLS_DIR"/*/; do
  skill_name="$(basename "$skill_dir")"
  bold "\n=== Skill: $skill_name ==="
  skill_md="$skill_dir/SKILL.md"

  # 1. SKILL.md exists
  if [[ ! -f "$skill_md" ]]; then
    fail "SKILL.md not found"
    continue
  fi
  pass "SKILL.md exists"

  # 2. Extract frontmatter
  frontmatter=$(sed -n '/^---$/,/^---$/p' "$skill_md" | sed '1d;$d')
  if [[ -z "$frontmatter" ]]; then
    fail "no YAML frontmatter found"
    continue
  fi
  pass "YAML frontmatter present"

  # 3. Check required fields
  name=$(echo "$frontmatter" | grep -E '^name:' | head -1 | sed 's/^name:[[:space:]]*//')
  description=$(echo "$frontmatter" | grep -E '^description:' | head -1 | sed 's/^description:[[:space:]]*//')

  if [[ -n "$name" ]]; then
    pass "name field: $name"
  else
    fail "missing 'name' in frontmatter"
  fi

  if [[ -n "$description" ]]; then
    pass "description field present"
  else
    fail "missing 'description' in frontmatter"
    continue
  fi

  # 4. Third-person description check
  if echo "$description" | grep -qi "This skill should be used when"; then
    pass "description uses third-person"
  else
    fail "description should start with 'This skill should be used when...'"
  fi

  # 5. Trigger phrases check (quoted phrases in description)
  trigger_count=$(echo "$description" | grep -o '"[^"]*"' | wc -l | tr -d ' ')
  if [[ "$trigger_count" -ge 3 ]]; then
    pass "description has $trigger_count trigger phrases"
  elif [[ "$trigger_count" -ge 1 ]]; then
    warn "description has only $trigger_count trigger phrase(s) (recommend 3+)"
  else
    fail "description has no quoted trigger phrases"
  fi

  # 6. Word count (body only, excluding frontmatter)
  body=$(awk 'BEGIN{n=0} /^---$/{n++; next} n>=2{print}' "$skill_md")
  word_count=$(echo "$body" | wc -w | tr -d ' ')
  if [[ "$word_count" -ge 500 && "$word_count" -le 3000 ]]; then
    pass "word count: $word_count (target: 500-3000)"
  elif [[ "$word_count" -lt 500 ]]; then
    warn "word count: $word_count (below 500 minimum)"
  else
    warn "word count: $word_count (above 3000, consider moving content to references/)"
  fi

  # 7. Check referenced files exist
  referenced_files=$(grep -oE '`references/[^`]+`|`scripts/[^`]+`|`examples/[^`]+`|`assets/[^`]+`' "$skill_md" | tr -d '`' | sort -u)
  if [[ -n "$referenced_files" ]]; then
    while IFS= read -r ref; do
      if [[ -f "$skill_dir/$ref" ]]; then
        pass "referenced file exists: $ref"
      else
        fail "referenced file missing: $ref"
      fi
    done <<< "$referenced_files"
  fi

  # 8. Check for orphaned resource files (exist but not referenced in SKILL.md)
  for subdir in references scripts examples assets; do
    if [[ -d "$skill_dir/$subdir" ]]; then
      for file in "$skill_dir/$subdir"/*; do
        [[ -f "$file" ]] || continue
        rel_path="$subdir/$(basename "$file")"
        if ! grep -q "$rel_path" "$skill_md"; then
          warn "orphaned file not referenced in SKILL.md: $rel_path"
        fi
      done
    fi
  done

  # 9. Second-person writing check (simple heuristic on body)
  second_person=$(echo "$body" | grep -ciE '\byou (should|need|can|must|will|may|might)\b' || true)
  if [[ "$second_person" -eq 0 ]]; then
    pass "no second-person writing detected"
  else
    warn "found ~$second_person second-person phrases (prefer imperative form)"
  fi
done

# Summary
bold "\n=== Summary ==="
if [[ "$ERRORS" -eq 0 && "$WARNINGS" -eq 0 ]]; then
  green "All checks passed!"
elif [[ "$ERRORS" -eq 0 ]]; then
  yellow "$WARNINGS warning(s), 0 errors"
else
  red "$ERRORS error(s), $WARNINGS warning(s)"
fi

exit "$ERRORS"
