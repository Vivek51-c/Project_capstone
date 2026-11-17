#!/bin/bash
set -e

echo "=========================================="
echo " Flutter Web Build on Vercel"
echo "=========================================="

# Avoid Git dubious ownership error in containerized CI environments
git config --global --add safe.directory '*' 2>/dev/null || true

# 1. Install Flutter if not in PATH
if ! command -v flutter &> /dev/null; then
  echo "Flutter not found in PATH. Checking $HOME/flutter..."
  if [ ! -d "$HOME/flutter" ]; then
    echo "Cloning Flutter stable SDK (depth 1)..."
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
  fi
  export PATH="$PATH:$HOME/flutter/bin"
  export FLUTTER_ROOT="$HOME/flutter"
fi

export PUB_CACHE="$HOME/.pub-cache"

echo "Flutter version:"
flutter --version

# Precache only Web engine artifacts (skips Android/iOS/Desktop)
echo "Precaching Web engine artifacts..."
flutter precache --web

# 2. Setup .env file
if [ ! -f .env ]; then
  if [ -n "$API_BASE_URL" ]; then
    echo "Creating .env from Vercel environment variables..."
    echo "API_BASE_URL=$API_BASE_URL" > .env
    echo "APP_ENV=${APP_ENV:-production}" >> .env
    echo "API_TIMEOUT_SECONDS=${API_TIMEOUT_SECONDS:-60}" >> .env
  elif [ -f .env.example ]; then
    echo "Creating .env from .env.example..."
    cp .env.example .env
  else
    echo "Touching default .env..."
    echo "API_BASE_URL=https://opportune-jobmate-api.onrender.com" > .env
    echo "APP_ENV=production" >> .env
    echo "API_TIMEOUT_SECONDS=60" >> .env
  fi
fi

# 3. Resolve dependencies
echo "Running flutter pub get..."
flutter pub get

# 4. Build Flutter Web release
echo "Running flutter build web --release..."
DART_DEFINES=""
if [ -n "$API_BASE_URL" ]; then
  DART_DEFINES="$DART_DEFINES --dart-define=API_BASE_URL=$API_BASE_URL"
fi
if [ -n "$APP_ENV" ]; then
  DART_DEFINES="$DART_DEFINES --dart-define=APP_ENV=$APP_ENV"
fi
if [ -n "$API_TIMEOUT_SECONDS" ]; then
  DART_DEFINES="$DART_DEFINES --dart-define=API_TIMEOUT_SECONDS=$API_TIMEOUT_SECONDS"
fi

flutter build web --release --base-href "/" --no-wasm-dry-run $DART_DEFINES

# 5. Verify build output
if [ -f "build/web/index.html" ]; then
  echo "=========================================="
  echo " Flutter Web build succeeded!"
  echo " Output ready at build/web"
  echo "=========================================="
else
  echo "Error: build/web/index.html not found!"
  exit 1
fi
