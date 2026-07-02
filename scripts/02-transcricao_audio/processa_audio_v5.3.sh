#!/bin/bash

# ==========================================================
# CONFIGURAÇÃO MANUAL - VERSÃO 5.3 (COM TEMPORIZADOR)
# Tenta: Modelos Gemini atualizados → Whisper
# Melhorias: Adicionado cronômetro visual durante a chamada da API
# ==========================================================
ARQUIVO_ENV="$HOME/bin/.env"
INPUT_FILE="$HOME/Downloads/audio.mp3"
OUTPUT_TRANSCRIPTION="$HOME/Downloads/transcricao.md"
OUTPUT_SUMMARY="$HOME/Downloads/resumo_notebooklm.md"

# Lista de modelos atualizada para 2026
MODELOS=("gemini-3-flash-preview" "gemini-2.5-flash" "gemini-2.0-flash" "gemini-2.0-flash-lite")
MODELO_ATUAL=""

# Intervalo aproximado entre timestamps em segundos
TIMESTAMP_INTERVAL=30

# Configuração de retry por modelo
MAX_API_RETRIES=2

# Timeouts para curl
CURL_TIMEOUT=180
CURL_CONNECT_TIMEOUT=30

# Modo verbose (ativado com -v)
VERBOSE=false
if [[ "$1" == "-v" ]] || [[ "$1" == "--verbose" ]]; then
    VERBOSE=true
fi
# ==========================================================

START_TIME=$SECONDS

# Função para obter tamanho do arquivo (compatível macOS/Linux)
get_file_size() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        stat -f%z "$1"
    else
        stat -c%s "$1"
    fi
}

# 1. Validações
echo "🔍 Validando arquivos..."

if [ ! -f "$ARQUIVO_ENV" ]; then
    echo "❌ Erro: Arquivo .env não encontrado em: $ARQUIVO_ENV"
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "❌ Erro: Arquivo de áudio não encontrado em: $INPUT_FILE"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "❌ Erro: 'jq' não está instalado."
    exit 1
fi

# 2. Extração da API Key
API_KEY=$(grep "^GEMINI_API_KEY=" "$ARQUIVO_ENV" | cut -d '=' -f2- | sed 's/"//g' | sed "s/'//g" | xargs)

if [ -z "$API_KEY" ]; then
    echo "❌ Erro: Variável GEMINI_API_KEY não encontrada no arquivo .env"
    exit 1
fi

FILE_SIZE=$(get_file_size "$INPUT_FILE")

echo "----------------------------------------------------------"
echo "🤖 Modelos disponíveis (em ordem de prioridade):"
for i in "${!MODELOS[@]}"; do
    echo "   $((i+1)). ${MODELOS[$i]}"
done
echo "   $((${#MODELOS[@]}+1)). Whisper (fallback final)"
echo "📝 VERSÃO 5.2.1 - Temporizador Ativo"
echo "🚀 Processando: $(basename "$INPUT_FILE")"
echo "----------------------------------------------------------"

# =========================================================
# FUNÇÃO PARA TRANSCRIÇÃO COM WHISPER (FALLBACK FINAL)
# =========================================================
transcribe_with_whisper() {
    echo ""
    echo "🎤 Iniciando transcrição com Whisper (fallback final)..."
    [ -f "$HOME/Downloads/audio.txt" ] && rm "$HOME/Downloads/audio.txt"
    WHISPER_START=$SECONDS

    if whisper "$INPUT_FILE" --model small --language Portuguese --output_format txt --output_dir ~/Downloads --fp16 False; then
        if [ -f "$HOME/Downloads/audio.txt" ]; then
            mv "$HOME/Downloads/audio.txt" "$OUTPUT_TRANSCRIPTION"
            WHISPER_DURATION=$((SECONDS - WHISPER_START))
            echo "✅ Transcrição com Whisper concluída em $((WHISPER_DURATION / 60))m $((WHISPER_DURATION % 60))s!"
            return 0
        fi
    fi
    return 1
}

# =========================================================
# FUNÇÃO DE CHAMADA DA API COM RETRY E TEMPORIZADOR
# =========================================================
call_gemini_api_with_fallback() {
    local PROMPT="$1"
    local MODELO_INDEX=0
    local RESPONSE=""

    while [ $MODELO_INDEX -lt ${#MODELOS[@]} ]; do
        MODELO_ATUAL="${MODELOS[$MODELO_INDEX]}"
        echo "🔄 Tentando com modelo: $MODELO_ATUAL" >&2

        local RETRY_COUNT=0
        local SUCCESS=false

        while [ $RETRY_COUNT -lt $MAX_API_RETRIES ]; do
            if [ "$VERBOSE" = true ]; then
                echo "   📡 Enviando requisição (tentativa $((RETRY_COUNT + 1))/$MAX_API_RETRIES)..." >&2
            fi

            # --- INÍCIO DO TEMPORIZADOR EM SEGUNDO PLANO ---
            (
                SEC=0
                while true; do
                    printf "\r   ⏳ Processando IA... (%ds)" $SEC >&2
                    sleep 1
                    ((SEC++))
                done
            ) &
            TIMER_PID=$!
            # -----------------------------------------------

            RESPONSE=$(curl -s -X POST \
                --max-time $CURL_TIMEOUT \
                --connect-timeout $CURL_CONNECT_TIMEOUT \
                "https://generativelanguage.googleapis.com/v1beta/models/${MODELO_ATUAL}:generateContent?key=${API_KEY}" \
                -H "Content-Type: application/json" \
                -d "{
                  \"contents\": [{
                    \"parts\": [
                      {\"text\": $(echo "$PROMPT" | jq -Rs .)},
                      {\"file_data\": {\"mime_type\": \"audio/mpeg\", \"file_uri\": \"$FILE_URI\"}}
                    ]
                  }],
                  \"generationConfig\": { \"temperature\": 0.2, \"maxOutputTokens\": 8192 }
                }")

            # Mata o temporizador assim que o curl termina
            kill $TIMER_PID 2>/dev/null
            wait $TIMER_PID 2>/dev/null
            printf "\r\033[K" >&2 # Limpa a linha do temporizador

            ERROR_MSG=$(echo "$RESPONSE" | jq -r '.error.message // empty' 2>/dev/null)
            ERROR_CODE=$(echo "$RESPONSE" | jq -r '.error.code // empty' 2>/dev/null)

            if [[ "$ERROR_CODE" == "429" ]]; then
                RETRY_COUNT=$((RETRY_COUNT + 1))
                sleep 5
            else
                TEXTO=$(echo "$RESPONSE" | jq -r '.candidates[0].content.parts[0].text // empty' 2>/dev/null)
                if [ -n "$TEXTO" ]; then
                    SUCCESS=true
                    break
                fi
                RETRY_COUNT=$((RETRY_COUNT + 1))
            fi
        done

        if [ "$SUCCESS" = true ]; then
            echo "   ✅ Sucesso com $MODELO_ATUAL!" >&2
            echo "$RESPONSE"
            return 0
        fi

        MODELO_INDEX=$((MODELO_INDEX + 1))
        [ $MODELO_INDEX -lt ${#MODELOS[@]} ] && sleep 2
    done
    return 1
}

# 3. Upload do Áudio (Lógica da v5.2)
echo "📤 Preparando upload para o Google Cloud..."
HEADERS_FILE=$(mktemp)

curl -s -D "$HEADERS_FILE" -X POST \
    --max-time 60 \
    --connect-timeout 30 \
    "https://generativelanguage.googleapis.com/upload/v1beta/files?key=${API_KEY}" \
    -H "X-Goog-Upload-Protocol: resumable" \
    -H "X-Goog-Upload-Command: start" \
    -H "X-Goog-Upload-Header-Content-Length: ${FILE_SIZE}" \
    -H "X-Goog-Upload-Header-Content-Type: audio/mpeg" \
    -H "Content-Type: application/json" \
    -d '{"file": {"display_name": "audio_job_v52"}}' > /dev/null

UPLOAD_URL=$(grep -i "x-goog-upload-url" "$HEADERS_FILE" | awk '{print $2}' | tr -d '\r' | tr -d '\n')
rm "$HEADERS_FILE"

echo "📤 Enviando bytes do arquivo..."
UPLOAD_RESULT=$(curl -s -X POST "$UPLOAD_URL" \
    --max-time 300 \
    -H "Content-Length: ${FILE_SIZE}" \
    -H "X-Goog-Upload-Offset: 0" \
    -H "X-Goog-Upload-Command: upload, finalize" \
    --data-binary @"$INPUT_FILE")

FILE_URI=$(echo "$UPLOAD_RESULT" | jq -r '.file.uri // empty')
FILE_NAME=$(echo "$UPLOAD_RESULT" | jq -r '.file.name // empty')

if [ -z "$FILE_URI" ]; then
    echo "❌ Erro no upload."
    exit 1
fi

echo "✅ Upload concluído: $FILE_NAME"

# 4. Verificação de Processamento
echo -n "⏳ Google processando o áudio"
while true; do
    STATUS=$(curl -s "https://generativelanguage.googleapis.com/v1beta/$FILE_NAME?key=$API_KEY" | jq -r '.state // empty')
    [ "$STATUS" == "ACTIVE" ] && break
    echo -n "."
    sleep 5
done
echo -e "\n✅ Áudio pronto para processamento!"

# 5. Gerar Transcrição
echo "🎯 [1/2] Gerando transcrição formatada com timestamps..."
read -r -d '' PROMPT_TRANSCRIPTION << 'EOF'
Transcreva este áudio em português brasileiro com timestamps [HH:MM:SS] a cada 30 segundos. Responda apenas com a transcrição.
EOF

RESPONSE_TRANSCRIPTION=$(call_gemini_api_with_fallback "$PROMPT_TRANSCRIPTION")

if [ $? -ne 0 ]; then
    transcribe_with_whisper
    USED_WHISPER=true
    MODELO_USADO="Whisper"
else
    echo "$RESPONSE_TRANSCRIPTION" | jq -r '.candidates[0].content.parts[0].text' > "$OUTPUT_TRANSCRIPTION"
    echo "✅ Transcrição salva!"
    USED_WHISPER=false
    MODELO_USADO="$MODELO_ATUAL"
fi

# 6. Gerar Resumo
if [ "$USED_WHISPER" = false ]; then
    echo "📚 [2/2] Gerando resumo NotebookLM..."
    read -r -d '' PROMPT_SUMMARY << 'EOF'
Crie um resumo detalhado ao estilo NotebookLM com tópicos e insights.
EOF
    RESPONSE_SUMMARY=$(call_gemini_api_with_fallback "$PROMPT_SUMMARY")
    echo "$RESPONSE_SUMMARY" | jq -r '.candidates[0].content.parts[0].text' > "$OUTPUT_SUMMARY"
    echo "✅ Resumo salvo!"
fi

echo "=========================================================="
echo "✨ CONCLUÍDO EM $((($SECONDS - $START_TIME) / 60))m $(($SECONDS % 60))s"
echo "=========================================================="
