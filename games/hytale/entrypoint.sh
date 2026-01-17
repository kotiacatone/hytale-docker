#!/bin/bash
set -e
cd /home/container

echo "Starting Hytale server setup..."

# Если включён принудительное обновление — очищаем старые файлы
if [[ "${FORCE_UPDATE}" == "1" ]]; then
    echo "Force update enabled: removing old server files..."
    rm -rf Server Assets.zip HytaleServer.zip mods config.json
fi

# Основная логика установки/обновления файлов сервера
if [[ -z "$HYTALE_SERVER_SESSION_TOKEN" ]]; then
    # Если серверные файлы уже есть — пропускаем скачивание
    if [[ -f "Server/HytaleServer.jar" ]]; then
        echo "Server files already present — skipping download."
    else
        echo "Downloading Hytale server files..."
        ./hytale-downloader/hytale-downloader-linux -patchline "$HYTALE_PATCHLINE" -download-path HytaleServer.zip
        
        if [[ -f "HytaleServer.zip" ]]; then
            echo "Unpacking HytaleServer.zip..."
            unzip -o HytaleServer.zip -d .
            # НЕ удаляем zip — оставляем для будущих распаковок
        else
            echo "Error: Failed to download HytaleServer.zip"
            exit 1
        fi
    fi
elif [[ -f "HytaleMount/HytaleServer.zip" ]]; then
    echo "Using mounted HytaleServer.zip..."
    unzip -o HytaleMount/HytaleServer.zip -d .
elif [[ -f "HytaleMount/Assets.zip" ]]; then
    ln -s -f HytaleMount/Assets.zip Assets.zip
elif [[ -f "Server/Assets.zip" ]]; then
    ln -s -f Server/Assets.zip Assets.zip
elif [[ -f "HytaleServer.zip" ]]; then
    echo "Using existing HytaleServer.zip..."
    unzip -o HytaleServer.zip -d .
fi

# Установка плагина sourcequery (только если нужно)
if [[ "${INSTALL_SOURCEQUERY_PLUGIN}" == "1" ]]; then
    if [[ -f "mods/hytale-sourcequery.jar" && "${FORCE_UPDATE}" != "1" ]]; then
        echo "SourceQuery plugin already installed — skipping download."
    else
        mkdir -p mods
        echo "Downloading latest hytale-sourcequery plugin..."
        LATEST_URL=$(curl -sSL https://api.github.com/repos/physgun-com/hytale-sourcequery/releases/latest \
        | grep -oP '"browser_download_url":\s*"\K[^"]+\.jar' || true)
        if [[ -n "$LATEST_URL" ]]; then
            curl -sSL -o mods/hytale-sourcequery.jar "$LATEST_URL"
            echo "Successfully installed hytale-sourcequery plugin."
        else
            echo "Warning: Could not find hytale-sourcequery plugin download URL."
        fi
    fi
fi

# Применение MaxViewRadius, если указано
if [[ -f config.json && -n "$HYTALE_MAX_VIEW_RADIUS" ]]; then
    jq ".MaxViewRadius = $HYTALE_MAX_VIEW_RADIUS" config.json > config.tmp.json && mv config.tmp.json config.json
    echo "MaxViewRadius set to $HYTALE_MAX_VIEW_RADIUS"
fi

echo "Setup complete. Starting server..."
/java.sh $@
