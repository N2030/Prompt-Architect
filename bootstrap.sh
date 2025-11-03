cat > bootstrap.sh <<'SCRIPT_EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "==> START bootstrap"

: "${REPO_NAME:=prompt-architect}"
: "${DEFAULT_BRANCH:=main}"

ROOT="$(pwd)"
DEVCON=".devcontainer"
CLIENT="client"
SERVER="server"

echo "==> mkdir -p $DEVCON $CLIENT $SERVER"
mkdir -p "$DEVCON" "$CLIENT" "$SERVER"

echo "==> write server/requirements.txt"
if [ ! -f "$SERVER/requirements.txt" ]; then
  cat > "$SERVER/requirements.txt" <<'REQ'
flask
python-dotenv
google-generativeai
REQ
fi

echo "==> write .devcontainer/devcontainer.json"
cat > "$DEVCON/devcontainer.json" <<'JSON'
{
  "name": "Prompt Architect (React + Python)",
  "image": "mcr.microsoft.com/devcontainers/universal:2",
  "features": {
    "ghcr.io/devcontainers/features/node:1": { "version": "18" },
    "ghcr.io/devcontainers/features/python:1": { "version": "3.11" }
  },
  "forwardPorts": [3000, 5000],
  "portsAttributes": {
    "3000": { "label": "React App (Client)" },
    "5000": { "label": "Python API (Server)" }
  },
  "postCreateCommand": "bash .devcontainer/postCreate.sh",
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-python.vscode-pylance",
        "dbaeumer.vscode-eslint",
        "esbenp.prettier-vscode"
      ],
      "settings": {
        "editor.formatOnSave": true,
        "files.eol": "\n",
        "python.defaultInterpreterPath": "${workspaceFolder}/server/.venv/bin/python",
        "python.analysis.typeCheckingMode": "basic"
      }
    }
  },
  "remoteUser": "vscode"
}
JSON

echo "==> write .devcontainer/postCreate.sh"
cat > "$DEVCON/postCreate.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
echo "[postCreate] Python:"; python --version
echo "[postCreate] Node:"; node -v; npm -v

# Python server venv
cd "$WORKSPACE_FOLDER/server" 2>/dev/null || cd "$(pwd)/server"
[ -d ".venv" ] || python -m venv .venv
# shellcheck disable=SC1091
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements.txt
deactivate

# Client deps only if package.json exists
cd "$WORKSPACE_FOLDER/client" 2>/dev/null || cd "$(pwd)/client"
if [ -f package.json ]; then
  npm ci || npm install
else
  echo "[postCreate] client/package.json not found (skipping npm install)."
fi
echo "[postCreate] Done."
SH
chmod +x "$DEVCON/postCreate.sh"

echo "==> write .gitignore"
cat > ".gitignore" <<'GI'
# Node
node_modules/
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-lock.yaml
dist/
build/

# Python
__pycache__/
*.py[cod]
*.pyo
*.egg-info/
.pyt
