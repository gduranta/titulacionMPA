# ==============================================================================
# MÓDULO 01: EXTRACTOR DE MEMORIA DESCRIPTIVA (.docx)
# Extrae linderos, colindancias, medidas perimétricas y áreas por manzana y lote
# ==============================================================================

suppressPackageStartupMessages({
  library(xml2)
  library(stringr)
  library(tibble)
  library(purrr)
  library(dplyr)
})

#' Extraer datos técnicos de lotes desde la Memoria Descriptiva (.docx)
#'
#' @param docx_path Ruta al archivo Word de la Memoria Descriptiva
#' @return Tibble con información de manzana, lote, linderos, área y perímetro
#' @export
extraer_memoria_proyecto <- function(docx_path) {
  vacio <- tibble::tibble(
    mz = character(), lote = character(), lote_raw = character(),
    linderos_frente = character(), linderos_fondo = character(),
    linderos_derecha = character(), linderos_izquierda = character(),
    calle_via = character(), area_memoria = numeric(), perimetro_memoria = numeric()
  )
  
  if (is.null(docx_path) || !nzchar(trimws(docx_path)) || !file.exists(docx_path)) {
    return(vacio)
  }

  tmp_dir <- tempfile(pattern = "memoria_mpa_")
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  utils::unzip(docx_path, files = "word/document.xml", exdir = tmp_dir)
  xml_file <- file.path(tmp_dir, "word", "document.xml")
  if (!file.exists(xml_file)) return(vacio)
  
  doc_xml <- xml2::read_xml(xml_file)
  ns <- c(w = "http://schemas.openxmlformats.org/wordprocessingml/2006/main")

  paras <- xml2::xml_find_all(doc_xml, ".//w:p", ns)
  para_texts <- purrr::map_chr(paras, function(p) {
    t_nodes <- xml2::xml_find_all(p, ".//w:t", ns)
    paste0(xml2::xml_text(t_nodes), collapse = "")
  })

  lines <- stringr::str_trim(para_texts)
  lines <- lines[nchar(lines) > 0]

  start_idx <- which(stringr::str_detect(lines, stringr::regex("LINDEROS Y PER\u00cdMETROS DE LOTES", ignore_case = TRUE)))[1]
  end_idx <- which(stringr::str_detect(lines, stringr::regex("\u00c1REAS DE APORTE|CUADRO GENERAL", ignore_case = TRUE)))[1]

  if (is.na(start_idx)) start_idx <- 1L
  if (is.na(end_idx)) end_idx <- length(lines)
  if (end_idx <= start_idx) return(vacio)

  lotes_lines <- lines[start_idx:(end_idx - 1L)]

  records <- list()
  curr_mz <- NA_character_
  curr_lote <- NA_character_
  curr_frente <- NA_character_
  curr_fondo <- NA_character_
  curr_derecha <- NA_character_
  curr_izq <- NA_character_
  curr_area <- NA_real_
  curr_perim <- NA_real_

  guardar_lote <- function() {
    if (!is.na(curr_mz) && !is.na(curr_lote)) {
      calle <- NA_character_
      if (!is.na(curr_frente)) {
        m <- stringr::str_match(curr_frente, stringr::regex("con\\s+(?:la\\s+)?(calle\\s+[^,]+|av(?:enida)?\\.?\\s+[^,]+|pasaje\\s+[^,]+|pista\\s+[^,]+)", ignore_case = TRUE))
        if (!is.na(m[1, 2])) calle <- stringr::str_trim(m[1, 2])
      }
      lote_norm <- if (grepl("^[0-9]+$", curr_lote)) as.character(as.integer(curr_lote)) else curr_lote

      records[[length(records) + 1L]] <<- tibble::tibble(
        mz = curr_mz,
        lote = lote_norm,
        lote_raw = curr_lote,
        linderos_frente = curr_frente,
        linderos_fondo = curr_fondo,
        linderos_derecha = curr_derecha,
        linderos_izquierda = curr_izq,
        calle_via = calle,
        area_memoria = curr_area,
        perimetro_memoria = curr_perim
      )
    }
  }

  for (line in lotes_lines) {
    m_mz <- stringr::str_match(line, stringr::regex("MANZANA\\s+[\u201c\"'\u2018]([A-Z0-9]+)[\u201d\"'\u2019]", ignore_case = TRUE))
    if (!is.na(m_mz[1, 2])) {
      guardar_lote()
      curr_mz <- toupper(stringr::str_trim(m_mz[1, 2]))
      curr_lote <- NA_character_
      curr_frente <- curr_fondo <- curr_derecha <- curr_izq <- NA_character_
      curr_area <- curr_perim <- NA_real_
      next
    }

    m_lt <- stringr::str_match(line, stringr::regex("^Lote\\s+([A-Za-z0-9\\-]+):?", ignore_case = TRUE))
    if (!is.na(m_lt[1, 2])) {
      guardar_lote()
      curr_lote <- toupper(stringr::str_trim(m_lt[1, 2]))
      curr_frente <- curr_fondo <- curr_derecha <- curr_izq <- NA_character_
      curr_area <- curr_perim <- NA_real_
      next
    }

    if (stringr::str_detect(line, stringr::regex("^Por el frente\\s*:", ignore_case = TRUE))) {
      curr_frente <- line
    } else if (stringr::str_detect(line, stringr::regex("^Por el fondo\\s*:", ignore_case = TRUE))) {
      curr_fondo <- line
    } else if (stringr::str_detect(line, stringr::regex("^Por la derecha\\s*:", ignore_case = TRUE))) {
      curr_derecha <- line
    } else if (stringr::str_detect(line, stringr::regex("^Por la izquierda\\s*:", ignore_case = TRUE))) {
      curr_izq <- line
    } else if (stringr::str_detect(line, stringr::regex("^\u00c1rea\\s*:", ignore_case = TRUE))) {
      m_a <- stringr::str_match(line, stringr::regex("\u00c1rea\\s*:\\s*([0-9.,]+)", ignore_case = TRUE))
      if (!is.na(m_a[1, 2])) curr_area <- suppressWarnings(as.numeric(gsub(",", "", m_a[1, 2])))
    } else if (stringr::str_detect(line, stringr::regex("^Per\u00edmetro\\s*:", ignore_case = TRUE))) {
      m_p <- stringr::str_match(line, stringr::regex("Per\u00edmetro\\s*:\\s*([0-9.,]+)", ignore_case = TRUE))
      if (!is.na(m_p[1, 2])) curr_perim <- suppressWarnings(as.numeric(gsub(",", "", m_p[1, 2])))
    }
  }
  guardar_lote()

  if (!length(records)) return(vacio)
  dplyr::bind_rows(records)
}
