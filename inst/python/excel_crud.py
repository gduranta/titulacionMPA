"""CRUD helper for Master Excel workbook used by titulacionMPA Shiny dashboard.

Preserves all existing sheets (CONFIGURACION, INSTRUCCIONES, etc.) and row
formatting while inserting or updating a lot (MZ, LOTE) and its 1..N
beneficiaries in the PREDIOS / OBSERVACIONES FORMALIZACION sheet.
"""

import json
import sys
from copy import copy
from pathlib import Path

import openpyxl


def _norm(val):
    if val is None:
        return ""
    return str(val).strip().upper()


def _find_predios_sheet(wb):
    for candidate in ("PREDIOS", "OBSERVACIONES FORMALIZACION ", "OBSERVACIONES FORMALIZACION"):
        if candidate in wb.sheetnames:
            return wb[candidate]
    for name in wb.sheetnames:
        if name.upper() not in ("CONFIGURACION", "INSTRUCCIONES"):
            return wb[name]
    raise ValueError("No se encontro la hoja de predios en el Excel maestro.")


def _find_lot_row_span(ws, mz_target, lote_target):
    """Return (start_row, end_row) 1-based inclusive for existing (MZ, LOTE), or None."""
    mz_t = _norm(mz_target)
    lote_t = _norm(lote_target)
    if not mz_t or not lote_t:
        return None

    cur_mz = ""
    cur_lote = ""
    match_start = None
    match_end = None

    for r in range(3, ws.max_row + 1):
        v_mz = _norm(ws.cell(r, 1).value)
        v_lote = _norm(ws.cell(r, 2).value)
        v_ben = _norm(ws.cell(r, 6).value)

        if v_mz or v_lote:
            # Starting a new lot block
            if match_start is not None:
                return (match_start, match_end)
            cur_mz = v_mz if v_mz else cur_mz
            cur_lote = v_lote
            if cur_mz == mz_t and cur_lote == lote_t:
                match_start = r
                match_end = r
        else:
            # Continuation row (blank MZ and blank LOTE)
            if match_start is not None:
                if v_ben or _norm(ws.cell(r, 7).value):
                    match_end = r
                else:
                    return (match_start, match_end)

    if match_start is not None:
        return (match_start, match_end)
    return None


def _last_data_row(ws):
    for r in range(ws.max_row, 1, -1):
        if any(ws.cell(r, c).value not in (None, "") for c in range(1, 29)):
            return r
    return 1


def _copy_row_style(ws, src_row, dst_row):
    if src_row < 2:
        return
    for c in range(1, 29):
        src_cell = ws.cell(src_row, c)
        dst_cell = ws.cell(dst_row, c)
        if src_cell.has_style:
            dst_cell.font = copy(src_cell.font)
            dst_cell.border = copy(src_cell.border)
            dst_cell.fill = copy(src_cell.fill)
            dst_cell.number_format = src_cell.number_format
            dst_cell.alignment = copy(src_cell.alignment)


def _as_num_or_str(val):
    if val is None:
        return None
    s = str(val).strip()
    if s == "":
        return None
    try:
        if "." in s:
            return float(s)
        return int(s)
    except ValueError:
        return s


def upsert_predio(excel_path, payload):
    wb = openpyxl.load_workbook(excel_path)
    ws = _find_predios_sheet(wb)

    mz = str(payload.get("mz", "")).strip()
    lote = str(payload.get("lote", "")).strip()
    if not mz or not lote:
        raise ValueError("MZ y LOTE son obligatorios.")

    beneficiarios = payload.get("beneficiarios") or []
    if not beneficiarios:
        raise ValueError("Debe ingresar al menos un posesionario/beneficiario.")

    lot_cols = {
        3: payload.get("partida") or None,
        4: payload.get("constancia") or None,
        5: payload.get("evaluacion") or "TITULABLE",
        10: payload.get("exp_constancia") or None,
        11: payload.get("exp_titulo") or None,
        12: payload.get("fecha_solicitud") or None,
        13: _as_num_or_str(payload.get("anio_posesion")),
        14: _as_num_or_str(payload.get("area")),
        15: _as_num_or_str(payload.get("perimetro")),
        17: payload.get("matrimonio") or None,
        18: payload.get("convivencia") or None,
        19: payload.get("inf_sgpuat") or None,
        20: payload.get("inf_gdur") or None,
        21: payload.get("inf_legal") or None,
        22: payload.get("proveido") or None,
        23: payload.get("resolucion") or None,
        24: payload.get("titulo") or None,
        25: payload.get("lindero_frente") or None,
        26: payload.get("lindero_fondo") or None,
        27: payload.get("lindero_derecha") or None,
        28: payload.get("lindero_izquierda") or None,
    }

    span = _find_lot_row_span(ws, mz, lote)
    style_ref_row = max(2, _last_data_row(ws))

    if span is not None:
        start_row, end_row = span
        old_n = end_row - start_row + 1
        new_n = len(beneficiarios)
        if new_n > old_n:
            ws.insert_rows(end_row + 1, amount=(new_n - old_n))
            for r in range(end_row + 1, start_row + new_n):
                _copy_row_style(ws, start_row, r)
        elif new_n < old_n:
            ws.delete_rows(start_row + new_n, amount=(old_n - new_n))
        write_start = start_row
        action = "updated"
    else:
        write_start = _last_data_row(ws) + 1
        for r in range(write_start, write_start + len(beneficiarios)):
            _copy_row_style(ws, style_ref_row, r)
        action = "inserted"

    for idx, ben in enumerate(beneficiarios):
        r = write_start + idx
        # Clear row values first
        for c in range(1, 29):
            ws.cell(r, c).value = None

        if idx == 0:
            ws.cell(r, 1).value = mz
            ws.cell(r, 2).value = _as_num_or_str(lote)
            for col_idx, val in lot_cols.items():
                ws.cell(r, col_idx).value = val

        ws.cell(r, 6).value = str(ben.get("nombre", "")).strip() or None
        ws.cell(r, 7).value = _as_num_or_str(ben.get("dni"))
        ws.cell(r, 8).value = str(ben.get("genero", "")).strip().lower() or None
        ws.cell(r, 9).value = "x" if str(ben.get("solicitante", "")).strip().lower() in ("x", "true", "1", "si") else None
        ws.cell(r, 16).value = str(ben.get("estado_civil", "")).strip().lower() or None

    wb.save(excel_path)
    return {
        "status": "ok",
        "action": action,
        "mz": mz,
        "lote": str(lote),
        "rows_written": len(beneficiarios),
        "start_row": write_start,
    }


def main():
    if len(sys.argv) < 3:
        print(json.dumps({"status": "error", "message": "Uso: excel_crud.py <excel_path> <payload_json_path>"}))
        sys.exit(1)

    excel_path = Path(sys.argv[1])
    payload_path = Path(sys.argv[2])
    payload = json.loads(payload_path.read_text(encoding="utf-8"))
    res = upsert_predio(str(excel_path), payload)
    print(json.dumps(res, ensure_ascii=False))


if __name__ == "__main__":
    main()
