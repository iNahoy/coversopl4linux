#!/bin/bash

# --- CONFIGURACIÓN ---
# 1. Ruta a la carpeta donde tus juegos de PS2 están en la unidad USB.
#    Si los juegos están en la raíz de la unidad USB (ej: ul.CODIGO.SLUS_ID.XX), apunta a la raíz.
GAMES_DIR="/run/media/USER_NAME/YPS2/"

# 2. Ruta a la carpeta ART de OPL en tu unidad USB.
#    Las carátulas se guardarán aquí. Esta carpeta generalmente está en la raíz de la unidad USB de OPL.
OPL_ART_DIR="/run/media/USER_NAME/DISKNAME/ART/"

# 3. URL base del repositorio de carátulas de GitHub para el formato JPG predeterminado.
#    Esta URL ahora apunta directamente al formato que has confirmado.
GITHUB_DEFAULT_JPG_URL="https://raw.githubusercontent.com/xlenore/ps2-covers/main/covers/default/"

echo "--- Iniciando la descarga de carátulas para OPL ---"
echo "Verificando juegos en: ${GAMES_DIR}"
echo "Guardando carátulas en: ${OPL_ART_DIR}"
echo "---"

# Asegura que la carpeta ART existe
mkdir -p "${OPL_ART_DIR}"

# Itera sobre cada archivo que comienza con "ul."
for GAME_FILE in "${GAMES_DIR}"ul.*; do
    # Verifica si hay archivos para procesar
    # También ignora ul.cfg, que no es un archivo de juego.
    if [ ! -f "$GAME_FILE" ] || [[ "$GAME_FILE" =~ \.cfg$ ]]; then
        continue
    fi

    GAME_BASENAME=$(basename "$GAME_FILE")
    echo "Procesando: ${GAME_BASENAME}"

    # --- LÓGICA DE EXTRACCIÓN Y REFORMATEO DEL ID ---
    # Extrae el ID del juego usando 'cut'. El ID completo es la unión del 3er y 4to campo.
    # Ej: ul.1A595FC6.SLUS_217.82.00 -> GAME_ID_PART1=SLUS_217, GAME_ID_PART2=82
    GAME_ID_PART1=$(echo "$GAME_BASENAME" | cut -d'.' -f3)
    GAME_ID_PART2=$(echo "$GAME_BASENAME" | cut -d'.' -f4)
    RAW_GAME_ID="${GAME_ID_PART1}.${GAME_ID_PART2}" # Ej: SLUS_217.82 (Formato OPL)

    # Convierte el ID al formato del repositorio: SLUS-XXXXX
    # Ej: SLUS_217.82 -> SLUS-21782
    FORMATTED_GAME_ID=$(echo "$RAW_GAME_ID" | tr '_' '-' | tr -d '.')


    # Una verificación básica para asegurar que el ID formateado no está vacío y parece un ID de juego.
    if [[ -n "$FORMATTED_GAME_ID" && "$FORMATTED_GAME_ID" =~ ^S[A-Z]+-[0-9]+$ ]]; then
        echo "  ID del Juego encontrado (OPL): ${RAW_GAME_ID}"
        echo "  ID del Juego formateado (Repositorio): ${FORMATTED_GAME_ID}"

        # El nombre del archivo para OPL aún usa el RAW_GAME_ID y la extensión .JPG
        COVER_FILE_NAME="${RAW_GAME_ID}_COV.JPG"
        OUTPUT_PATH="${OPL_ART_DIR}${COVER_FILE_NAME}" # Ruta completa para guardar la carátula

        # Verifica si la carátula ya existe en la carpeta ART para evitar descargas repetidas
        if [ -f "$OUTPUT_PATH" ]; then
            echo "  Carátula ya existe para ${RAW_GAME_ID}. Saltando."
            continue
        fi

        # URL para descargar la carátula del repositorio (usando el ID formateado)
        DOWNLOAD_URL="${GITHUB_DEFAULT_JPG_URL}${FORMATTED_GAME_ID}.jpg"

        echo "  Intentando descargar desde: ${DOWNLOAD_URL}"
        # Descarga la carátula usando wget
        wget -q -O "${OUTPUT_PATH}" "${DOWNLOAD_URL}"

        if [ $? -eq 0 ]; then
            echo "  Carátula descargada con éxito: ${COVER_FILE_NAME}"
        else
            echo "  Error o carátula no encontrada para ${RAW_GAME_ID} en el repositorio predeterminado. Verifica el ID en GitHub."
            rm -f "${OUTPUT_PATH}" # Elimina el archivo vacío o incompleto si la descarga falló
        fi
    else
        echo "  No se pudo extraer o formatear un ID de juego válido de: ${GAME_BASENAME}. Saltando."
    fi
    echo "---"
done

echo "--- Proceso de descarga de carátulas completado ---"
