#!/bin/bash

# Dépôt Github
REPO="Neptune-Crypto/neptune-core"

# Fichier de stockage de la dernière version connue
VERSION_FILE="last_release.txt"

# Dossier où télécharger et exécuter le programme
DOWNLOAD_DIR="/home/user/neptune/neptune-cash-x86_64-unknown-linux-gnu"

# Nom du screen pour exécuter Neptune
SCREEN_NAME="neptune"

# Créer le dossier de téléchargement si il n'existe pas
mkdir -p "$DOWNLOAD_DIR"

while true; do
    # Récupérer la dernière version publiée
    LATEST_VERSION=$(curl -s https://api.github.com/$REPO/releases/latest | jq -r '.tag_name')

    # Lire la dernière version connue
    if [ -f "$VERSION_FILE" ]; then
        KNOWN_VERSION=$(cat "$VERSION_FILE")
    else
        KNOWN_VERSION=""
    fi

    # Comparer les versions
    if [ "$LATEST_VERSION" != "$KNOWN_VERSION" ]; then
        echo "Nouvelle release détectée: $LATEST_VERSION"
        echo "$LATEST_VERSION" > "$VERSION_FILE"

        # Télécharger la release
        DOWNLOAD_URL="https://github.com/Neptune-Crypto/neptune-core/releases/download/$LATEST_VERSION/neptune-cash-x86_64-unknown-linux-gnu.tar.xz"
        rm -rf /root/.local/share/neptune/main/blocks
        rm -rf /root/.local/share/neptune/main/databases

        if [ "$DOWNLOAD_URL" != "null" ]; then
            echo "Téléchargement de la nouvelle release..."
            FILE_NAME="neptune-cash-x86_64-unknown-linux-gnu.tar.xz"
            wget -O "$FILE_NAME" "$DOWNLOAD_URL"
            
            # Extraire le fichier
            tar -xvf "$FILE_NAME"
            echo "Extraction terminée."

            # Kill ancien screen si existe
            if screen -list | grep -q "$SCREEN_NAME"; then
                echo "Arrêt de l'ancienne session screen ($SCREEN_NAME)..."
                screen -S "$SCREEN_NAME" -X quit
            fi

            # Démarrer le programme mis à jour dans un nouveau screen
            echo "Démarrage de la nouvelle version..."
            cd "$DOWNLOAD_DIR" && screen -S "$SCREEN_NAME" -dm bash -c 'TVM_LDE_TRACE="no_cache" ./neptune-core --network main --listen-addr 0.0.0.0 --peers 51.15.139.238:9798 --peers 151.115.78.81:9798 --peers 185.25.224.220:9798 --peers 217.160.201.210:9798 --guess'
            echo "Mise à jour réussie avec la nouvelle version: $LATEST_VERSION"
        else
            echo "Aucun asset téléchargeable trouvé pour la release $LATEST_VERSION."
        fi
    else
        echo "Aucune nouvelle release. Dernière version connue: $KNOWN_VERSION"
    fi
    
    # Attendre 15 secondes avant la prochaine vérification
    sleep 15
done
