# ==============================================================================
# MÓDULO 05: GENERADORES ESTANDARIZADOS DE DOCUMENTOS (titulacionMPA)
# Motor Typst para PDF (ultrarrápido) y Quarto+Python para DOCX
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(glue)
})

#' Serializar configuración de proyecto a archivo temporal RDS
#'
#' @param config Objeto de configuración devuelto por \code{cargar_config_proyecto()}.
#' @return Ruta absoluta al archivo temporal `.rds`.
#' @keywords internal
preparar_config_temp <- function(config) {
  if (is.null(config)) stop("Debe proporcionar un objeto 'config' creado con cargar_config_proyecto().")
  cfg_rds <- tempfile("cfg_mpa_", fileext = ".rds")
  saveRDS(config, cfg_rds)
  normalizePath(cfg_rds, winslash = "/")
}

#' Filtrar un único predio por manzana y lote
#'
#' @param df Tibble maestro de predios.
#' @param mz_nombre Código de manzana.
#' @param lote_nombre Código de lote.
#' @return Tibble de una sola fila correspondiente al predio solicitado.
#' @keywords internal
filtrar_lote_unico <- function(df, mz_nombre, lote_nombre) {
  mz_val <- toupper(trimws(as.character(mz_nombre)))
  lote_val <- trimws(as.character(lote_nombre))
  item <- dplyr::filter(df, toupper(.data$mz) == mz_val, as.character(.data$lote) == lote_val)
  if (nrow(item) != 1L) stop("No se encontr\u00f3 un \u00fanico registro para Mz. ", mz_val, " Lote ", lote_val)
  item[1, , drop = FALSE]
}

#' Filtrar predios numerados para generación en lote
#'
#' @param df Tibble maestro de predios.
#' @param col_name Nombre de la columna de correlativo a validar.
#' @param solo_numerados Lógico; si es \code{TRUE}, excluye registros vacíos o con \code{"XXX"}.
#' @param mz_nombre Manzana opcional para restringir el lote.
#' @return Tibble con columnas únicas \code{mz} y \code{lote}.
#' @keywords internal
filtrar_numerados <- function(df, col_name, solo_numerados = TRUE, mz_nombre = NULL) {
  if (!is.null(mz_nombre) && nzchar(trimws(mz_nombre))) {
    df <- df %>% dplyr::filter(toupper(.data$mz) == toupper(trimws(mz_nombre)))
  }
  if (isTRUE(solo_numerados)) {
    df <- df %>% dplyr::filter(
      !is.na(.data[[col_name]]) &
      nzchar(trimws(as.character(.data[[col_name]]))) &
      toupper(trimws(as.character(.data[[col_name]]))) != "XXX"
    )
  }
  df %>% dplyr::select("mz", "lote") %>% dplyr::distinct()
}

# ==============================================================================
# 1. INFORMES DE SUBGERENCIA (SGPUAT)
# ==============================================================================

#' Generar Informe Técnico de Subgerencia (SGPUAT) para un predio
#'
#' Genera el informe técnico-administrativo de evaluación TUPA emitido por la
#' Subgerencia de Planeamiento Urbano y Acondicionamiento Territorial.
#'
#' @param mz_nombre Manzana del predio (ej. \code{"A"}, \code{"C"}).
#' @param lote_nombre Lote del predio (ej. \code{"1"}, \code{"4-5-A"}).
#' @param config Objeto de configuración generado por \code{cargar_config_proyecto()}.
#' @param fecha Fecha oficial del informe. Por defecto toma \code{FECHA_DEFECTO_SGPUAT}.
#' @param num_informe Correlativo manual opcional; si es \code{NULL}, lee el del Excel.
#' @param formato Formato de salida: \code{"pdf"} (Typst rápido), \code{"docx"} (Word) o \code{"ambos"}.
#' @param output_dir Carpeta de destino. Por defecto \code{config$rutas_salida$sgpuat}.
#' @param sobrescribir Lógico; si es \code{TRUE}, reemplaza archivos existentes.
#' @param df_cache Dataset maestro pre-cargado (uso interno en procesos masivos).
#' @return Vector de caracteres con las rutas absolutas de los archivos generados.
#' @examples
#' \dontrun{
#' generar_informe_sgpuat("A", "1", config = config, formato = "pdf")
#' }
#' @export
generar_informe_sgpuat <- function(
    mz_nombre, lote_nombre, config,
    fecha = config$meta$FECHA_DEFECTO_SGPUAT,
    num_informe = NULL,
    formato = c("pdf", "ambos", "docx"),
    output_dir = config$rutas_salida$sgpuat,
    sobrescribir = TRUE, df_cache = NULL
) {
  formato <- match.arg(formato)
  df <- if (is.null(df_cache)) obtener_dataset_proyecto(config) else df_cache
  item <- filtrar_lote_unico(df, mz_nombre, lote_nombre)

  num_inf <- if (!is.null(num_informe) && nzchar(trimws(num_informe))) trimws(num_informe) else item$num_informe_sgpuat_num[[1]]
  lote_seguro <- gsub("[^[:alnum:]_-]", "_", item$lote[[1]])
  base_nombre <- glue::glue("INFORME_{num_inf}-{config$meta$ANIO_GESTION}-SGPUAT-GDUR-MPA_MZ_{item$mz[[1]]}_LOTE_{lote_seguro}")

  parametros_q <- character(0)
  if (formato %in% c("docx", "ambos")) {
    cfg_rds <- preparar_config_temp(config); on.exit(unlink(cfg_rds), add = TRUE)
    parametros_q <- c("-P", shQuote(glue::glue("config_rds:{cfg_rds}"), type = "cmd"), "-P", glue::glue("mz:{item$mz[[1]]}"), "-P", glue::glue("lote:{item$lote[[1]]}"), "-P", glue::glue("num_informe:{num_inf}"), "-P", shQuote(glue::glue("fecha:{fecha}"), type = "cmd"))
  }

  renderizar_documento_mpa(config, item, base_nombre, output_dir, parametros_q, "sgpuat", fecha, overrides = list(num_sgpuat = num_inf), formato = formato, sobrescribir = sobrescribir)
}

#' Generar todos los Informes Técnicos de Subgerencia (SGPUAT)
#'
#' Procesa en lote todos los predios (o los de una manzana específica), mostrando
#' el avance \code{[i/N]} y el tiempo total de ejecución.
#'
#' @param config Objeto de configuración generado por \code{cargar_config_proyecto()}.
#' @param fecha Fecha oficial de los informes.
#' @param formato Formato de salida: \code{"pdf"}, \code{"ambos"} o \code{"docx"}.
#' @param output_dir Carpeta de destino.
#' @param solo_numerados Si es \code{TRUE}, genera solo los predios con correlativo asignado en el Excel.
#' @param mz_nombre Manzana opcional para filtrar la generación.
#' @param sobrescribir Lógico; si es \code{TRUE}, sobrescribe archivos existentes.
#' @return Vector invisible con las rutas de todos los archivos generados.
#' @export
generar_todos_informes_sgpuat <- function(
    config, fecha = config$meta$FECHA_DEFECTO_SGPUAT,
    formato = c("pdf", "ambos", "docx"),
    output_dir = config$rutas_salida$sgpuat,
    solo_numerados = TRUE, mz_nombre = NULL, sobrescribir = FALSE
) {
  formato <- match.arg(formato)
  df <- obtener_dataset_proyecto(config, recargar = TRUE)
  predios <- filtrar_numerados(df, "num_informe_sgpuat_num", solo_numerados, mz_nombre)

  ejecutar_lote_generacion(predios, "Informes de Subgerencia (SGPUAT)", config$meta$NOMBRE_SECTOR,
    function(m, l) generar_informe_sgpuat(m, l, config = config, fecha = fecha, formato = formato, output_dir = output_dir, sobrescribir = sobrescribir, df_cache = df), output_dir)
}

# ==============================================================================
# 2. INFORMES DE GERENCIA (GDUR)
# ==============================================================================

#' Generar Informe de Gerencia de Desarrollo Urbano y Rural (GDUR)
#'
#' Genera el informe de remisión y opinión favorable de 1 página emitido por la GDUR.
#'
#' @inheritParams generar_informe_sgpuat
#' @return Vector de caracteres con las rutas absolutas de los archivos generados.
#' @export
generar_informe_gdur <- function(
    mz_nombre, lote_nombre, config,
    fecha = config$meta$FECHA_DEFECTO_GDUR,
    num_informe = NULL,
    formato = c("pdf", "ambos", "docx"),
    output_dir = config$rutas_salida$gdur,
    sobrescribir = TRUE, df_cache = NULL
) {
  formato <- match.arg(formato)
  df <- if (is.null(df_cache)) obtener_dataset_proyecto(config) else df_cache
  item <- filtrar_lote_unico(df, mz_nombre, lote_nombre)

  num_inf <- if (!is.null(num_informe) && nzchar(trimws(num_informe))) trimws(num_informe) else item$num_informe_gdur_num[[1]]
  lote_seguro <- gsub("[^[:alnum:]_-]", "_", item$lote[[1]])
  base_nombre <- glue::glue("INFORME_{num_inf}-{config$meta$ANIO_GESTION}-EEIQ-GDUR-MPA_MZ_{item$mz[[1]]}_LOTE_{lote_seguro}")

  parametros_q <- character(0)
  if (formato %in% c("docx", "ambos")) {
    cfg_rds <- preparar_config_temp(config); on.exit(unlink(cfg_rds), add = TRUE)
    parametros_q <- c("-P", shQuote(glue::glue("config_rds:{cfg_rds}"), type = "cmd"), "-P", glue::glue("mz:{item$mz[[1]]}"), "-P", glue::glue("lote:{item$lote[[1]]}"), "-P", glue::glue("num_informe:{num_inf}"), "-P", shQuote(glue::glue("fecha:{fecha}"), type = "cmd"))
  }

  renderizar_documento_mpa(config, item, base_nombre, output_dir, parametros_q, "gdur", fecha, overrides = list(num_gdur = num_inf), formato = formato, sobrescribir = sobrescribir)
}

#' Generar todos los Informes de Gerencia (GDUR)
#'
#' @inheritParams generar_todos_informes_sgpuat
#' @return Vector invisible con las rutas de todos los archivos generados.
#' @export
generar_todos_informes_gdur <- function(
    config, fecha = config$meta$FECHA_DEFECTO_GDUR,
    formato = c("pdf", "ambos", "docx"),
    output_dir = config$rutas_salida$gdur,
    solo_numerados = TRUE, mz_nombre = NULL, sobrescribir = FALSE
) {
  formato <- match.arg(formato)
  df <- obtener_dataset_proyecto(config, recargar = TRUE)
  predios <- filtrar_numerados(df, "num_informe_gdur_num", solo_numerados, mz_nombre)

  ejecutar_lote_generacion(predios, "Informes de Gerencia (GDUR)", config$meta$NOMBRE_SECTOR,
    function(m, l) generar_informe_gdur(m, l, config = config, fecha = fecha, formato = formato, output_dir = output_dir, sobrescribir = sobrescribir, df_cache = df), output_dir)
}

# ==============================================================================
# 3. INFORMES DE ASESORÍA LEGAL (GAL)
# ==============================================================================

#' Generar Informe Legal (GAL) para un predio
#'
#' Genera el dictamen de viabilidad legal emitido por la Gerencia de Asesoría Legal,
#' referenciando automáticamente los informes previos de SGPUAT y GDUR.
#'
#' @inheritParams generar_informe_sgpuat
#' @param num_informe_legal Correlativo manual opcional del informe legal.
#' @return Vector de caracteres con las rutas absolutas de los archivos generados.
#' @export
generar_informe_legal <- function(
    mz_nombre, lote_nombre, config,
    fecha = config$meta$FECHA_DEFECTO_LEGAL,
    num_informe_legal = NULL,
    formato = c("pdf", "ambos", "docx"),
    output_dir = config$rutas_salida$legal,
    sobrescribir = TRUE, df_cache = NULL
) {
  formato <- match.arg(formato)
  df <- if (is.null(df_cache)) obtener_dataset_proyecto(config) else df_cache
  item <- filtrar_lote_unico(df, mz_nombre, lote_nombre)

  num_leg <- if (!is.null(num_informe_legal) && nzchar(trimws(num_informe_legal))) trimws(num_informe_legal) else item$num_informe_legal_num[[1]]
  lote_seguro <- gsub("[^[:alnum:]_-]", "_", item$lote[[1]])
  base_nombre <- glue::glue("INFORME_LEGAL_{num_leg}-{config$meta$ANIO_GESTION}-GAL-MPA_MZ_{item$mz[[1]]}_LOTE_{lote_seguro}")

  parametros_q <- character(0)
  if (formato %in% c("docx", "ambos")) {
    cfg_rds <- preparar_config_temp(config); on.exit(unlink(cfg_rds), add = TRUE)
    parametros_q <- c("-P", shQuote(glue::glue("config_rds:{cfg_rds}"), type = "cmd"), "-P", glue::glue("mz:{item$mz[[1]]}"), "-P", glue::glue("lote:{item$lote[[1]]}"), "-P", glue::glue("num_informe_legal:{num_leg}"), "-P", shQuote(glue::glue("fecha:{fecha}"), type = "cmd"))
  }

  renderizar_documento_mpa(config, item, base_nombre, output_dir, parametros_q, "legal", fecha, overrides = list(num_legal = num_leg), formato = formato, sobrescribir = sobrescribir)
}

#' Generar todos los Informes de Asesoría Legal (GAL)
#'
#' @inheritParams generar_todos_informes_sgpuat
#' @return Vector invisible con las rutas de todos los archivos generados.
#' @export
generar_todos_informes_legales <- function(
    config, fecha = config$meta$FECHA_DEFECTO_LEGAL,
    formato = c("pdf", "ambos", "docx"),
    output_dir = config$rutas_salida$legal,
    solo_numerados = TRUE, mz_nombre = NULL, sobrescribir = FALSE
) {
  formato <- match.arg(formato)
  df <- obtener_dataset_proyecto(config, recargar = TRUE)
  predios <- filtrar_numerados(df, "num_informe_legal_num", solo_numerados, mz_nombre)

  ejecutar_lote_generacion(predios, "Informes de Asesor\u00eda Legal (GAL)", config$meta$NOMBRE_SECTOR,
    function(m, l) generar_informe_legal(m, l, config = config, fecha = fecha, formato = formato, output_dir = output_dir, sobrescribir = sobrescribir, df_cache = df), output_dir)
}

# ==============================================================================
# 4. RESOLUCIONES DE ALCALDÍA
# ==============================================================================

#' Generar Resolución de Alcaldía para un predio
#'
#' Genera la resolución municipal de otorgamiento de título con márgenes
#' calibrados para papel membretado (\code{3.0 cm} sup / \code{1.5 cm} inf) y tabla TUPA.
#'
#' @inheritParams generar_informe_sgpuat
#' @param num_resolucion Correlativo manual opcional de la Resolución de Alcaldía.
#' @return Vector de caracteres con las rutas absolutas de los archivos generados.
#' @export
generar_resolucion_alcaldia <- function(
    mz_nombre, lote_nombre, config,
    fecha = config$meta$FECHA_DEFECTO_RESOLUCION,
    num_resolucion = NULL,
    formato = c("pdf", "ambos", "docx"),
    output_dir = config$rutas_salida$resolucion,
    sobrescribir = TRUE, df_cache = NULL
) {
  formato <- match.arg(formato)
  df <- if (is.null(df_cache)) obtener_dataset_proyecto(config) else df_cache
  item <- filtrar_lote_unico(df, mz_nombre, lote_nombre)

  num_res <- if (!is.null(num_resolucion) && nzchar(trimws(num_resolucion))) trimws(num_resolucion) else item$num_resolucion_num[[1]]
  lote_seguro <- gsub("[^[:alnum:]_-]", "_", item$lote[[1]])
  base_nombre <- glue::glue("RESOLUCION_{num_res}-{config$meta$ANIO_GESTION}-A-MPA_MZ_{item$mz[[1]]}_LOTE_{lote_seguro}")

  parametros_q <- character(0)
  if (formato %in% c("docx", "ambos")) {
    cfg_rds <- preparar_config_temp(config); on.exit(unlink(cfg_rds), add = TRUE)
    parametros_q <- c("-P", shQuote(glue::glue("config_rds:{cfg_rds}"), type = "cmd"), "-P", glue::glue("mz:{item$mz[[1]]}"), "-P", glue::glue("lote:{item$lote[[1]]}"), "-P", glue::glue("num_resolucion:{num_res}"), "-P", shQuote(glue::glue("fecha:{fecha}"), type = "cmd"))
  }

  renderizar_documento_mpa(config, item, base_nombre, output_dir, parametros_q, "resolucion", fecha, overrides = list(num_res = num_res), formato = formato, sobrescribir = sobrescribir)
}

#' Generar todas las Resoluciones de Alcaldía
#'
#' @inheritParams generar_todos_informes_sgpuat
#' @return Vector invisible con las rutas de todos los archivos generados.
#' @export
generar_todas_resoluciones <- function(
    config, fecha = config$meta$FECHA_DEFECTO_RESOLUCION,
    formato = c("pdf", "ambos", "docx"),
    output_dir = config$rutas_salida$resolucion,
    solo_numerados = TRUE, mz_nombre = NULL, sobrescribir = FALSE
) {
  formato <- match.arg(formato)
  df <- obtener_dataset_proyecto(config, recargar = TRUE)
  predios <- filtrar_numerados(df, "num_resolucion_num", solo_numerados, mz_nombre)

  ejecutar_lote_generacion(predios, "Resoluciones de Alcald\u00eda", config$meta$NOMBRE_SECTOR,
    function(m, l) generar_resolucion_alcaldia(m, l, config = config, fecha = fecha, formato = formato, output_dir = output_dir, sobrescribir = sobrescribir, df_cache = df), output_dir)
}

# ==============================================================================
# 5. TÍTULOS DE PROPIEDAD
# ==============================================================================

#' Generar Título de Propiedad para un predio
#'
#' Genera el Título de Propiedad con márgenes de papel membretado, linderos y
#' bloque dinámico de firmas para 1, 2 o \eqn{N} copropietarios.
#'
#' @inheritParams generar_informe_sgpuat
#' @param fecha_emision Fecha de suscripción del título en formato \code{"YYYY-MM-DD"}.
#' @param fecha_resolucion Fecha de la Resolución de Alcaldía referenciada.
#' @param correlativo Número manual opcional del Título de Propiedad.
#' @param num_resolucion Número manual opcional de la Resolución de Alcaldía.
#' @return Vector de caracteres con las rutas absolutas de los archivos generados.
#' @export
generar_titulo_propiedad <- function(
    mz_nombre, lote_nombre, config,
    fecha_emision = config$meta$FECHA_DEFECTO_TITULO,
    fecha_resolucion = config$meta$FECHA_DEFECTO_RESOLUCION,
    correlativo = NULL, num_resolucion = NULL,
    formato = c("pdf", "ambos", "docx"),
    output_dir = config$rutas_salida$titulo,
    sobrescribir = TRUE, df_cache = NULL
) {
  formato <- match.arg(formato)
  df <- if (is.null(df_cache)) obtener_dataset_proyecto(config) else df_cache
  item <- filtrar_lote_unico(df, mz_nombre, lote_nombre)

  num_tit <- if (!is.null(correlativo) && nzchar(trimws(correlativo))) trimws(correlativo) else item$num_titulo_num[[1]]
  num_res <- if (!is.null(num_resolucion) && nzchar(trimws(num_resolucion))) trimws(num_resolucion) else item$num_resolucion_num[[1]]
  lote_seguro <- gsub("[^[:alnum:]_-]", "_", item$lote[[1]])
  base_nombre <- glue::glue("TITULO_{num_tit}-{config$meta$ANIO_GESTION}-A-MPA-C_MZ_{item$mz[[1]]}_LOTE_{lote_seguro}")

  parametros_q <- character(0)
  if (formato %in% c("docx", "ambos")) {
    cfg_rds <- preparar_config_temp(config); on.exit(unlink(cfg_rds), add = TRUE)
    parametros_q <- c("-P", shQuote(glue::glue("config_rds:{cfg_rds}"), type = "cmd"), "-P", glue::glue("mz:{item$mz[[1]]}"), "-P", glue::glue("lote:{item$lote[[1]]}"), "-P", glue::glue("correlativo:{num_tit}"), "-P", glue::glue("num_resolucion:{num_res}"), "-P", shQuote(glue::glue("fecha_resolucion:{fecha_resolucion}"), type = "cmd"), "-P", shQuote(glue::glue("fecha_emision:{fecha_emision}"), type = "cmd"))
  }

  renderizar_documento_mpa(config, item, base_nombre, output_dir, parametros_q, "titulo", fecha_resolucion,
    overrides = list(corr = num_tit, num_res = num_res, fecha_resolucion = fecha_resolucion, fecha_emision = fecha_emision),
    formato = formato, sobrescribir = sobrescribir)
}

#' Generar todos los Títulos de Propiedad
#'
#' @inheritParams generar_todos_informes_sgpuat
#' @param fecha_emision Fecha de suscripción en formato \code{"YYYY-MM-DD"}.
#' @param fecha_resolucion Fecha de la Resolución de Alcaldía referenciada.
#' @return Vector invisible con las rutas de todos los archivos generados.
#' @export
generar_todos_titulos <- function(
    config, fecha_emision = config$meta$FECHA_DEFECTO_TITULO,
    fecha_resolucion = config$meta$FECHA_DEFECTO_RESOLUCION,
    formato = c("pdf", "ambos", "docx"),
    output_dir = config$rutas_salida$titulo,
    solo_numerados = TRUE, mz_nombre = NULL, sobrescribir = FALSE
) {
  formato <- match.arg(formato)
  df <- obtener_dataset_proyecto(config, recargar = TRUE)
  predios <- filtrar_numerados(df, "num_titulo_num", solo_numerados, mz_nombre)

  ejecutar_lote_generacion(predios, "T\u00edtulos de Propiedad", config$meta$NOMBRE_SECTOR,
    function(m, l) generar_titulo_propiedad(m, l, config = config, fecha_emision = fecha_emision, fecha_resolucion = fecha_resolucion, formato = formato, output_dir = output_dir, sobrescribir = sobrescribir, df_cache = df), output_dir)
}

# ==============================================================================
# 6. EXPEDIENTE COMPLETO (LOS 5 DOCUMENTOS PARA UN PREDIO)
# ==============================================================================

#' Generar los 5 documentos completos para un único predio
#'
#' Orquesta la generación secuencial de: (1) Informe SGPUAT, (2) Informe GDUR,
#' (3) Informe Legal, (4) Resolución de Alcaldía y (5) Título de Propiedad.
#'
#' @inheritParams generar_informe_sgpuat
#' @return Lista nombrada con las rutas generadas por tipo de documento.
#' @examples
#' \dontrun{
#' generar_expediente_completo("A", "1", config = config, formato = "pdf")
#' }
#' @export
generar_expediente_completo <- function(
    mz_nombre, lote_nombre, config,
    formato = c("pdf", "ambos", "docx"),
    sobrescribir = TRUE
) {
  formato <- match.arg(formato)
  df <- obtener_dataset_proyecto(config)
  message(glue::glue("Generando expediente completo (5 documentos) para Mz. {mz_nombre} Lote {lote_nombre}..."))
  list(
    sgpuat     = generar_informe_sgpuat(mz_nombre, lote_nombre, config, formato = formato, sobrescribir = sobrescribir, df_cache = df),
    gdur       = generar_informe_gdur(mz_nombre, lote_nombre, config, formato = formato, sobrescribir = sobrescribir, df_cache = df),
    legal      = generar_informe_legal(mz_nombre, lote_nombre, config, formato = formato, sobrescribir = sobrescribir, df_cache = df),
    resolucion = generar_resolucion_alcaldia(mz_nombre, lote_nombre, config, formato = formato, sobrescribir = sobrescribir, df_cache = df),
    titulo     = generar_titulo_propiedad(mz_nombre, lote_nombre, config, formato = formato, sobrescribir = sobrescribir, df_cache = df)
  )
}
