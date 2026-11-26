# ==============================================================================
# MÓDULO 02: EXTRACTOR DE EXCEL MAESTRO (titulacionMPA)
# Extrae titulares (1, 2 o N copropietarios), expedientes, resoluciones y datos
# ==============================================================================

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(stringr)
  library(tibble)
  library(purrr)
})

#' Extraer datos de predios desde el Excel maestro del proyecto
#'
#' @param xlsx_path Ruta al archivo Excel
#' @param sheet Nombre de la hoja de predios (auto-detectada si es NULL)
#' @return Tibble con un registro consolidado por lote, preservando todos los N beneficiarios
#' @export
extraer_excel_proyecto <- function(xlsx_path, sheet = NULL) {
  if (!file.exists(xlsx_path)) {
    stop("No se encontr\u00f3 el archivo Excel: ", xlsx_path)
  }

  hojas <- readxl::excel_sheets(xlsx_path)
  if (is.null(sheet)) {
    if ("PREDIOS" %in% hojas) {
      sheet <- "PREDIOS"
    } else if ("OBSERVACIONES FORMALIZACION " %in% hojas) {
      sheet <- "OBSERVACIONES FORMALIZACION "
    } else {
      otras <- setdiff(hojas, "CONFIGURACION")
      sheet <- if (length(otras) > 0) otras[[1]] else hojas[[1]]
    }
  }

  raw_df <- readxl::read_excel(
    xlsx_path,
    sheet = sheet,
    col_names = FALSE,
    col_types = "text",
    .name_repair = "minimal"
  )

  header_row_idx <- which(purrr::map_lgl(seq_len(min(10, nrow(raw_df))), function(r) {
    val <- as.character(raw_df[r, 1])
    !is.na(val) && toupper(trimws(val)) == "MZ"
  }))[1]

  if (is.na(header_row_idx)) header_row_idx <- 2L
  if (nrow(raw_df) <= header_row_idx) {
    stop("La hoja '", sheet, "' no contiene registros de predios.")
  }

  data_df <- raw_df[(header_row_idx + 1L):nrow(raw_df), , drop = FALSE]

  records <- list()
  curr_mz <- NA_character_
  curr_lote_rec <- NULL
  curr_personas <- NULL

  finalizar_lote <- function() {
    if (!is.null(curr_lote_rec)) {
      if (nrow(curr_personas) > 1 && any(curr_personas$solicitante) && !curr_personas$solicitante[1]) {
        idx_sol <- which(curr_personas$solicitante)[1]
        orden <- c(idx_sol, setdiff(seq_len(nrow(curr_personas)), idx_sol))
        curr_personas <- curr_personas[orden, , drop = FALSE]
      }

      n_ben <- nrow(curr_personas)
      curr_lote_rec$num_beneficiarios <- n_ben
      curr_lote_rec$beneficiarios <- list(curr_personas)

      if (n_ben >= 1) {
        curr_lote_rec$t1_nombre      <- curr_personas$nombre[1]
        curr_lote_rec$t1_dni         <- curr_personas$dni[1]
        curr_lote_rec$t1_genero      <- curr_personas$genero[1]
        curr_lote_rec$t1_solicitante <- curr_personas$solicitante[1]
        if (!nzchar(curr_lote_rec$estado_civil) && nzchar(curr_personas$estado_civil[1])) {
          curr_lote_rec$estado_civil <- curr_personas$estado_civil[1]
        }
      }
      if (n_ben >= 2) {
        curr_lote_rec$t2_nombre      <- curr_personas$nombre[2]
        curr_lote_rec$t2_dni         <- curr_personas$dni[2]
        curr_lote_rec$t2_genero      <- curr_personas$genero[2]
        curr_lote_rec$t2_solicitante <- curr_personas$solicitante[2]
        curr_lote_rec$es_pareja      <- TRUE
      }

      records[[length(records) + 1L]] <<- curr_lote_rec
    }
  }

  for (i in seq_len(nrow(data_df))) {
    row_vals <- as.character(data_df[i, 1:min(28, ncol(data_df))])
    row_vals[is.na(row_vals)] <- ""
    row_vals <- stringr::str_trim(row_vals)
    if (length(row_vals) < 28) {
      row_vals <- c(row_vals, rep("", 28 - length(row_vals)))
    }

    if (!any(nzchar(row_vals))) next

    col_mz <- row_vals[1]
    col_lote <- row_vals[2]

    if (toupper(col_mz) == "MZ" || toupper(col_lote) == "LOTE") next
    if (nzchar(col_mz)) curr_mz <- toupper(col_mz)

    col_partida     <- row_vals[3]
    col_constancia  <- row_vals[4]
    col_evaluacion  <- row_vals[5]
    col_persona     <- row_vals[6]
    col_dni         <- row_vals[7]
    col_genero      <- tolower(row_vals[8])
    col_solicitante <- row_vals[9]
    col_exp_const   <- row_vals[10]
    col_exp_titulo  <- row_vals[11]
    col_fecha_sol   <- row_vals[12]
    col_anio_pos    <- row_vals[13]
    col_area        <- suppressWarnings(as.numeric(gsub(",", "", row_vals[14])))
    col_perim       <- suppressWarnings(as.numeric(gsub(",", "", row_vals[15])))
    col_estado      <- toupper(gsub("0", "O", row_vals[16]))
    col_matrimonio  <- toupper(row_vals[17])
    col_convivencia <- toupper(row_vals[18])
    col_inf_sgpuat  <- row_vals[19]
    col_inf_gdur    <- row_vals[20]
    col_inf_legal   <- row_vals[21]
    col_prov_sg     <- row_vals[22]
    col_res_sg      <- row_vals[23]
    col_tit_prop    <- row_vals[24]

    if (nzchar(col_lote)) {
      finalizar_lote()

      lote_raw <- col_lote
      lote_norm <- if (grepl("^[0-9]+$", lote_raw)) as.character(as.integer(lote_raw)) else lote_raw
      tiene_const <- nzchar(col_constancia) && !grepl("^NO", col_constancia, ignore.case = TRUE)

      curr_personas <- tibble::tibble(
        nombre = character(), dni = character(), genero = character(),
        solicitante = logical(), estado_civil = character()
      )
      if (nzchar(col_persona)) {
        curr_personas <- dplyr::bind_rows(curr_personas, tibble::tibble(
          nombre = col_persona,
          dni = col_dni,
          genero = col_genero,
          solicitante = grepl("^x", tolower(col_solicitante)),
          estado_civil = col_estado
        ))
      }

      fecha_sol_norm <- if (nzchar(col_fecha_sol) && grepl("^[0-9]+(\\.[0-9]+)?$", col_fecha_sol)) {
        d_sol <- as.Date(as.numeric(col_fecha_sol), origin = "1899-12-30")
        meses_es <- c("enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre")
        paste0(as.integer(format(d_sol, "%d")), " de ", meses_es[as.integer(format(d_sol, "%m"))], " del ", format(d_sol, "%Y"))
      } else {
        col_fecha_sol
      }

      curr_lote_rec <- tibble::tibble(
        mz = curr_mz,
        lote = lote_norm,
        lote_raw = lote_raw,
        partida = col_partida,
        num_constancia = col_constancia,
        tiene_constancia = tiene_const,
        evaluacion_excel = col_evaluacion,
        t1_nombre = "",
        t1_dni = "",
        t1_genero = "",
        t1_solicitante = FALSE,
        t2_nombre = "",
        t2_dni = "",
        t2_genero = "",
        t2_solicitante = FALSE,
        es_pareja = FALSE,
        num_beneficiarios = 0L,
        estado_civil = col_estado,
        exp_constancia = col_exp_const,
        exp_titulo = col_exp_titulo,
        fecha_solicitud = fecha_sol_norm,
        anio_posesion = col_anio_pos,
        area_excel = col_area,
        perimetro_excel = col_perim,
        acta_matrimonio = col_matrimonio,
        acta_convivencia = col_convivencia,
        num_informe_sgpuat = col_inf_sgpuat,
        num_informe_gdur = col_inf_gdur,
        num_proveido_sg = col_prov_sg,
        num_informe_legal = col_inf_legal,
        num_resolucion_sg = col_res_sg,
        num_titulo_propiedad = col_tit_prop,
        linderos_frente_xl = row_vals[25],
        linderos_fondo_xl = row_vals[26],
        linderos_derecha_xl = row_vals[27],
        linderos_izquierda_xl = row_vals[28]
      )
    } else if (!is.null(curr_lote_rec)) {
      if (!nzchar(curr_lote_rec$evaluacion_excel) && nzchar(col_evaluacion)) curr_lote_rec$evaluacion_excel <- col_evaluacion
      if (!nzchar(curr_lote_rec$num_informe_legal) && nzchar(col_inf_legal)) curr_lote_rec$num_informe_legal <- col_inf_legal
      if (!nzchar(curr_lote_rec$num_informe_gdur) && nzchar(col_inf_gdur)) curr_lote_rec$num_informe_gdur <- col_inf_gdur
      if (!nzchar(curr_lote_rec$num_informe_sgpuat) && nzchar(col_inf_sgpuat)) curr_lote_rec$num_informe_sgpuat <- col_inf_sgpuat
      if (!nzchar(curr_lote_rec$num_proveido_sg) && nzchar(col_prov_sg)) curr_lote_rec$num_proveido_sg <- col_prov_sg
      if (!nzchar(curr_lote_rec$num_resolucion_sg) && nzchar(col_res_sg)) curr_lote_rec$num_resolucion_sg <- col_res_sg
      if (!nzchar(curr_lote_rec$num_titulo_propiedad) && nzchar(col_tit_prop)) curr_lote_rec$num_titulo_propiedad <- col_tit_prop

      if (nzchar(col_persona)) {
        curr_personas <- dplyr::bind_rows(curr_personas, tibble::tibble(
          nombre = col_persona,
          dni = col_dni,
          genero = col_genero,
          solicitante = grepl("^x", tolower(col_solicitante)),
          estado_civil = col_estado
        ))
      }
    }
  }

  finalizar_lote()
  dplyr::bind_rows(records)
}
