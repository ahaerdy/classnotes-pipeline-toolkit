#!/usr/bin/env python3
from pathlib import Path
import re
import pytesseract
from PIL import Image

# --------------------------------------------------
# Diretório Downloads
# --------------------------------------------------
downloads_dir = Path.home() / "Downloads"

MD_IN = downloads_dir / "esqueleto.md"
MD_OUT = downloads_dir / "esqueleto_enriquecido.md"

# -----------------------------
# Heurísticas simples
# -----------------------------
def detectar_codigo(texto):
    sinais = [
        r"\bdef\b", r"\bclass\b", r"\bimport\b",
        r"\{|\}|\(|\)|;",
        r"\becho\b", r"\bgit\b", r"\bnpm\b",
        r"\$ ", r"> "
    ]
    return any(re.search(p, texto) for p in sinais)

def detectar_linguagem(texto):
    if re.search(r"\bdef\b|\bimport\b", texto):
        return "python"
    if re.search(r"\becho\b|\bgit\b|\$ ", texto):
        return "bash"
    if re.search(r"\bfunction\b|\bconst\b|\blet\b", texto):
        return "javascript"
    return None

# -----------------------------
# Lê Markdown
# -----------------------------
if not MD_IN.exists():
    raise SystemExit("Arquivo esqueleto.md não encontrado em ~/Downloads.")

md_text = MD_IN.read_text(encoding="utf-8")

# -----------------------------
# Regex para bloco <p> completo
# -----------------------------
padrao_bloco_img = re.compile(
    r'(<p align="center">\s*<img src="[^"]+/([^"]+)"[^>]*>\s*</p>)',
    re.DOTALL
)

# -----------------------------
# Enriquecimento
# -----------------------------
def enriquecer(match):
    bloco_html = match.group(1)
    filename = match.group(2)

    classificacao = ["<!-- CLASSIFICACAO_AUTOMATICA -->"]

    try:
        img = Image.open(filename)
        texto = pytesseract.image_to_string(img)

        if detectar_codigo(texto):
            classificacao.append("<!-- TIPO_DE_IMAGEM: codigo -->")
            lang = detectar_linguagem(texto)
            if lang:
                classificacao.append(f"<!-- POSSIVEL_LINGUAGEM: {lang} -->")
            classificacao.append("<!-- CONFIANCA: media -->")
        else:
            classificacao.append("<!-- TIPO_DE_IMAGEM: slide_conceitual -->")
            classificacao.append("<!-- CONFIANCA: alta -->")

    except Exception:
        classificacao.append("<!-- TIPO_DE_IMAGEM: desconhecido -->")
        classificacao.append("<!-- CONFIANCA: baixa -->")

    return bloco_html + "\n\n" + "\n".join(classificacao)

md_out = padrao_bloco_img.sub(enriquecer, md_text)

# -----------------------------
# Escrita do arquivo final em ~/Downloads
# -----------------------------
MD_OUT.write_text(md_out, encoding="utf-8")

print(f"esqueleto_enriquecido.md gerado com sucesso em {MD_OUT}")
