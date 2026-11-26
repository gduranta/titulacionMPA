"""Postprocesador unificado de documentos DOCX para titulacionMPA.
Estandariza la tipografía institucional Times New Roman, repara relaciones XML
y aplica bordes/espaciados consistentes según el tipo de documento.
"""

import os
import sys
import zipfile
import docx
from docx.shared import Pt
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import parse_xml
from docx.oxml.ns import nsdecls

FUENTE_ESTANDAR = "Times New Roman"


def fix_rels_prefixes(docx_path):
    try:
        with zipfile.ZipFile(docx_path, "r") as z_in:
            entries = {item.filename: z_in.read(item.filename) for item in z_in.infolist()}

        modified = False
        for name in list(entries.keys()):
            if "rels" in name:
                txt = entries[name].decode("utf-8", errors="ignore")
                if "ns0:Relationship" in txt or "r:Relationship" in txt:
                    txt = txt.replace("ns0:Relationship", "Relationship").replace("r:Relationship", "Relationship")
                    entries[name] = txt.encode("utf-8")
                    modified = True

        if modified:
            with zipfile.ZipFile(docx_path, "w", compression=zipfile.ZIP_DEFLATED) as z_out:
                for name, data in entries.items():
                    z_out.writestr(name, data)
    except Exception as e:
        print(f"Warning fixing rels: {e}")


def aplicar_bordes_tabla(tbl, completos=True):
    tblPr = tbl._tbl.tblPr
    anterior = tblPr.first_child_found_in("w:tblBorders")
    if anterior is not None:
        tblPr.remove(anterior)
    if completos:
        xml_b = (
            r'<w:tblBorders %s>'
            r'  <w:top w:val="single" w:sz="4" w:space="0" w:color="000000"/>'
            r'  <w:left w:val="single" w:sz="4" w:space="0" w:color="000000"/>'
            r'  <w:bottom w:val="single" w:sz="4" w:space="0" w:color="000000"/>'
            r'  <w:right w:val="single" w:sz="4" w:space="0" w:color="000000"/>'
            r'  <w:insideH w:val="single" w:sz="4" w:space="0" w:color="000000"/>'
            r'  <w:insideV w:val="single" w:sz="4" w:space="0" w:color="000000"/>'
            r'</w:tblBorders>' % nsdecls("w")
        )
    else:
        xml_b = (
            r'<w:tblBorders %s>'
            r'  <w:top w:val="nil"/><w:left w:val="nil"/><w:bottom w:val="nil"/>'
            r'  <w:right w:val="nil"/><w:insideH w:val="nil"/><w:insideV w:val="nil"/>'
            r'</w:tblBorders>' % nsdecls("w")
        )
    ref = (
        tblPr.first_child_found_in("w:tblLayout")
        or tblPr.first_child_found_in("w:tblCellMar")
        or tblPr.first_child_found_in("w:tblLook")
    )
    if ref is not None:
        ref.addprevious(parse_xml(xml_b))
    else:
        tblPr.append(parse_xml(xml_b))


def aplicar_fuente_parrafos(doc, size_pt=11, justificar_todos=False):
    for p in doc.paragraphs:
        t = p.text.strip()
        if justificar_todos and t and not any(k in t for k in ["Atentamente", "ALCALDE", "TITULAR", "Municipalidad Provincial De Anta"]):
            if p.alignment not in (WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.RIGHT):
                p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
        for r in p.runs:
            r.font.name = FUENTE_ESTANDAR
            if r.font.size is None:
                r.font.size = Pt(size_pt)

    for tbl in doc.tables:
        for row in tbl.rows:
            for cell in row.cells:
                for p in cell.paragraphs:
                    for r in p.runs:
                        r.font.name = FUENTE_ESTANDAR
                        if r.font.size is None:
                            r.font.size = Pt(size_pt - 1)


def postprocesar(docx_path, tipo_doc="general"):
    if not os.path.exists(docx_path):
        return False

    fix_rels_prefixes(docx_path)
    doc = docx.Document(docx_path)

    if tipo_doc == "sgpuat":
        for p in doc.paragraphs:
            t = p.text.strip()
            if "INFORME N°" in t or "INFORME Nº" in t:
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
                for r in p.runs:
                    r.font.name = FUENTE_ESTANDAR
                    r.font.size = Pt(12)
                    r.font.bold = True
            elif "Atentamente" in t:
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
                for r in p.runs:
                    r.font.name = FUENTE_ESTANDAR
                    r.font.size = Pt(11)
            else:
                p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
                p.paragraph_format.space_before = Pt(0)
                p.paragraph_format.space_after = Pt(4)
                p.paragraph_format.line_spacing = 1.03
                for r in p.runs:
                    r.font.name = FUENTE_ESTANDAR
                    r.font.size = Pt(11)
        for tbl in doc.tables:
            aplicar_bordes_tabla(tbl, completos=True)
            for row in tbl.rows:
                for cell in row.cells:
                    for p in cell.paragraphs:
                        for r in p.runs:
                            r.font.name = FUENTE_ESTANDAR
                            r.font.size = Pt(9.5)

    elif tipo_doc == "gdur":
        for p in doc.paragraphs:
            t = p.text.strip()
            if "INFORME N.º" in t or "INFORME N°" in t:
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
                for r in p.runs:
                    r.font.name = FUENTE_ESTANDAR
                    r.font.size = Pt(11)
                    r.font.bold = True
            elif "Atentamente" in t:
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
                for r in p.runs:
                    r.font.name = FUENTE_ESTANDAR
                    r.font.size = Pt(10.5)
            else:
                p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
                p.paragraph_format.space_before = Pt(0)
                p.paragraph_format.space_after = Pt(3)
                p.paragraph_format.line_spacing = 1.02
                for r in p.runs:
                    r.font.name = FUENTE_ESTANDAR
                    r.font.size = Pt(10.5)
        for tbl_idx, tbl in enumerate(doc.tables):
            aplicar_bordes_tabla(tbl, completos=(tbl_idx > 0))
            for row in tbl.rows:
                for cell in row.cells:
                    for p in cell.paragraphs:
                        for r in p.runs:
                            r.font.name = FUENTE_ESTANDAR
                            r.font.size = Pt(10)

    elif tipo_doc == "legal":
        aplicar_fuente_parrafos(doc, size_pt=11, justificar_todos=True)

    elif tipo_doc == "resolucion":
        for p in doc.paragraphs:
            t = p.text.strip()
            if p.style.name == "ResolucionTitle":
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
                for r in p.runs:
                    r.font.name = FUENTE_ESTANDAR
                    r.font.size = Pt(12)
                    r.font.bold = True
                    r.font.underline = True
            elif p.style.name == "ResolucionDate":
                p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
                for r in p.runs:
                    r.font.name = FUENTE_ESTANDAR
                    r.font.size = Pt(11)
            elif p.style.name in ("ResolucionAlcalde", "Title"):
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
                for r in p.runs:
                    r.font.name = FUENTE_ESTANDAR
                    r.font.size = Pt(11)
                    r.font.bold = True
            else:
                if any(t.startswith(k) for k in ("VISTO:", "CONSIDERANDO:", "SE RESUELVE:", "Que,", "ARTICULO", "Estando", "En uso")):
                    p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
                for r in p.runs:
                    r.font.name = FUENTE_ESTANDAR
                    if r.font.size is None:
                        r.font.size = Pt(11)
        for tbl in doc.tables:
            aplicar_bordes_tabla(tbl, completos=True)
            for r_idx, row in enumerate(tbl.rows):
                for cell in row.cells:
                    for p in cell.paragraphs:
                        for r in p.runs:
                            r.font.name = FUENTE_ESTANDAR
                            r.font.size = Pt(10 if r_idx == 0 else 9.5)
                            if r_idx == 0:
                                r.font.bold = True

    elif tipo_doc == "titulo":
        for p in doc.paragraphs:
            t = p.text.strip()
            if "TÍTULO DE PROPIEDAD N" in t:
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
                for r in p.runs:
                    r.font.name = FUENTE_ESTANDAR
                    r.font.size = Pt(13)
                    r.font.bold = True
                    r.font.underline = True
            elif t.startswith("ALCALDE") or "Municipalidad Provincial De Anta" in t or t.startswith("TITULAR"):
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
                for r in p.runs:
                    r.font.name = FUENTE_ESTANDAR
                    r.font.size = Pt(10.5)
            else:
                p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
                for r in p.runs:
                    r.font.name = FUENTE_ESTANDAR
                    if r.font.size is None:
                        r.font.size = Pt(11)
        for tbl in doc.tables:
            for row in tbl.rows:
                for cell in row.cells:
                    for p in cell.paragraphs:
                        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
                        for r in p.runs:
                            r.font.name = FUENTE_ESTANDAR
                            r.font.size = Pt(10.5)

    doc.save(docx_path)
    return True


if __name__ == "__main__":
    if len(sys.argv) >= 2:
        path = sys.argv[1]
        tipo = sys.argv[2] if len(sys.argv) >= 3 else "general"
        ok = postprocesar(path, tipo)
        print(f"{'SUCCESS' if ok else 'FAILED'}: {path} ({tipo})")
