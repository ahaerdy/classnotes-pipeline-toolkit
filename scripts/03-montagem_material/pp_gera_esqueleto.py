#!/usr/bin/env python3
import re
from pathlib import Path
from datetime import timedelta

# --------------------------------------------------
# Extrai timestamp do nome VLC (apenas para ordenação)
# --------------------------------------------------
def extract_timestamp(filename: str):
    """
    Espera padrão: HHhMMmSSsXXX
    Exemplo: 13h56m58s772
    """
    m = re.search(r'(\d{2})h(\d{2})m(\d{2})s(\d{3})', filename)
    if not m:
        return None

    h, m_, s, ms = map(int, m.groups())
    return timedelta(
        hours=h,
        minutes=m_,
        seconds=s,
        milliseconds=ms
    )

# --------------------------------------------------
# Diretórios principais
# --------------------------------------------------
downloads_dir = Path.home() / "Downloads"
images_dir = Path.home() / "Imagens"

# --------------------------------------------------
# Coleta imagens vlc*.jpg em ~/Imagens
# --------------------------------------------------
images = []

for img in images_dir.iterdir():
    if (
        img.is_file()
        and img.name.lower().startswith("vlc")
        and img.name.lower().endswith(".jpg")
    ):
        ts = extract_timestamp(img.name)
        if ts is not None:
            images.append((ts, img.name))

if not images:
    raise SystemExit("Nenhuma imagem vlc*.jpg com timestamp válido encontrada em ~/Imagens.")

# Ordenação cronológica (hora local de captura)
images.sort(key=lambda x: x[0])

# --------------------------------------------------
# Carrega transcrição em ~/Downloads
# --------------------------------------------------
transcription_file = downloads_dir / "transcricao.md"

if not transcription_file.exists():
    raise SystemExit("Arquivo transcricao.md não encontrado em ~/Downloads.")

transcription_text = transcription_file.read_text(encoding="utf-8").strip()

# --------------------------------------------------
# Geração do Markdown esqueleto
# --------------------------------------------------
md_lines = []

md_lines.append("<!-- ESQUELETO GERADO AUTOMATICAMENTE -->")
md_lines.append("<!-- NÃO ALTERAR NOMES DE ARQUIVOS -->")
md_lines.append("<!-- A IA DEVE APENAS COMPLETAR OS BLOCOS INDICADOS -->\n")

for _, filename in images:
    md_lines.append("#### ")
    md_lines.append("")
    md_lines.append(
        f"""<p align="center">
  <img src="000-Midia_e_Anexos/{filename}" alt="" width="840">
</p>
"""
    )
    md_lines.append(
        """<!--
TAREFA DA IA:
- Identificar o conteúdo visual da imagem
- Localizar o trecho correspondente na transcrição
- Produzir explicação didática no contexto da aula
- Extrair e formatar código, se houver
- NÃO inventar nomes de arquivos
-->
"""
    )
    md_lines.append("")

# --------------------------------------------------
# Apêndice: Transcrição completa
# --------------------------------------------------
md_lines.append("\n---\n")
md_lines.append("<!-- TRANSCRIÇÃO COMPLETA — NÃO ALTERAR -->\n")
md_lines.append("<!-- INÍCIO DA TRANSCRIÇÃO -->\n")
md_lines.append(transcription_text)
md_lines.append("\n<!-- FIM DA TRANSCRIÇÃO -->\n")

# --------------------------------------------------
# Escrita do arquivo final em ~/Downloads
# --------------------------------------------------
output_file = downloads_dir / "esqueleto.md"
output_file.write_text("\n".join(md_lines), encoding="utf-8")

print(f"Esqueleto Markdown gerado com sucesso: {output_file}")
