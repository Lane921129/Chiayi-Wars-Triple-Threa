import fitz
import sys
import os
sys.stdout.reconfigure(encoding='utf-8')

output_dir = r"d:\code_practice\application_design\FINAL\untitled3\pdf_pages"
os.makedirs(output_dir, exist_ok=True)

doc = fitz.open(r"C:\Users\lane9\Downloads\諸羅探索_—_嘉義智慧觀光_App_期末專案報告.pptx.pdf")
print(f"Total pages: {len(doc)}")

for i, page in enumerate(doc):
    pix = page.get_pixmap(dpi=200)
    img_path = os.path.join(output_dir, f"page_{i+1}.png")
    pix.save(img_path)
    print(f"Saved page {i+1} to {img_path}")
