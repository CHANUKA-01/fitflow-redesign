"""Tile screenshots into one image for quick review: contact_sheet.py OUT IMG..."""
import sys
from PIL import Image

out, files = sys.argv[1], sys.argv[2:]
ims = [Image.open(f).convert("RGB") for f in files]
h = 900
ims = [i.resize((round(i.width * h / i.height), h)) for i in ims]
cols = min(5, len(ims))
rows = (len(ims) + cols - 1) // cols
w = max(i.width for i in ims)
sheet = Image.new("RGB", (cols * (w + 16), rows * (h + 16)), "white")
for k, im in enumerate(ims):
    sheet.paste(im, ((k % cols) * (w + 16), (k // cols) * (h + 16)))
sheet.save(out)
print(out, sheet.size)
