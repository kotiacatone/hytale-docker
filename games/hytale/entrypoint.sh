#!/bin/bash
set -e
cd /home/container

echo "--- Hytale Server Setup (kotiacatone GitHub) ---"

if [[ "${FORCE_UPDATE}" == "1" ]]; then
    echo "Force update enabled: cleaning up old server files..."
    rm -rf Server Assets.zip mods config.json version
fi

if [[ ! -f "./hytale-downloader/hytale-downloader-linux" ]]; then
    echo "Error: Hytale Downloader not found! Проверьте скрипт установки."
    exit 1
fi

if [[ -z "$HYTALE_SERVER_SESSION_TOKEN" ]]; then
    if [[ ! -d "Server" || "${FORCE_UPDATE}" == "1" ]]; then
        if [[ ! -f "HytaleServer.zip" ]]; then
            echo "Downloading Hytale server files..."
            ./hytale-downloader/hytale-downloader-linux -patchline "$HYTALE_PATCHLINE" -download-path HytaleServer.zip
        fi

        if [[ -f "HytaleServer.zip" ]]; then
            echo "Extracting HytaleServer.zip..."
            unzip -o HytaleServer.zip -d .
        fi
    fi
fi

if [[ "${INSTALL_SOURCEQUERY_PLUGIN}" == "1" ]]; then
    if [[ ! -f "mods/hytale-sourcequery.jar" || "${FORCE_UPDATE}" == "1" ]]; then
        mkdir -p mods
        echo "Updating SourceQuery plugin..."
        LATEST_URL=$(curl -sSL https://api.github.com/repos/physgun-com/hytale-sourcequery/releases/latest | grep -oP '"browser_download_url":\s*"\K[^"]+\.jar' || true)
        if [[ -n "$LATEST_URL" ]]; then
            curl -sSL -o mods/hytale-sourcequery.jar "$LATEST_URL"
        fi
    fi
fi

if [[ -f config.json && -n "$HYTALE_MAX_VIEW_RADIUS" ]]; then
    jq ".MaxViewRadius = $HYTALE_MAX_VIEW_RADIUS" config.json > config.tmp.json && mv config.tmp.json config.json
fi

echo "--- Starting Hytale Server ---"

exec java $@
