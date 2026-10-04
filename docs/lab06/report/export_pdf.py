"""Export the Word report to PDF without Word automation: docx -> HTML (mammoth)
-> PDF (headless Chrome). Content comes from the .docx, so both files match.

Run: store-assets/_tools/.venv/bin/python docs/lab06/report/export_pdf.py
"""
import base64
import pathlib
import re
import subprocess
import tempfile

import mammoth

HERE = pathlib.Path(__file__).resolve().parent
DOCX = HERE / "IT23230774_Lab06.docx"
PDF = HERE / "IT23230774_Lab06.pdf"
ICON = HERE.parents[2] / "store-assets/icons/preview/ff_icon_rounded-preview_1024.png"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

CSS = """
@page { size: A4; margin: 18mm; }
body { font-family: Calibri, 'Helvetica Neue', Arial, sans-serif; font-size: 10.5pt; color: #1a1a2e; line-height: 1.38; }
h1 { color: #4338CA; font-size: 17pt; margin: 0 0 6pt; page-break-before: always; }
h2 { color: #4338CA; font-size: 13pt; margin: 12pt 0 4pt; page-break-after: avoid; }
p { margin: 0 0 5pt; }
table { border-collapse: collapse; width: 100%; margin: 4pt 0 10pt; font-size: 9pt; }
tr { page-break-inside: avoid; }
td { border: 1px solid #c9c9dc; padding: 3pt 5pt; vertical-align: top; }
table tr:first-child td { background: #4338CA; color: #fff; font-weight: bold; }
table.code tr td { background: #F1F1F7 !important; color: #1a1a2e !important; font-weight: normal !important; font-family: Menlo, monospace; font-size: 7.4pt; white-space: pre-wrap; }
img { display: block; margin: 6pt auto; max-width: 100%; max-height: 225mm; }
ul { margin: 2pt 0 8pt 16pt; padding: 0; }
.cover { text-align: center; padding-top: 70pt; }
.cover .t1 { font-size: 26pt; font-weight: bold; margin-bottom: 10pt; }
.cover .t2 { font-size: 16pt; }
.cover .t3 { font-size: 14pt; font-weight: bold; margin-top: 6pt; }
.cover .t4 { font-size: 12.5pt; color: #4338CA; margin-top: 4pt; }
.cover img { width: 120pt; margin: 40pt auto; }
.cover .details p { font-size: 12.5pt; margin: 3pt; }
"""


def main() -> None:
    html = mammoth.convert_to_html(DOCX.open("rb")).value
    body = html.split("<h1>Contents</h1>", 1)[1]
    # Code blocks are the single-cell tables in the .docx.
    body = re.sub(r"<table>(.*?)</table>",
                  lambda m: ("<table class='code'>" if m.group(1).count("<td") == 1 else "<table>")
                  + m.group(1) + "</table>", body, flags=re.S)
    icon = base64.b64encode(ICON.read_bytes()).decode()
    cover = f"""<div class='cover'>
      <div class='t1'>Sri Lanka Institute of Information Technology</div>
      <div class='t2'>Human Computer Interaction (IT3060)</div>
      <div class='t3'>Lab Exercise 06</div>
      <div class='t4'>FitFlow — Release Preparation and Internal Testing</div>
      <img src='data:image/png;base64,{icon}'>
      <div class='details'><p><u>Details</u></p><p>Campus: Malabe Campus</p><p>Name: Jayawardhana O K T C</p>
      <p>Student ID: IT23230774</p><p>Year: 3rd Year, 2nd Semester</p><p>Group: WE 1.1</p><p>Date: 04/10/2026</p></div>
    </div>"""
    doc = f"<!doctype html><html><head><meta charset='utf-8'><style>{CSS}</style></head><body>{cover}<h1>Contents</h1>{body}</body></html>"
    with tempfile.NamedTemporaryFile("w", suffix=".html", delete=False) as f:
        f.write(doc)
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--no-pdf-header-footer",
                    f"--print-to-pdf={PDF}", f.name], check=True, capture_output=True)
    print(PDF)


if __name__ == "__main__":
    main()
