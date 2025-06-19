#!/bin/bash

# --- CONFIGURAÇÕES ---
# 1. Caminho para a pasta onde seus jogos de PS2 estão no pendrive.
#    Se os jogos estão na raiz do pendrive (ex: ul.CODIGO.SLUS_ID.XX), aponte para a raiz.
GAMES_DIR="/run/media/USER_NAME/YPS2/"

# 2. Caminho para a pasta ART do OPL no seu pendrive.
#    As capas serão salvas aqui. Esta pasta geralmente fica na raiz do pendrive do OPL.
OPL_ART_DIR="/run/media/USER_NAME/DISKNAME/ART/"

# 3. URL base do repositório de capas do GitHub para o formato Default JPG.
#    Esta URL agora aponta diretamente para o formato que você confirmou.
GITHUB_DEFAULT_JPG_URL="https://raw.githubusercontent.com/xlenore/ps2-covers/main/covers/default/"

echo "--- Iniciando o download de capas para o OPL ---"
echo "Verificando jogos em: ${GAMES_DIR}"
echo "Salvando capas em: ${OPL_ART_DIR}"
echo "---"

# Garante que a pasta ART existe
mkdir -p "${OPL_ART_DIR}"

# Itera sobre cada arquivo que começa com "ul."
for GAME_FILE in "${GAMES_DIR}"ul.*; do
    # Verifica se há arquivos para processar
    # Também ignora o ul.cfg, que não é um arquivo de jogo.
    if [ ! -f "$GAME_FILE" ] || [[ "$GAME_FILE" =~ \.cfg$ ]]; then
        continue
    fi

    GAME_BASENAME=$(basename "$GAME_FILE")
    echo "Processando: ${GAME_BASENAME}"

    # --- LÓGICA DE EXTRAÇÃO E REFORMATAÇÃO DO ID ---
    # Extrai o ID do jogo usando 'cut'. O ID completo é a junção do 3º e 4º campo.
    # Ex: ul.1A595FC6.SLUS_217.82.00 -> GAME_ID_PART1=SLUS_217, GAME_ID_PART2=82
    GAME_ID_PART1=$(echo "$GAME_BASENAME" | cut -d'.' -f3)
    GAME_ID_PART2=$(echo "$GAME_BASENAME" | cut -d'.' -f4)
    RAW_GAME_ID="${GAME_ID_PART1}.${GAME_ID_PART2}" # Ex: SLUS_217.82 (Formato OPL)

    # Converte o ID para o formato do repositório: SLUS-XXXXX
    # Ex: SLUS_217.82 -> SLUS-21782
    FORMATTED_GAME_ID=$(echo "$RAW_GAME_ID" | tr '_' '-' | tr -d '.')


    # Uma verificação básica para garantir que o ID formatado não está vazio e parece um ID de jogo.
    if [[ -n "$FORMATTED_GAME_ID" && "$FORMATTED_GAME_ID" =~ ^S[A-Z]+-[0-9]+$ ]]; then
        echo "  ID do Jogo encontrado (OPL): ${RAW_GAME_ID}"
        echo "  ID do Jogo formatado (Repositório): ${FORMATTED_GAME_ID}"

        # O nome do arquivo para o OPL ainda usa o RAW_GAME_ID e a extensão .JPG
        COVER_FILE_NAME="${RAW_GAME_ID}_COV.JPG"
        OUTPUT_PATH="${OPL_ART_DIR}${COVER_FILE_NAME}" # Caminho completo para salvar a capa

        # Verifica se a capa já existe na pasta ART para evitar download repetido
        if [ -f "$OUTPUT_PATH" ]; then
            echo "  Capa já existe para ${RAW_GAME_ID}. Pulando."
            continue
        fi

        # URL para baixar a capa do repositório (usando o ID formatado)
        DOWNLOAD_URL="${GITHUB_DEFAULT_JPG_URL}${FORMATTED_GAME_ID}.jpg"

        echo "  Tentando baixar de: ${DOWNLOAD_URL}"
        # Baixa a capa usando wget
        wget -q -O "${OUTPUT_PATH}" "${DOWNLOAD_URL}"

        if [ $? -eq 0 ]; then
            echo "  Capa baixada com sucesso: ${COVER_FILE_NAME}"
        else
            echo "  Erro ou capa não encontrada para ${RAW_GAME_ID} no repositório default. Verifique o ID no GitHub."
            rm -f "${OUTPUT_PATH}" # Remove o arquivo vazio ou incompleto se o download falhou
        fi
    else
        echo "  Não foi possível extrair ou formatar um ID de jogo válido de: ${GAME_BASENAME}. Pulando."
    fi
    echo "---"
done

echo "--- Processo de download de capas concluído ---"
