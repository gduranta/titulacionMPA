# ==============================================================================
# MÓDULO 00: CONFIGURACIÓN MAESTRA DEL PROYECTO (titulacionMPA)
# Carga la configuración única desde el Excel Maestro o parámetros explícitos
# ==============================================================================

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
})

#' Localizar la raíz del paquete titulacionMPA de forma dinámica
#' @keywords internal
localizar_raiz_paquete <- function() {
  cur <- getwd()
  # Si estamos en el directorio padre que contiene titulacionMPA/
  if (dir.exists(file.path(cur, "titulacionMPA", "inst"))) {
    return(normalizePath(file.path(cur, "titulacionMPA"), winslash = "/"))
  }
  # Si estamos dentro de titulacionMPA/ o en un subdirectorio
  while (!file.exists(file.path(cur, "DESCRIPTION")) && dirname(cur) != cur) {
    cur <- dirname(cur)
  }
  if (file.exists(file.path(cur, "DESCRIPTION")) && dir.exists(file.path(cur, "inst"))) {
    return(normalizePath(cur, winslash = "/"))
  }
  # Si el paquete está instalado (ej. R CMD check o library(titulacionMPA))
  inst_root <- system.file(package = "titulacionMPA")
  if (nzchar(inst_root) && dir.exists(inst_root)) {
    return(normalizePath(inst_root, winslash = "/"))
  }
  stop("No se pudo localizar la carpeta ra\u00edz del paquete 'titulacionMPA'.")
}

#' Resolver ruta a un recurso del paquete (en desarrollo o instalado)
#' @keywords internal
ruta_recurso_paquete <- function(..., pkg_root = NULL) {
  res <- system.file(..., package = "titulacionMPA")
  if (nzchar(res) && (file.exists(res) || dir.exists(res))) {
    return(normalizePath(res, winslash = "/"))
  }
  if (is.null(pkg_root)) pkg_root <- localizar_raiz_paquete()
  cand_inst <- file.path(pkg_root, "inst", ...)
  if (file.exists(cand_inst) || dir.exists(cand_inst)) {
    return(normalizePath(cand_inst, winslash = "/"))
  }
  cand_direct <- file.path(pkg_root, ...)
  if (file.exists(cand_direct) || dir.exists(cand_direct)) {
    return(normalizePath(cand_direct, winslash = "/"))
  }
  cand_inst
}

#' Cargar configuración maestra del proyecto a partir del archivo Excel
#'
#' Lee la hoja 'CONFIGURACION' de la plantilla maestra en Excel (si existe) y
#' combina con rutas de memoria descriptiva y directorios de salida.
#'
#' @param excel_path Ruta al archivo Excel maestro de predios
#' @param memoria_path Ruta opcional a la Memoria Descriptiva (.docx)
#' @param output_base Carpeta raíz donde se guardarán los documentos generados
#' @param overrides Lista con valores que sobreescriban la configuración del Excel
#' @return Objeto de configuración de proyecto (lista)
#' @export
cargar_config_proyecto <- function(
    excel_path = NULL,
    memoria_path = NULL,
    output_base = "resultados_titulacion",
    overrides = list()
) {
  pkg_root <- localizar_raiz_paquete()
  
  if (is.null(excel_path) || !nzchar(trimws(excel_path))) {
    excel_path <- ruta_recurso_paquete("extdata", "PLANTILLA_MAESTRA_TITULACION.xlsx", pkg_root = pkg_root)
  }
  if (!file.exists(excel_path)) {
    stop("No se encontr\u00f3 el archivo Excel base: ", excel_path)
  }
  excel_abs <- normalizePath(excel_path, winslash = "/")
  
  memoria_abs <- if (!is.null(memoria_path) && nzchar(trimws(memoria_path)) && file.exists(memoria_path)) {
    normalizePath(memoria_path, winslash = "/")
  } else {
    NULL
  }
  
  # Valores institucionales por defecto
  cfg <- list(
    NOMBRE_SECTOR               = "ADV PARQUE DEL CARMEN",
    PARTIDA_MATRIZ              = "PE N\u00ba 02026313 Asientos 28 y 29",
    RES_APROBACION_LOTIZACION   = "Resoluci\u00f3n Gerencial N\u00b0051-2026-GDUR/MPA",
    FECHA_APROBACION_LOTIZACION = "16/02/2026",
    DISTRITO                    = "Anta",
    PROVINCIA                   = "Anta",
    DEPARTAMENTO                = "Cusco",
    ALCALDE_NOMBRE              = "Sr. ELIAS CCOLLATUPA CHACON",
    ALCALDE_DNI                 = "25315115",
    DOMICILIO_LEGAL             = "AV. Los Andes s/n Izcuchaca- Anta",
    GERENTE_MUNICIPAL           = "Ing. German Mendoza Morales",
    ASESOR_LEGAL                = "Abg. Richard Salas Cuadros",
    GERENTE_GDUR                = "MGT. ARQ. ELIZABETH ELVIRA ITUSACA QUISPE",
    SUBGERENTE_SGPUAT           = "MGT. ING. CESAR EDUARDO ECHENIQUE LESCANO",
    ORDENANZA_TUPA              = "Ordenanza Municipal N\u00b0019-2019-AL-CPA-MPA de fecha 27 de diciembre de 2019",
    ANIO_GESTION                = "2026",
    FECHA_DEFECTO_SGPUAT        = "24 de noviembre del 2026",
    FECHA_DEFECTO_GDUR          = "25 de noviembre de 2026",
    FECHA_DEFECTO_LEGAL         = "25 de NOVIEMBRE de 2026",
    FECHA_DEFECTO_RESOLUCION    = "25 de noviembre del 2026",
    FECHA_DEFECTO_TITULO        = "2026-11-25"
  )
  
  # Leer hoja CONFIGURACION si existe en el Excel
  hojas <- readxl::excel_sheets(excel_abs)
  if ("CONFIGURACION" %in% hojas) {
    df_cfg <- suppressMessages(readxl::read_excel(excel_abs, sheet = "CONFIGURACION"))
    if (all(c("PARAMETRO", "VALOR") %in% names(df_cfg))) {
      for (i in seq_len(nrow(df_cfg))) {
        k <- trimws(as.character(df_cfg$PARAMETRO[i]))
        v <- trimws(as.character(df_cfg$VALOR[i]))
        if (!is.na(k) && nzchar(k) && !is.na(v) && nzchar(v)) {
          cfg[[k]] <- v
        }
      }
    }
  }
  
  # Aplicar overrides explícitos
  for (nm in names(overrides)) {
    if (!is.null(overrides[[nm]])) cfg[[nm]] <- overrides[[nm]]
  }
  
  out_abs <- normalizePath(output_base, winslash = "/", mustWork = FALSE)
  
  list(
    meta = cfg,
    pkg_root = pkg_root,
    excel_path = excel_abs,
    memoria_path = memoria_abs,
    output_base = out_abs,
    rutas_salida = list(
      sgpuat     = file.path(out_abs, "01_subgerencia_sgpuat"),
      gdur       = file.path(out_abs, "02_gerencia_gdu"),
      legal      = file.path(out_abs, "03_asesoria_legal"),
      resolucion = file.path(out_abs, "04_resoluciones_alcaldia"),
      titulo     = file.path(out_abs, "05_titulos_propiedad")
    ),
    templates = list(
      sgpuat     = ruta_recurso_paquete("templates", "plantilla_sgpuat.qmd", pkg_root = pkg_root),
      gdur       = ruta_recurso_paquete("templates", "plantilla_gdur.qmd", pkg_root = pkg_root),
      legal      = ruta_recurso_paquete("templates", "plantilla_legal.qmd", pkg_root = pkg_root),
      resolucion = ruta_recurso_paquete("templates", "plantilla_resolucion.qmd", pkg_root = pkg_root),
      titulo     = ruta_recurso_paquete("templates", "plantilla_titulo.qmd", pkg_root = pkg_root)
    ),
    templates_typst = list(
      sgpuat     = ruta_recurso_paquete("templates_typst", "plantilla_sgpuat.typ", pkg_root = pkg_root),
      gdur       = ruta_recurso_paquete("templates_typst", "plantilla_gdur.typ", pkg_root = pkg_root),
      legal      = ruta_recurso_paquete("templates_typst", "plantilla_legal.typ", pkg_root = pkg_root),
      resolucion = ruta_recurso_paquete("templates_typst", "plantilla_resolucion.typ", pkg_root = pkg_root),
      titulo     = ruta_recurso_paquete("templates_typst", "plantilla_titulo.typ", pkg_root = pkg_root)
    ),
    postprocesador = ruta_recurso_paquete("python", "postprocesar_docx.py", pkg_root = pkg_root)
  )
}
