# ==============================================================================
# SERVIDOR LOCAL SHINY PARA titulacionMPA (usado detrás de Cloudflare Tunnel)
# ==============================================================================

port_env <- suppressWarnings(as.integer(Sys.getenv("MPA_PORT", "3838")))
if (is.na(port_env) || port_env <= 0L) port_env <- 3838L

host_env <- Sys.getenv("MPA_HOST", "127.0.0.1")
excel_env <- Sys.getenv("MPA_EXCEL_PATH", "")
output_env <- Sys.getenv("MPA_OUTPUT_BASE", "resultados_editor")

if (requireNamespace("pkgload", quietly = TRUE) && file.exists("DESCRIPTION")) {
  pkgload::load_all(".", quiet = TRUE)
} else if (requireNamespace("titulacionMPA", quietly = TRUE)) {
  library(titulacionMPA)
} else {
  stop("No se pudo cargar el paquete 'titulacionMPA'. Instálalo o ejecuta desde la raíz del proyecto.")
}

if (!nzchar(trimws(excel_env))) {
  excel_env <- system.file("extdata", "EJEMPLO_PLANTILLA_MAESTRA_PARQUE_DEL_CARMEN.xlsx", package = "titulacionMPA")
  if (!nzchar(excel_env) || !file.exists(excel_env)) {
    excel_env <- file.path("inst", "extdata", "EJEMPLO_PLANTILLA_MAESTRA_PARQUE_DEL_CARMEN.xlsx")
  }
}

cfg <- cargar_config_proyecto(
  excel_path  = excel_env,
  output_base = output_env
)

message("Iniciando servidor titulacionMPA en http://", host_env, ":", port_env)
message("Excel maestro: ", cfg$excel_path)

lanzar_editor_mpa(
  config         = cfg,
  launch.browser = FALSE,
  host           = host_env,
  port           = port_env
)
