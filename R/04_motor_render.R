# ==============================================================================
# MÓDULO 04: MOTOR COMÚN DE RENDERIZADO (TYPST PDF + QUARTO DOCX)
# Compilación ultrarrápida con Typst para PDF y Quarto+Python para Word (.docx)
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
  library(glue)
})

buscar_typst_mpa <- function() {
  bin <- Sys.which("typst")
  if (nzchar(bin)) return(bin)
  candidatos <- c(
    "C:/Program Files/RStudio/resources/app/bin/quarto/bin/tools/x86_64/typst.exe",
    "C:/Program Files/RStudio/resources/app/bin/quarto/bin/tools/typst.exe",
    "C:/Program Files/Quarto/bin/tools/x86_64/typst.exe",
    "C:/Program Files/Quarto/bin/tools/typst.exe"
  )
  encontrados <- candidatos[file.exists(candidatos)]
  if (length(encontrados) > 0) return(encontrados[[1]])
  stop("No se encontr\u00f3 el ejecutable de Typst en el sistema.")
}

buscar_quarto_mpa <- function() {
  bin <- Sys.which("quarto")
  if (nzchar(bin)) return(bin)
  candidatos <- c(
    "C:/Program Files/RStudio/resources/app/bin/quarto/bin/quarto.exe",
    "C:/Program Files/Quarto/bin/quarto.exe",
    file.path(Sys.getenv("LOCALAPPDATA"), "Programs/Quarto/bin/quarto.exe")
  )
  encontrados <- candidatos[file.exists(candidatos)]
  if (length(encontrados) > 0) encontrados[[1]] else "quarto"
}

buscar_python_mpa <- function() {
  py <- Sys.which("python")
  if (nzchar(py)) return(py)
  py3 <- Sys.which("python3")
  if (nzchar(py3)) return(py3)
  "python"
}

escribir_json_mpa <- function(lst, path) {
  esc <- function(x) {
    s <- as.character(x)
    if (length(s) == 0 || is.na(s)) s <- ""
    s <- gsub("\\\\", "\\\\\\\\", s)
    s <- gsub("\"", "\\\\\"", s)
    s <- gsub("\r?\n", "\\\\n", s)
    paste0("\"", s, "\"")
  }
  pares <- vapply(names(lst), function(nm) {
    val <- lst[[nm]]
    if (is.numeric(val) && !is.na(val)) {
      paste0(esc(nm), ": ", val)
    } else {
      paste0(esc(nm), ": ", esc(val))
    }
  }, character(1))
  writeLines(paste0("{\n  ", paste(pares, collapse = ",\n  "), "\n}"), path, useBytes = TRUE)
}

construir_payload_typst_mpa <- function(item, config, fecha_doc, overrides = list()) {
  unir_y <- function(vec) {
    vec <- vec[nzchar(vec)]
    n <- length(vec)
    if (n == 0L) return("")
    if (n == 1L) return(vec[1])
    if (n == 2L) return(paste(vec[1], "y", vec[2]))
    paste0(paste(vec[-n], collapse = ", "), " y ", vec[n])
  }

  mz <- as.character(item$mz[[1]])
  lote <- as.character(item$lote[[1]])
  lote_str <- if (grepl("^[0-9]$", lote)) paste0("0", lote) else lote
  partida <- as.character(item$partida[[1]])
  expediente <- as.character(item$expediente[[1]])

  num_sgpuat <- if (!is.null(overrides$num_sgpuat)) overrides$num_sgpuat else as.character(item$num_informe_sgpuat_num[[1]])
  num_gdur   <- if (!is.null(overrides$num_gdur))   overrides$num_gdur   else as.character(item$num_informe_gdur_num[[1]])
  num_legal  <- if (!is.null(overrides$num_legal))  overrides$num_legal  else as.character(item$num_informe_legal_num[[1]])
  num_res    <- if (!is.null(overrides$num_res))    overrides$num_res    else as.character(item$num_resolucion_num[[1]])
  corr       <- if (!is.null(overrides$corr))       overrides$corr       else as.character(item$num_titulo_num[[1]])
  num_prov   <- if (!is.null(overrides$num_prov))   overrides$num_prov   else {
    p_raw <- as.character(item$num_proveido_sg[[1]])
    m <- stringr::str_extract(p_raw, "[0-9]+")
    if (is.na(m) || !nzchar(m)) "XXXX" else m
  }

  # Fecha de solicitud del expediente
  f_sol <- as.character(item$fecha_solicitud[[1]])
  fecha_exp <- if (nzchar(f_sol) && grepl("^[0-9]+$", f_sol)) {
    d <- as.Date(as.numeric(f_sol), origin = "1899-12-30")
    meses <- c("enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre")
    paste0(as.integer(format(d, "%d")), " de ", meses[as.integer(format(d, "%m"))], " del ", format(d, "%Y"))
  } else if (nzchar(f_sol)) f_sol else "18 de noviembre del 2026"

  # Fecha de emisión de título en letras
  f_emision <- if (!is.null(overrides$fecha_emision)) overrides$fecha_emision else config$meta$FECHA_DEFECTO_TITULO
  f_date <- suppressWarnings(as.Date(f_emision))
  if (is.na(f_date)) f_date <- as.Date("2026-11-25")
  meses <- c("enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre")
  dia <- format(f_date, "%d")
  mes <- meses[as.integer(format(f_date, "%m"))]
  anio_num <- as.integer(format(f_date, "%Y"))
  anio_letras <- if (anio_num == 2026L) "dos mil veintis\u00e9is" else if (anio_num == 2025L) "dos mil veinticinco" else as.character(anio_num)

  # Datos de beneficiarios (1, 2 o N)
  ben_df <- if ("beneficiarios" %in% names(item) && length(item$beneficiarios) > 0 && is.data.frame(item$beneficiarios[[1]])) {
    item$beneficiarios[[1]]
  } else NULL
  n_tit <- if (!is.null(ben_df)) nrow(ben_df) else if (isTRUE(item$es_pareja[[1]])) 2L else 1L
  es_par <- n_tit >= 2L
  fem1 <- isTRUE(item$fem1[[1]])
  t1_nom <- as.character(item$t1_nombre[[1]])
  t1_dni <- as.character(item$t1_dni[[1]])
  est_civ <- toupper(trimws(as.character(item$estado_civil[[1]])))
  sector <- config$meta$NOMBRE_SECTOR

  # Textos para Legal
  admin_solic_ant <- if (fem1) glue::glue("la administrada {t1_nom}") else glue::glue("el administrado {t1_nom}")
  if (!is.null(ben_df) && n_tit >= 3L) {
    sujeto_posesion <- paste("los administrados", unir_y(paste(ifelse(ben_df$es_fem, "Sra.", "Sr."), ben_df$nombre)))
    titulares_legal <- unir_y(purrr::map_chr(seq_len(n_tit), function(k) {
      tr <- if (ben_df$es_fem[k]) "Sra." else "Sr."
      id <- if (ben_df$es_fem[k]) "identificada" else "identificado"
      glue::glue("{tr} {ben_df$nombre[k]} {id} con DNI N\u00ba {ben_df$dni[k]} de estado civil {ben_df$est_civ_sing[k]}")
    }))
  } else if (es_par && !is.null(ben_df) && n_tit == 2L) {
    sujeto_posesion <- glue::glue("los administrados {ifelse(ben_df$es_fem[1],'Sra.','Sr.')} {ben_df$nombre[1]} y {ifelse(ben_df$es_fem[2],'Sra.','Sr.')} {ben_df$nombre[2]}")
    titulares_legal <- unir_y(purrr::map_chr(1:2, function(k) {
      tr <- if (ben_df$es_fem[k]) "Sra." else "Sr."
      id <- if (ben_df$es_fem[k]) "identificada" else "identificado"
      glue::glue("{tr} {ben_df$nombre[k]} {id} con DNI N\u00ba {ben_df$dni[k]} de estado civil {ben_df$est_civ_sing[k]}")
    }))
  } else {
    ec1 <- if (!is.null(ben_df) && n_tit >= 1L) ben_df$est_civ_sing[1] else tolower(est_civ)
    sujeto_posesion <- glue::glue("{ifelse(fem1,'la administrada Sra.','el administrado Sr.')} {t1_nom}")
    titulares_legal <- glue::glue("{ifelse(fem1,'Sra.','Sr.')} {t1_nom} {ifelse(fem1,'identificada','identificado')} con DNI N\u00ba {t1_dni} de estado civil {ec1}")
  }

  # Textos para Resolución
  if (!is.null(ben_df) && n_tit >= 2L) {
    titular_fut <- unir_y(purrr::map_chr(seq_len(n_tit), function(k) {
      art <- if (k == 1L) "" else if (ben_df$es_fem[k]) "la " else "el "
      glue::glue("{art}{ben_df$trat_corto[k]} {ben_df$nombre[k]} {ben_df$ident[k]} con DNI N\u00ba {ben_df$dni[k]}")
    }))
    titulares_res <- paste("los administrados", unir_y(purrr::map_chr(seq_len(n_tit), function(k) {
      art <- if (k == 1L) "" else if (ben_df$es_fem[k]) "la " else "el "
      glue::glue("{art}{ben_df$trat_corto[k]} {ben_df$nombre[k]} {ben_df$ident[k]} con DNI N\u00ba {ben_df$dni[k]} de estado civil {ben_df$est_civ_sing[k]}")
    })))
  } else {
    ec1 <- if (!is.null(ben_df) && n_tit >= 1L) ben_df$est_civ_sing[1] else tolower(est_civ)
    titular_fut <- glue::glue("{ifelse(fem1,'sra.','sr.')} {t1_nom} {ifelse(fem1,'identificada','identificado')} con DNI N\u00ba {t1_dni}")
    titulares_res <- glue::glue("{ifelse(fem1,'la administrada sra.','el administrado sr.')} {t1_nom} {ifelse(fem1,'identificada','identificado')} con DNI N\u00ba {t1_dni}, de estado civil {ec1}")
  }

  # Textos para Título de Propiedad
  if (!is.null(ben_df) && n_tit >= 2L) {
    p1_vec <- purrr::map_chr(seq_len(n_tit), function(k) {
      pref <- if (k == 1L) "Que" else "que"
      glue::glue("{pref} {ben_df$don[k]}: {ben_df$nombre[k]}, de estado civil: {ben_df$est_civ_sing[k]} {stringr::str_to_title(ben_df$ident[k])} con D.N.I N.\u00b0 {ben_df$dni[k]}")
    })
    txt_primero <- glue::glue("{paste(p1_vec, collapse = ', ')} A quienes en lo sucesivo se denominar\u00e1 LOS ADJUDICATARIOS, han demostrado reunir los requisitos que establece el Texto \u00danico de Procedimiento Administrativo (TUPA) de la Municipalidad Provincial de Anta para la adquisici\u00f3n de la Propiedad de la Mz \u201c{mz}\u201d Lote {lote} que poseen, de la {sector} ubicado en el distrito y provincia de {config$meta$PROVINCIA}, departamento de {config$meta$DEPARTAMENTO}.")

    p4_vec <- purrr::map_chr(seq_len(n_tit), function(k) {
      glue::glue("{ben_df$don[k]}: {ben_df$nombre[k]} {stringr::str_to_title(ben_df$ident[k])} con D.N.I N.\u00b0 {ben_df$dni[k]} de estado civil {ben_df$est_civ_sing[k]}")
    })
    txt_cuarto_tit <- glue::glue("Que, {unir_y(p4_vec)}, han demostrado reunir los requisitos que establece la ley, para la adjudicaci\u00f3n de la propiedad del predio del cual se encuentran en condici\u00f3n de posesionarios en predio Lote N.\u00b0 {lote} de la Manzana \u201c{mz}\u201d de la {sector} ubicado en el distrito y provincia de {config$meta$PROVINCIA}, departamento de {config$meta$DEPARTAMENTO}.")
    txt_cuarto_otorga <- "procede otorgarles el presente T\u00edtulo"
    txt_septimo_adj <- "a nombre de los adjudicatarios"
    txt_octavo_tit <- "de los titulares"
  } else {
    ec1 <- if (!is.null(ben_df) && n_tit >= 1L) ben_df$est_civ_sing[1] else tolower(est_civ)
    don1 <- if (fem1) "Do\u00f1a" else "Don"
    id1 <- if (fem1) "Identificada" else "Identificado"
    adj_nom <- if (fem1) "LA ADJUDICATARIA" else "EL ADJUDICATARIO"
    pos_cond <- if (fem1) "posesionaria" else "posesionario"
    txt_primero <- glue::glue("Que {don1}: {t1_nom}, de estado civil: {ec1} {id1} con D.N.I N.\u00b0 {t1_dni} A quien en lo sucesivo se denominar\u00e1 {adj_nom}, ha demostrado reunir los requisitos que establece el Texto \u00danico de Procedimiento Administrativo (TUPA) de la Municipalidad Provincial de Anta para la adquisici\u00f3n de la Propiedad de la Mz \u201c{mz}\u201d Lote {lote} que posee, de la {sector} ubicado en el distrito y provincia de {config$meta$PROVINCIA}, departamento de {config$meta$DEPARTAMENTO}.")
    txt_cuarto_tit <- glue::glue("Que, {don1}: {t1_nom} {id1} con D.N.I N.\u00b0 {t1_dni}, de estado civil {ec1}, ha demostrado reunir los requisitos que establece la ley, para la adjudicaci\u00f3n de la propiedad del predio del cual se encuentra en condici\u00f3n de {pos_cond} en predio Lote N.\u00b0 {lote} de la Manzana \u201c{mz}\u201d de la {sector} ubicado en el distrito y provincia de {config$meta$PROVINCIA}, departamento de {config$meta$DEPARTAMENTO}.")
    txt_cuarto_otorga <- "procede otorgarle el presente T\u00edtulo"
    txt_septimo_adj <- if (fem1) "a nombre de la adjudicataria" else "a nombre del adjudicatario"
    txt_octavo_tit <- if (fem1) "de la titular" else "del titular"
  }

  formatear_lindero <- function(linea, prefijo) {
    if (is.null(linea) || is.na(linea) || !nzchar(trimws(as.character(linea)))) return(paste0(prefijo, " : "))
    cuerpo <- sub("^Por (?:el|la) (?:frente|fondo|derecha|izquierda|costado derecho|costado izquierdo)\\s*:\\s*", "", trimws(as.character(linea)), ignore.case = TRUE)
    paste0(prefijo, " : ", cuerpo)
  }

  list(
    anio = config$meta$ANIO_GESTION,
    sector = sector,
    partida_matriz = config$meta$PARTIDA_MATRIZ,
    res_lotizacion = config$meta$RES_APROBACION_LOTIZACION,
    fecha_lotizacion = config$meta$FECHA_APROBACION_LOTIZACION,
    ordenanza_tupa = config$meta$ORDENANZA_TUPA,
    distrito = config$meta$DISTRITO,
    provincia = config$meta$PROVINCIA,
    departamento = config$meta$DEPARTAMENTO,
    alcalde = sub("^Sr\\.?\\s*", "", config$meta$ALCALDE_NOMBRE),
    dni_alc = config$meta$ALCALDE_DNI,
    dom_leg = config$meta$DOMICILIO_LEGAL,
    gerente_mun = config$meta$GERENTE_MUNICIPAL,
    asesor_legal = config$meta$ASESOR_LEGAL,
    gerente_gdur = config$meta$GERENTE_GDUR,
    subgerente_sg = config$meta$SUBGERENTE_SGPUAT,
    mz = mz,
    lote = lote,
    lote_str = lote_str,
    partida = partida,
    expediente = expediente,
    fecha_exp = fecha_exp,
    fecha_doc = fecha_doc,
    fecha_sgpuat = config$meta$FECHA_DEFECTO_SGPUAT,
    fecha_gdur = config$meta$FECHA_DEFECTO_GDUR,
    fecha_legal = config$meta$FECHA_DEFECTO_LEGAL,
    fecha_prov = config$meta$FECHA_DEFECTO_RESOLUCION,
    fecha_res = if (!is.null(overrides$fecha_resolucion)) overrides$fecha_resolucion else config$meta$FECHA_DEFECTO_RESOLUCION,
    dia = dia,
    mes = mes,
    anio_letras = anio_letras,
    num_sgpuat = num_sgpuat,
    num_gdur = num_gdur,
    num_legal = num_legal,
    num_res = num_res,
    num_prov = num_prov,
    corr = corr,
    t1_nombre = t1_nom,
    tratamiento = if (fem1) "Sra." else "Sr.",
    solicitante_saludo = as.character(item$solicitante_saludo[[1]]),
    quien_solicita = if (es_par) "quienes solicitan" else "quien solicita",
    titulares_informe = as.character(item$titulares_informe[[1]]),
    nombres_resumen = as.character(item$nombres_resumen[[1]]),
    nombres_constata = as.character(item$nombres_constata[[1]]),
    sujeto_admin = as.character(item$sujeto_admin[[1]]),
    sujeto_admin_cap = as.character(item$sujeto_admin_cap[[1]]),
    sujeto_solicitan = as.character(item$sujeto_solicitan[[1]]),
    sujeto_vienen = as.character(item$sujeto_vienen[[1]]),
    sujeto_adjuntan = as.character(item$sujeto_adjuntan[[1]]),
    sujeto_cumplido = as.character(item$sujeto_cumplido[[1]]),
    sujeto_declaran = as.character(item$sujeto_declaran[[1]]),
    sujeto_presentan = as.character(item$sujeto_presentan[[1]]),
    evaluacion_formateada = as.character(item$evaluacion_formateada[[1]]),
    anio_pos = as.character(item$anio_pos[[1]]),
    area = as.character(item$area_formateada[[1]]),
    perimetro = as.character(item$perimetro_formateado[[1]]),
    tupa_6 = as.character(item$tupa_defuncion[[1]]),
    tupa_7 = as.character(item$tupa_matrimonio[[1]]),
    tupa_8 = as.character(item$tupa_convivencia[[1]]),
    admin_solic_ant = admin_solic_ant,
    sujeto_posesion = sujeto_posesion,
    titulares_legal = titulares_legal,
    titular_fut = titular_fut,
    verbo_fut = if (es_par) "solicitan la formalizaci\u00f3n" else "solicita la formalizaci\u00f3n",
    posesion_fut = if (es_par) "vienen ejerciendo posesi\u00f3n" else "viene ejerciendo posesi\u00f3n",
    solicitante_eval = if (es_par) "los administrados" else if (fem1) "la administrada" else "el administrado",
    titulares_res = titulares_res,
    interesado_notif = if (es_par) "a los administrados interesados" else if (fem1) "a la administrada interesada" else "al administrado interesado",
    txt_primero = txt_primero,
    txt_cuarto_tit = txt_cuarto_tit,
    txt_cuarto_otorga = txt_cuarto_otorga,
    txt_septimo_adj = txt_septimo_adj,
    txt_octavo_tit = txt_octavo_tit,
    txt_frente = formatear_lindero(item$linderos_frente[[1]], "Por el frente"),
    txt_fondo = formatear_lindero(item$linderos_fondo[[1]], "Por el fondo"),
    txt_derecha = formatear_lindero(item$linderos_derecha[[1]], "Por la derecha"),
    txt_izquierda = formatear_lindero(item$linderos_izquierda[[1]], "Por la izquierda"),
    n_tit = as.integer(n_tit)
  )
}

#' Renderizar documento: Typst para PDF (ultrarrápido) y Quarto+Python para DOCX
#' @keywords internal
renderizar_documento_mpa <- function(
    config,
    item,
    base_nombre,
    output_dir,
    parametros_quarto,
    tipo_doc,
    fecha_doc,
    overrides = list(),
    formato = c("pdf", "ambos", "docx"),
    sobrescribir = TRUE
) {
  formato <- match.arg(formato)
  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  formatos_eval <- if (formato == "ambos") c("docx", "pdf") else formato
  rutas_generadas <- character(0)

  for (ext in formatos_eval) {
    salida_archivo <- file.path(output_dir, paste0(base_nombre, ".", ext))

    if (!isTRUE(sobrescribir) && file.exists(salida_archivo) && file.info(salida_archivo)$size > 0) {
      rutas_generadas <- c(rutas_generadas, normalizePath(salida_archivo, winslash = "/"))
      next
    }

    if (ext == "pdf") {
      # Motor Typst directo
      tmpl_typ <- config$templates_typst[[tipo_doc]]
      if (!file.exists(tmpl_typ)) stop("No se encontr\u00f3 la plantilla Typst: ", tmpl_typ)

      payload <- construir_payload_typst_mpa(item, config, fecha_doc, overrides = overrides)
      tmpl_dir <- dirname(normalizePath(tmpl_typ, winslash = "/"))
      json_name <- paste0("_tmp_", tipo_doc, "_", Sys.getpid(), ".json")
      json_path <- file.path(tmpl_dir, json_name)
      escribir_json_mpa(payload, json_path)

      typst_bin <- buscar_typst_mpa()
      pdf_tmp <- file.path(tmpl_dir, paste0(base_nombre, "_", Sys.getpid(), ".pdf"))
      args <- c(
        "compile",
        normalizePath(tmpl_typ, winslash = "/"),
        normalizePath(pdf_tmp, winslash = "/", mustWork = FALSE),
        "--input", paste0("json_file=", json_name)
      )
      res <- suppressWarnings(system2(typst_bin, args, stdout = TRUE, stderr = TRUE))
      unlink(json_path)
      status <- attr(res, "status")

      if (!file.exists(pdf_tmp) || (!is.null(status) && status != 0L)) {
        unlink(pdf_tmp)
        warning(glue::glue("Error al compilar {base_nombre}.pdf con Typst:\n{paste(res, collapse='\n')}"))
        next
      }

      cp_ok <- suppressWarnings(file.copy(pdf_tmp, salida_archivo, overwrite = TRUE))
      if (!cp_ok) {
        alt <- file.path(output_dir, paste0(base_nombre, "_nuevo.pdf"))
        if (suppressWarnings(file.copy(pdf_tmp, alt, overwrite = TRUE))) salida_archivo <- alt
      }
      unlink(pdf_tmp)
      if (file.exists(salida_archivo)) {
        rutas_generadas <- c(rutas_generadas, normalizePath(salida_archivo, winslash = "/"))
      }
    } else if (ext == "docx") {
      # Motor Quarto + Python para Word editable
      tmpl_qmd <- config$templates[[tipo_doc]]
      if (!file.exists(tmpl_qmd)) stop("No se encontr\u00f3 la plantilla Quarto: ", tmpl_qmd)

      quarto_cmd <- buscar_quarto_mpa()
      python_cmd <- buscar_python_mpa()
      tmpl_dir <- dirname(tmpl_qmd)
      nombre_temp <- paste0(base_nombre, "_", Sys.getpid(), ".docx")
      candidatos <- c(file.path(tmpl_dir, nombre_temp), nombre_temp)
      unlink(candidatos[file.exists(candidatos)])

      args <- c("render", tmpl_qmd, parametros_quarto, "--to", "docx", "--output", nombre_temp)
      res_log <- suppressWarnings(system2(quarto_cmd, args, stdout = TRUE, stderr = TRUE))
      status <- attr(res_log, "status")
      generado <- candidatos[file.exists(candidatos)][1]

      if (is.na(generado) || (!is.null(status) && status != 0L)) {
        warning(glue::glue("Error al generar {base_nombre}.docx con Quarto:\n{paste(tail(res_log, 10), collapse='\n')}"))
        next
      }

      if (file.exists(config$postprocesador)) {
        system2(python_cmd, args = c(shQuote(config$postprocesador), shQuote(generado), tipo_doc), stdout = FALSE, stderr = FALSE)
      }

      cp_ok <- suppressWarnings(file.copy(generado, salida_archivo, overwrite = TRUE))
      if (!cp_ok) {
        alt <- file.path(output_dir, paste0(base_nombre, "_nuevo.docx"))
        if (suppressWarnings(file.copy(generado, alt, overwrite = TRUE))) salida_archivo <- alt
      }
      unlink(generado)
      if (file.exists(salida_archivo)) {
        rutas_generadas <- c(rutas_generadas, normalizePath(salida_archivo, winslash = "/"))
      }
    }
  }

  rutas_generadas
}

#' Ejecutar generación masiva estandarizada con reporte de avance `[i/N]` y tiempo
#' @keywords internal
ejecutar_lote_generacion <- function(
    df_lotes,
    etiqueta_doc,
    sector_nombre,
    fn_individual,
    output_dir
) {
  n <- nrow(df_lotes)
  if (n == 0L) {
    message(glue::glue("No hay registros disponibles para generar {etiqueta_doc} en '{sector_nombre}'."))
    return(invisible(character(0)))
  }

  t0 <- proc.time()
  message(glue::glue("Iniciando generaci\u00f3n de {n} {etiqueta_doc} para {sector_nombre}..."))

  todas_rutas <- character(0)
  for (i in seq_len(n)) {
    mz_i <- df_lotes$mz[i]
    lote_i <- df_lotes$lote[i]
    tryCatch({
      archivos <- fn_individual(mz_i, lote_i)
      todas_rutas <- c(todas_rutas, archivos)
      message(glue::glue("[{i}/{n}] Generado: Mz. {mz_i} Lote {lote_i}"))
    }, error = function(e) {
      warning(glue::glue("[{i}/{n}] Error en Mz. {mz_i} Lote {lote_i}: {conditionMessage(e)}"))
    })
  }

  elapsed <- round((proc.time() - t0)[["elapsed"]], 2)
  message(glue::glue("Finalizado en {elapsed}s: {length(todas_rutas)} archivos en '{output_dir}'."))
  invisible(todas_rutas)
}
