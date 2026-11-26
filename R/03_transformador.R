# ==============================================================================
# MÓDULO 03: TRANSFORMADOR DE DATOS MAESTROS (titulacionMPA)
# Cruce relacional de Memoria Descriptiva y Excel, concordancia gramatical y TUPA
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
  library(purrr)
  library(tibble)
  library(glue)
  library(writexl)
})

normalizar_txt_mpa <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  stringr::str_trim(x)
}

extraer_num_doc_mpa <- function(txt, default_val = "XXX") {
  txt <- normalizar_txt_mpa(txt)
  if (!nzchar(txt)) return(default_val)
  m <- stringr::str_match(txt, "[Nn][\u00b0\u00bao.]+\\s*([0-9A-Za-z]+)")[, 2]
  if (is.na(m)) m <- stringr::str_extract(txt, "[0-9]+")
  if (is.na(m) || m == "2026") {
    if (grepl("X", txt, ignore.case = TRUE)) "XXX" else default_val
  } else {
    m
  }
}

clasificar_fem_mpa <- function(nombre, genero_col = "") {
  g <- tolower(normalizar_txt_mpa(genero_col))
  if (g %in% c("f", "femenino", "mujer")) return(TRUE)
  if (g %in% c("m", "masculino", "hombre")) return(FALSE)

  nom <- toupper(normalizar_txt_mpa(nombre))
  primer_nom <- strsplit(nom, "\\s+")[[1]][1]
  if (is.na(primer_nom) || !nzchar(primer_nom)) return(FALSE)

  excepciones_f <- c("LIZBETH", "JANETH", "ELIZABETH", "RUTH", "ROCIO", "MILAGROS", "LOURDES", "MERCEDES", "MARIBEL", "MARY", "GLADYS", "SOLEDAD", "MARILUZ", "YULY", "YANETH", "BEATRIZ", "ESTHER", "NOEMI", "FLOR", "CARMEN", "PILAR")
  excepciones_m <- c("JHON", "LUIS", "CARLOS", "JUAN", "JOSE", "ALEX", "DAVID", "EDWIN", "WILBER", "PERCY", "FREDY", "HENRY", "EDGAR", "ELOY", "FIDEL", "SANTOS", "JUVENAL", "JESUS", "MARIO", "DANIEL", "MARCO")

  if (primer_nom %in% excepciones_f) return(TRUE)
  if (primer_nom %in% excepciones_m) return(FALSE)
  grepl("(A|E)$", primer_nom)
}

formatear_eval_mpa <- function(raw_eval) {
  txt <- normalizar_txt_mpa(raw_eval)
  if (!nzchar(txt)) return("")
  txt <- stringr::str_squish(txt)
  primera <- toupper(substr(txt, 1, 1))
  resto <- substr(txt, 2, nchar(txt))
  txt <- paste0(primera, resto)
  if (!grepl("\\.$", txt)) txt <- paste0(txt, ".")
  txt
}

#' Construir el dataset maestro unificado para un proyecto
#'
#' @param config Objeto de configuración generado por cargar_config_proyecto()
#' @param guardar_archivos Si TRUE, guarda copia .rds y .xlsx junto al Excel fuente
#' @return Tibble maestro listo para generar los 5 productos documentales
#' @export
construir_dataset_maestro <- function(config, guardar_archivos = TRUE) {
  df_excel <- extraer_excel_proyecto(config$excel_path)
  df_mem   <- extraer_memoria_proyecto(config$memoria_path)

  if (nrow(df_mem) > 0) {
    df <- dplyr::left_join(df_excel, df_mem, by = c("mz", "lote"))
  } else {
    df <- df_excel
    df$lote_raw.y <- df$lote_raw
    df$linderos_frente <- ""
    df$linderos_fondo <- ""
    df$linderos_derecha <- ""
    df$linderos_izquierda <- ""
    df$calle_via <- ""
    df$area_memoria <- NA_real_
    df$perimetro_memoria <- NA_real_
  }

  # Respaldo automático desde columnas Y-AB del Excel si no hay Memoria Descriptiva
  for (lado in c("frente", "fondo", "derecha", "izquierda")) {
    col_mem <- paste0("linderos_", lado)
    col_xl  <- paste0("linderos_", lado, "_xl")
    if (col_xl %in% names(df)) {
      v_mem <- normalizar_txt_mpa(df[[col_mem]])
      v_xl  <- normalizar_txt_mpa(df[[col_xl]])
      df[[col_mem]] <- ifelse(nzchar(v_mem), v_mem, v_xl)
    }
  }

  char_cols <- c(
    "mz", "lote", "partida", "num_constancia", "evaluacion_excel",
    "t1_nombre", "t1_dni", "t1_genero", "t2_nombre", "t2_dni", "t2_genero",
    "estado_civil", "exp_constancia", "exp_titulo", "fecha_solicitud", "anio_posesion",
    "acta_matrimonio", "acta_convivencia",
    "num_informe_sgpuat", "num_informe_gdur", "num_proveido_sg",
    "num_informe_legal", "num_resolucion_sg", "num_titulo_propiedad",
    "linderos_frente", "linderos_fondo", "linderos_derecha", "linderos_izquierda", "calle_via"
  )
  for (c in intersect(char_cols, names(df))) {
    df[[c]] <- normalizar_txt_mpa(df[[c]])
  }

  # Correlativos extraídos
  df$num_informe_sgpuat_num <- purrr::map_chr(df$num_informe_sgpuat, extraer_num_doc_mpa, default_val = "XXX")
  df$num_informe_gdur_num   <- purrr::map_chr(df$num_informe_gdur,   extraer_num_doc_mpa, default_val = "XXX")
  df$num_informe_legal_num  <- purrr::map_chr(df$num_informe_legal,  extraer_num_doc_mpa, default_val = "XXX")
  df$num_resolucion_num     <- purrr::map_chr(df$num_resolucion_sg,  extraer_num_doc_mpa, default_val = "XXX")
  df$num_titulo_num         <- purrr::map_chr(df$num_titulo_propiedad, extraer_num_doc_mpa, default_val = "XXX")

  # Evaluación TUPA:
  # Ítem 6: Defunción (VIUDO/A -> CUMPLE)
  df$tupa_defuncion <- purrr::map_chr(df$estado_civil, function(est) {
    if (grepl("VIUD", toupper(normalizar_txt_mpa(est)))) "CUMPLE" else "NO CORRESPONDE"
  })

  # Ítems 7 (Col Q) y 8 (Col R): "SI" -> CUMPLE, otro valor no vacío se conserva, vacío/"-" -> NO CORRESPONDE
  evaluar_req <- function(val) {
    v <- toupper(normalizar_txt_mpa(val))
    if (v == "SI") "CUMPLE" else if (nzchar(v) && v != "-") v else "NO CORRESPONDE"
  }
  df$tupa_matrimonio  <- purrr::map_chr(df$acta_matrimonio, evaluar_req)
  df$tupa_convivencia <- purrr::map_chr(df$acta_convivencia, evaluar_req)
  df$tupa_item_6 <- df$tupa_defuncion
  df$tupa_item_7 <- df$tupa_matrimonio
  df$tupa_item_8 <- df$tupa_convivencia

  # Géneros y concordancias gramaticales
  df$fem1 <- purrr::map2_lgl(df$t1_nombre, df$t1_genero, clasificar_fem_mpa)
  df$fem2 <- purrr::map2_lgl(df$t2_nombre, df$t2_genero, clasificar_fem_mpa)

  df$sujeto_admin <- purrr::pmap_chr(list(df$fem1, df$es_pareja), function(f1, par) {
    if (isTRUE(par)) "los administrados" else if (isTRUE(f1)) "la administrada" else "el administrado"
  })
  df$sujeto_admin_cap <- purrr::pmap_chr(list(df$fem1, df$es_pareja), function(f1, par) {
    if (isTRUE(par)) "Los administrados" else if (isTRUE(f1)) "La administrada" else "El administrado"
  })
  df$admin1     <- df$sujeto_admin
  df$admin1_cap <- df$sujeto_admin_cap

  unir_y <- function(vec) {
    vec <- vec[nzchar(vec)]
    n <- length(vec)
    if (n == 0L) return("")
    if (n == 1L) return(vec[1])
    if (n == 2L) return(paste(vec[1], "y", vec[2]))
    paste0(paste(vec[-n], collapse = ", "), " y ", vec[n])
  }

  est_civ_sing_fn <- function(est, es_fem) {
    est <- toupper(normalizar_txt_mpa(gsub("0", "O", est)))
    if (grepl("CASAD", est)) { if (es_fem) "casada" else "casado" }
    else if (grepl("CONVIV", est)) { "conviviente" }
    else if (grepl("VIUD", est)) { if (es_fem) "viuda" else "viudo" }
    else if (grepl("DIVORC", est)) { if (es_fem) "divorciada" else "divorciado" }
    else { if (es_fem) "soltera" else "soltero" }
  }

  df$beneficiarios <- purrr::map2(df$beneficiarios, df$estado_civil, function(ben, est_def) {
    if (is.null(ben) || nrow(ben) == 0) return(ben)
    ben$es_fem <- purrr::map2_lgl(ben$nombre, ben$genero, clasificar_fem_mpa)
    ben$trat_corto <- ifelse(ben$es_fem, "sra.", "sr.")
    ben$trat <- ifelse(ben$es_fem, "la Sra.", "el Sr.")
    ben$ident <- ifelse(ben$es_fem, "identificada", "identificado")
    ben$don <- ifelse(ben$es_fem, "Do\u00f1a", "Don")
    ben$est_civ_raw <- ifelse(nzchar(normalizar_txt_mpa(ben$estado_civil)), ben$estado_civil, est_def)
    ben$est_civ_sing <- purrr::map2_chr(ben$est_civ_raw, ben$es_fem, est_civ_sing_fn)
    ben
  })

  df$beneficiarios_resumen <- purrr::map_chr(df$beneficiarios, function(ben) {
    if (is.null(ben) || nrow(ben) == 0) return("")
    paste(paste0(ben$nombre, " (DNI ", ben$dni, ")"), collapse = "; ")
  })

  df$solicitante_saludo <- purrr::map_chr(df$beneficiarios, function(ben) {
    if (nrow(ben) == 0) return("")
    unir_y(paste0(ben$trat, " ", ben$nombre))
  })

  df$titulares_informe <- purrr::map_chr(df$beneficiarios, function(ben) {
    if (nrow(ben) == 0) return("")
    partes <- glue::glue("{ben$trat} {ben$nombre} {ben$ident} con DNI N\u00b0 {ben$dni}")
    unir_y(partes)
  })

  df$nombres_resumen <- df$solicitante_saludo

  df$nombres_constata <- purrr::map_chr(df$beneficiarios, function(ben) {
    n <- nrow(ben)
    if (n == 0) return("")
    if (n == 1) return(paste0(ben$trat[1], " ", ben$nombre[1]))
    paste("los sres.", unir_y(ben$nombre))
  })

  df$titular_recibo <- df$nombres_resumen
  df$sujeto_solicitan  <- ifelse(df$es_pareja, "solicitan", "solicita")
  df$sujeto_vienen     <- ifelse(df$es_pareja, "vienen ejerciendo", "viene ejerciendo")
  df$sujeto_adjuntan   <- ifelse(df$es_pareja, "adjuntan", "adjunta")
  df$sujeto_cumplido   <- ifelse(df$es_pareja, "han cumplido", "ha cumplido")
  df$sujeto_declaran   <- ifelse(df$es_pareja, "declaran", "declara")
  df$sujeto_presentan  <- ifelse(df$es_pareja, "presentan", "presenta")
  df$evaluacion_formateada <- purrr::map_chr(df$evaluacion_excel, formatear_eval_mpa)

  df$area_formateada <- purrr::map2_chr(df$area_memoria, df$area_excel, function(am, ae) {
    val <- if (!is.na(am) && am > 0) am else ae
    if (is.na(val)) "0.00" else formatC(val, format = "f", digits = 2)
  })
  df$perimetro_formateado <- purrr::map2_chr(df$perimetro_memoria, df$perimetro_excel, function(pm, pe) {
    val <- if (!is.na(pm) && pm > 0) pm else pe
    if (is.na(val)) "0.00" else formatC(val, format = "f", digits = 2)
  })

  df$expediente <- ifelse(nzchar(df$exp_titulo), df$exp_titulo, df$exp_constancia)
  df$anio_pos   <- ifelse(nzchar(df$anio_posesion), df$anio_posesion, "2020")

  if (isTRUE(guardar_archivos)) {
    dir_out <- dirname(config$excel_path)
    saveRDS(df, file.path(dir_out, "dataset_maestro_proyecto.rds"))
    df_xlsx <- df %>% dplyr::select(-dplyr::any_of("beneficiarios"))
    writexl::write_xlsx(df_xlsx, file.path(dir_out, "dataset_maestro_proyecto.xlsx"))
  }

  df
}

.mpa_cache <- new.env(parent = emptyenv())

#' Obtener el dataset maestro con recarga automática ante cambios en el Excel
#'
#' @param config Objeto de configuración generado por cargar_config_proyecto()
#' @param recargar Si TRUE, fuerza la reconstrucción desde Excel y Memoria
#' @return Tibble maestro
#' @export
obtener_dataset_proyecto <- function(config, recargar = FALSE) {
  rds_path <- file.path(dirname(config$excel_path), "dataset_maestro_proyecto.rds")
  excel_mtime <- file.info(config$excel_path)$mtime
  cache_key <- config$excel_path

  cache_stale <- if (exists("mtime", envir = .mpa_cache) && exists("excel", envir = .mpa_cache)) {
    (get("excel", envir = .mpa_cache) != cache_key) || (excel_mtime > get("mtime", envir = .mpa_cache))
  } else {
    TRUE
  }

  if (!isTRUE(recargar) && !cache_stale && exists("df", envir = .mpa_cache)) {
    return(get("df", envir = .mpa_cache))
  }

  rds_stale <- if (file.exists(rds_path)) excel_mtime > file.info(rds_path)$mtime else TRUE
  if (!isTRUE(recargar) && !rds_stale && file.exists(rds_path)) {
    df <- readRDS(rds_path)
  } else {
    df <- construir_dataset_maestro(config, guardar_archivos = TRUE)
  }

  assign("df", df, envir = .mpa_cache)
  assign("mtime", excel_mtime, envir = .mpa_cache)
  assign("excel", cache_key, envir = .mpa_cache)
  df
}
