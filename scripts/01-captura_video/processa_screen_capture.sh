#!/bin/bash

rm ~/Imagens/vlcsnap-*.jpg; 
rm ~/Downloads/debug_*.* ; 
rm ~/Downloads/esqueleto.md \ 
~/Downloads/esqueleto_enriquecido.* \
~/Downloads/imagens.pdf \
~/Downloads/transcricao.md \
~/Downloads/resumo_notebooklm.md; 
clear;

###############################################################################
# 🚀 NOME: processa_screen_capture.sh
# O que este script faz:
#   1. Repara o container do vídeo .webm via ffmpeg.
#   2. Lê configurações de trilha, módulo e curso de 'processa_screen_capture.cfg'.
#   3. Identifica o próximo índice de vídeo (video_01, video_02...).
#   4. Renomeia o vídeo e extrai o áudio para ~/Downloads/audio.mp3.
#
# 🛠 REQUISITOS: ffmpeg, arquivo .cfg e vídeo no Downloads.
###############################################################################

# Cores para o terminal
VERDE='\033[0;32m'
AZUL='\033[0;34m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
NC='\033[0m' # Sem cor

# --- CONFIGURAÇÕES DE CAMINHO ---
ARQUIVO_ENTRADA="$HOME/Downloads/screen-capture.webm"
ARQUIVO_FIXADO_TMP="$HOME/Downloads/screen-capture-fixed.mkv"
ARQUIVO_FINAL_TMP="./screen-capture-fixed.webm"
ARQUIVO_AUDIO_SAIDA="$HOME/Downloads/audio.mp3"
CONFIG_FILE="processa_screen_capture.cfg"

echo -e "${AZUL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "🎬  ${AMARELO}Iniciando o Processamento da Aula${NC}"
echo -e "${AZUL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 1. Validação
echo -e "🔍 [1/6] Verificando se o vídeo está em Downloads..."
if [ ! -f "$ARQUIVO_ENTRADA" ]; then
    echo -e "❌ ${VERMELHO}Erro: O arquivo 'screen-capture.webm' não foi encontrado.${NC}"
    exit 1
fi
echo -e "    ✅ Vídeo localizado!"

# 2. ffmpeg Reparo
echo -e "🛠️  [2/6] Corrigindo timestamps do vídeo (ffmpeg)..."
ffmpeg -fflags +genpts -i "$ARQUIVO_ENTRADA" -c copy "$ARQUIVO_FIXADO_TMP" -loglevel error
mv "$ARQUIVO_FIXADO_TMP" "$ARQUIVO_FINAL_TMP"
rm "$ARQUIVO_ENTRADA"
echo -e "    ✅ Vídeo estabilizado e movido para a pasta de trabalho."

# 3. Configurações
echo -e "📋 [3/6] Lendo arquivo de configuração..."
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    nome_da_trilha=$(echo $nome_da_trilha | xargs)
    modulo=$(echo $modulo | xargs)
    curso=$(echo $curso | xargs)
    echo -e "    ✅ Configurações carregadas: ${AMARELO}$nome_da_trilha${NC}"
else
    echo -e "❌ ${VERMELHO}Erro: Arquivo '$CONFIG_FILE' não encontrado.${NC}"
    exit 1
fi

# 4. Índice
echo -e "🔢 [4/6] Calculando o próximo número da sequência..."
indice=1
while true; do
    idx_formatado=$(printf "%02d" $indice)
    NOME_DESTINO="${nome_da_trilha}-modulo.${modulo}-curso.${curso}-video_${idx_formatado}.webm"
    if [ ! -f "$NOME_DESTINO" ]; then break; fi
    indice=$((indice + 1))
done
echo -e "    ✅ O próximo arquivo será o de número: ${AMARELO}$idx_formatado${NC}"

# 5. Renomear
echo -e "🏷️  [5/6] Aplicando nome oficial ao arquivo..."
mv "$ARQUIVO_FINAL_TMP" "$NOME_DESTINO"
echo -e "    ✅ Pronto: ${VERDE}$NOME_DESTINO${NC}"

# 6. Áudio
echo -e "🎵 [6/6] Extraindo áudio para revisão..."
[ -f "$ARQUIVO_AUDIO_SAIDA" ] && rm "$ARQUIVO_AUDIO_SAIDA"
ffmpeg -i "$NOME_DESTINO" -vn -acodec libmp3lame "$ARQUIVO_AUDIO_SAIDA" -loglevel error
echo -e "    ✅ Áudio salvo em: ${VERDE}~/Downloads/audio.mp3${NC}"

echo -e "${AZUL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "✨  ${VERDE}Terminado!"
echo -e "${AZUL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
