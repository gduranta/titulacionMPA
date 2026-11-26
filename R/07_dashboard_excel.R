#' Localiza el ejecutable de Python disponible en el sistema
#'
#' @return Ruta al ejecutable de Python o lanza un error si no existe.
#' @keywords internal
buscar_python_mpa <- function() {
  candidatos <- c(
    Sys.which("python"),
    Sys.which("python3"),
    Sys.which("py")
  )
  candidatos <- candidatos[nzchar(candidatos)]
  if (length(candidatos) == 0L) {
    cli::cli_abort("No se encontr\u00f3 Python en el PATH del sistema.")
  }
  candidatos[[1L]]
}

#' Guarda o actualiza un predio y sus posesionarios en el Excel maestro
#'
#' Inserta un nuevo lote o actualiza uno existente (identificado por `mz` y
#' `lote`) en la hoja `PREDIOS` / `OBSERVACIONES FORMALIZACION ` del archivo
#' Excel maestro, preservando las demás hojas y el formato del libro.
#'
#' @param config Lista de configuración retornada por [cargar_config_proyecto()].
#' @param datos_predio Lista con los campos del predio (`mz`, `lote`, `partida`,
#'   `constancia`, `evaluacion`, `exp_constancia`, `exp_titulo`,
#'   `fecha_solicitud`, `anio_posesion`, `area`, `perimetro`, `matrimonio`,
#'   `convivencia`, `inf_sgpuat`, `inf_gdur`, `inf_legal`, `proveido`,
#'   `resolucion`, `titulo`, `lindero_frente`, `lindero_fondo`,
#'   `lindero_derecha`, `lindero_izquierda`) y `beneficiarios` (lista de listas
#'   con `nombre`, `dni`, `genero`, `solicitante`, `estado_civil`).
#' @return Lista con el resultado de la operación (`status`, `action`, `mz`,
#'   `lote`, `rows_written`, `start_row`).
#' @export
guardar_predio_excel <- function(config, datos_predio) {
  if (is.null(config$excel_path) || !file.exists(config$excel_path)) {
    cli::cli_abort("No existe el archivo Excel maestro en: {config$excel_path}")
  }

  script_py <- system.file("python", "excel_crud.py", package = "titulacionMPA")
  if (!nzchar(script_py) || !file.exists(script_py)) {
    script_py <- file.path("titulacionMPA", "inst", "python", "excel_crud.py")
  }
  if (!file.exists(script_py)) {
    cli::cli_abort("No se encontr\u00f3 el script excel_crud.py.")
  }

  py_bin <- buscar_python_mpa()
  tmp_json <- tempfile(fileext = ".json")
  on.exit(unlink(tmp_json), add = TRUE)

  json_txt <- jsonlite::toJSON(datos_predio, auto_unbox = TRUE, null = "null")
  writeLines(enc2utf8(json_txt), tmp_json, useBytes = TRUE)

  res_out <- system2(
    py_bin,
    args = c(shQuote(script_py), shQuote(config$excel_path), shQuote(tmp_json)),
    stdout = TRUE,
    stderr = TRUE
  )
  status_code <- attr(res_out, "status")
  if (!is.null(status_code) && status_code != 0L) {
    cli::cli_abort(c(
      "Error al guardar en el Excel maestro.",
      "i" = paste(res_out, collapse = "\n")
    ))
  }

  jsonlite::fromJSON(paste(res_out, collapse = "\n"))
}

#' Catálogo de campos protegidos provenientes del Excel maestro
#'
#' Devuelve el mapeo entre las variables `#data.<campo>` usadas en las plantillas
#' Typst y su descripción / columna en el Excel maestro.
#'
#' @return Data frame con columnas `variable`, `etiqueta` y `origen`.
#' @keywords internal
obtener_diccionario_campos_excel <- function() {
  data.frame(
    variable = c(
      "data.mz", "data.lote", "data.nombres_completo", "data.nombres_completo_y",
      "data.dnis_completo", "data.solicitante", "data.dni_solicitante",
      "data.tipo_sociedad", "data.estado_civil_texto", "data.area",
      "data.perimetro", "data.partida_matriz", "data.constancia_numero",
      "data.expediente_constancia", "data.expediente_titulo",
      "data.fecha_solicitud", "data.anio_posesion", "data.informe_sgpuat",
      "data.informe_gdur", "data.informe_legal", "data.proveido",
      "data.resolucion_numero", "data.titulo_numero", "data.lindero_frente",
      "data.lindero_fondo", "data.lindero_derecha", "data.lindero_izquierda",
      "data.requisitos_tupa", "data.fecha_actual"
    ),
    etiqueta = c(
      "Manzana", "Lote", "Posesionario(s) (coma)", "Posesionario(s) (y)",
      "DNI(s)", "Solicitante principal", "DNI solicitante",
      "Tipo de sociedad / titularidad", "Estado civil", "\u00c1rea (m2)",
      "Per\u00edmetro (ml)", "Partida matriz", "N.\u00b0 Constancia de posesi\u00f3n",
      "Exp. Constancia", "Exp. T\u00edtulo",
      "Fecha de solicitud", "A\u00f1o de posesi\u00f3n", "N.\u00b0 Informe SGPUAT",
      "N.\u00b0 Informe GDUR", "N.\u00b0 Informe Legal", "N.\u00b0 Prove\u00eddo",
      "N.\u00b0 Resoluci\u00f3n de Alcald\u00eda", "N.\u00b0 T\u00edtulo de Propiedad",
      "Lindero Frente", "Lindero Fondo", "Lindero Derecha", "Lindero Izquierda",
      "Requisitos TUPA (Matrimonio / Convivencia)", "Fecha del documento"
    ),
    origen = c(
      "Excel Col A (MZ)", "Excel Col B (LOTE)", "Excel Col F (POSESIONARIO(S))",
      "Excel Col F (POSESIONARIO(S))", "Excel Col G (DNI)", "Excel Col F + I (SOLICITANTE)",
      "Excel Col G + I", "Excel Col H + P (G\u00e9nero/Estado civil)",
      "Excel Col P (ESTADO CIVIL)", "Excel Col N (AREA M2)", "Excel Col O (PERIMETRO)",
      "Excel Col C (N.\u00b0 PARTIDA)", "Excel Col D (CONSTANCIA)", "Excel Col J (EXP. CONSTANCIA)",
      "Excel Col K (EXP. TITULO)", "Excel Col L (FECHA SOLICITUD)",
      "Excel Col M (A\u00d1O POSESION)", "Excel Col S (INF. SGPUAT)",
      "Excel Col T (INF. GDUR)", "Excel Col U (INF. LEGAL)", "Excel Col V (PROVEIDO)",
      "Excel Col W (RESOLUCION)", "Excel Col X (TITULO)", "Excel Col Y (FRENTE)",
      "Excel Col Z (FONDO)", "Excel Col AA (DERECHA)", "Excel Col AB (IZQUIERDA)",
      "Excel Col Q y R (TUPA)", "Selector de fecha / Sistema"
    ),
    stringsAsFactors = FALSE
  )
}
