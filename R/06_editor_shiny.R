# ==============================================================================
# MÓDULO 06: EDITOR INTERACTIVO SHINY + VISTA PREVIA TYPST (titulacionMPA)
# Permite visualizar el PDF renderizado en vivo y editar el texto de la plantilla
# ==============================================================================

#' Lanzar el editor interactivo de plantillas y vista previa Typst
#'
#' Abre una aplicación Shiny local donde el usuario puede seleccionar cualquier
#' predio y tipo de documento, editar directamente el contenido de texto de la
#' plantilla Typst, previsualizar el PDF renderizado en tiempo real (~0.2 s) y
#' guardar los cambios o exportar el PDF final.
#'
#' @param config Objeto de configuración devuelto por \code{cargar_config_proyecto()}.
#'   Si es \code{NULL}, carga la plantilla maestra de ejemplo de Parque del Carmen.
#' @param launch.browser Lógico; si es \code{TRUE}, abre el navegador automáticamente.
#' @param host Dirección IP de escucha (por defecto \code{"127.0.0.1"}; use
#'   \code{"0.0.0.0"} para exponer la app en la red local como servidor).
#' @param port Puerto TCP de escucha (por defecto automático; ej. \code{3838} para servidor).
#' @return Inicia la aplicación Shiny interactiva.
#' @examples
#' \dontrun{
#' lanzar_editor_mpa(config)
#' # Como servidor en red local:
#' lanzar_editor_mpa(config, host = "0.0.0.0", port = 3838, launch.browser = FALSE)
#' }
#' @export
lanzar_editor_mpa <- function(config = NULL, launch.browser = TRUE,
                              host = getOption("shiny.host", "127.0.0.1"),
                              port = getOption("shiny.port", NULL)) {
  for (pkg in c("shiny", "bslib")) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      stop("El paquete '", pkg, "' es necesario para el editor. Inst\u00e1lalo con install.packages('", pkg, "').")
    }
  }

  if (is.null(config)) {
    ej_excel <- ruta_recurso_paquete("extdata", "EJEMPLO_PLANTILLA_MAESTRA_PARQUE_DEL_CARMEN.xlsx")
    config <- cargar_config_proyecto(excel_path = ej_excel, output_base = "resultados_editor")
  }

  app_dir <- ruta_recurso_paquete("shiny", pkg_root = config$pkg_root)
  if (!dir.exists(app_dir)) stop("No se encontr\u00f3 la carpeta Shiny en: ", app_dir)

  shiny::shinyOptions(mpa_config = config)
  shiny::runApp(app_dir, launch.browser = launch.browser, host = host, port = port)
}
