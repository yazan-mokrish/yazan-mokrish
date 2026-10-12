#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

REPO="yazan-mokrish/haqibat-workspace"
BASE="$HOME/.haqibat-agent"
mkdir -p "$BASE"

echo "=== HAQIBAT BOOTSTRAP ==="
echo "DATE=$(date -Is)"

need=(gh jq curl coreutils)
echo "Installing required packages..."
timeout 300s pkg install -y "${need[@]}" || true

for c in gh jq curl base64; do
  command -v "$c" >/dev/null 2>&1 || { echo "ERROR=MISSING_$c"; exit 2; }
done

if ! gh auth status >/dev/null 2>&1; then
  echo "GITHUB_LOGIN_REQUIRED=YES"
  echo "A browser/device login will open once. Complete it with the yazan-mokrish account."
  gh auth login --hostname github.com --git-protocol https --web
fi

gh auth status >/dev/null 2>&1 || { echo "ERROR=GITHUB_AUTH_FAILED"; exit 3; }
gh api "repos/$REPO" >/dev/null || { echo "ERROR=PRIVATE_REPO_ACCESS_FAILED"; exit 4; }

echo "Downloading private agent..."
gh api "repos/$REPO/contents/termux/agent/haqibat-agent.sh?ref=main" --jq .content | tr -d '\n' | base64 -d > "$BASE/haqibat-agent.sh"
chmod 700 "$BASE/haqibat-agent.sh"

"$BASE/haqibat-agent.sh" install
"$BASE/haqibat-agent.sh" once || true

echo
echo "========== FINISHED =========="
"$BASE/haqibat-agent.sh" status
echo "CONTROL_REPO=$REPO"
echo "NEXT=Leave Termux installed; the agent checks GitHub for approved jobs every 30 seconds."
command -v termux-clipboard-set >/dev/null 2>&1 && {
  R="$BASE/bootstrap-result.txt"
  {
    echo "HAQIBAT_BOOTSTRAP=SUCCESS"
    "$BASE/haqibat-agent.sh" status
    echo "CONTROL_REPO=$REPO"
  } > "$R"
  timeout 8s termux-clipboard-set < "$R" >/dev/null 2>&1 || true
}
printf '\a'
