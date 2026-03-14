#!/bin/bash
# Загрузка Legday-macOS-1.0.0.zip в релиз v1.0.0 на GitHub.
# Нужен GITHUB_TOKEN с правом repo (Settings → Developer settings → Personal access tokens).

set -e
REPO="lyucean/Legday"
TAG="v1.0.0"
ZIP="Legday-macOS-1.0.0.zip"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ARCHIVE="${SCRIPT_DIR}/../release/${ZIP}"

if [ -z "$GITHUB_TOKEN" ]; then
  echo "Задайте GITHUB_TOKEN: export GITHUB_TOKEN=ghp_..."
  exit 1
fi
if [ ! -f "$ARCHIVE" ]; then
  echo "Не найден архив: $ARCHIVE"
  exit 1
fi

RELEASE_JSON=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/${REPO}/releases/tags/${TAG}")
RELEASE_ID=$(echo "$RELEASE_JSON" | grep '"id":' | head -1 | sed 's/.*: *\([0-9]*\).*/\1/')
UPLOAD_URL="https://uploads.github.com/repos/${REPO}/releases/${RELEASE_ID}/assets?name=${ZIP}"

echo "Загрузка ${ZIP} в релиз ${TAG}..."
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/zip" \
  --data-binary "@${ARCHIVE}" \
  "$UPLOAD_URL" | grep -q '"browser_download_url"' && echo "Готово." || (echo "Ошибка загрузки."; exit 1)
