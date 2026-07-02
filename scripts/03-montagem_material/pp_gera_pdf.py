#!/usr/bin/env python3
from pathlib import Path
import re
from PIL import Image, ImageDraw, ImageFont
import sys

# ---------------------------------
# Diretório Downloads
# ---------------------------------
downloads_dir = Path.home() / "Downloads"
MD_FILE = downloads_dir / "esqueleto_enriquecido.md"
PDF_OUT = downloads_dir / "imagens.pdf"

# ---------------------------------
# Lê o Markdown
# ---------------------------------
if not MD_FILE.exists():
    sys.exit("Arquivo esqueleto_enriquecido.md não encontrado em ~/Downloads.")

md_text = MD_FILE.read_text(encoding="utf-8")

# Extrai SOMENTE o nome do arquivo da imagem
filenames = re.findall(
    r'<img src="[^/"]*/([^"]+)"',
    md_text
)

if not filenames:
    sys.exit("Nenhuma imagem encontrada no Markdown.")

pages = []

# ---------------------------------
# Processa imagens (busca em ~/Imagens)
# ---------------------------------
images_dir = Path.home() / "Imagens"

for name in filenames:
    img_path = images_dir / name

    if not img_path.exists():
        sys.exit(f"Imagem não encontrada em ~/Imagens: {name}")

    img = Image.open(img_path).convert("RGB")
    draw = ImageDraw.Draw(img)

    try:
        font = ImageFont.truetype("DejaVuSans.ttf", 18)
    except:
        font = ImageFont.load_default()

    w, h = img.size
    draw.text((10, h - 30), name, fill="black", font=font)

    pages.append(img)

# ---------------------------------
# Gera o PDF em ~/Downloads
# ---------------------------------
pages[0].save(
    PDF_OUT,
    save_all=True,
    append_images=pages[1:]
)

print(f"PDF gerado com sucesso: {PDF_OUT}")
