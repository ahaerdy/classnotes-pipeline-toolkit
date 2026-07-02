#!/bin/bash

###############################################################################
# 🚀 NOME: organizar_projeto.sh
# 📝 DESCRIÇÃO:
#   1. Copia arquivos .jpg de ~/Imagens para a pasta atual.
#   2. Executa a sequência de comandos (via PATH):
#      - pp_gera_esqueleto.py
#      - pp_classifica_imagens.py
#      - pp_gera_pdf.py
###############################################################################

# Cores para o terminal
VERDE='\033[0;32m'
AZUL='\033[0;34m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
NC='\033[0m' # Sem cor

echo -e "${AZUL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "📸  ${AMARELO}Iniciando Fluxo de Documentação de Aula${NC}"
echo -e "${AZUL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 1. Copiar Imagens
echo -e "📂 [1/4] Coletando imagens JPG de ~/Imagens..."
# O redirecionamento 2>/dev/null evita mensagem de erro se a pasta estiver vazia
if cp ~/Imagens/*.jpg . 2>/dev/null; then
    echo -e "    ✅ Imagens copiadas para a pasta atual."
else
    echo -e "    ⚠️  ${AMARELO}Aviso:${NC} Nenhuma imagem .jpg encontrada para copiar."
fi

# 2. Gerar Esqueleto
echo -e "🏗️  [2/4] Executando: pp_gera_esqueleto.py..."
if pp_gera_esqueleto.py; then
    echo -e "    ✅ Estrutura criada com sucesso."
else
    echo -e "    ❌ ${VERMELHO}Erro ao executar pp_gera_esqueleto.py.${NC}"
    exit 1
fi

# 3. Classificar Imagens
echo -e "🏷️  [3/4] Executando: pp_classifica_imagens.py..."
if pp_classifica_imagens.py; then
    echo -e "    ✅ Imagens classificadas."
else
    echo -e "    ❌ ${VERMELHO}Erro ao executar pp_classifica_imagens.py.${NC}"
    exit 1
fi

# 4. Gerar PDF
echo -e "📄 [4/4] Executando: pp_gera_pdf.py..."
if pp_gera_pdf.py; then
    echo -e "    ✅ PDF gerado com sucesso!"
else
    echo -e "    ❌ ${VERMELHO}Erro ao executar pp_gera_pdf.py.${NC}"
    exit 1
fi

cp ~/Downloads/esqueleto_enriquecido.md ~/Downloads/esqueleto_enriquecido.txt

echo -e "${AZUL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "✨  ${VERDE}Fluxo finalizado com sucesso!${NC}  🚀"
echo -e "${AZUL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
