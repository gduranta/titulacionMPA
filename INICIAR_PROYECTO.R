# ==============================================================================
# PUNTO DE PARTIDA PARA UN PROYECTO DE TITULACIÓN - titulacionMPA (Motor Typst)
# ==============================================================================

# 1. Cargar los módulos del paquete titulacionMPA
paquete_dir <- if (dir.exists("titulacionMPA")) "titulacionMPA" else "."
for (f in sort(list.files(file.path(paquete_dir, "R"), pattern = "\\.R$", full.names = TRUE))) {
  source(f, encoding = "UTF-8")
}

# 2. Cargar configuración desde la Plantilla Maestra Excel
#    (Para un nuevo sector, copia 'inst/extdata/PLANTILLA_MAESTRA_TITULACION.xlsx')
config <- cargar_config_proyecto(
  excel_path   = "titulacionMPA/inst/extdata/EJEMPLO_PLANTILLA_MAESTRA_PARQUE_DEL_CARMEN.xlsx",
  memoria_path = NULL, # Opcional si los linderos están en las columnas Y-AB del Excel
  output_base  = "resultados_titulacion"
)

# 3. Verificar carga del dataset maestro
df_maestro <- obtener_dataset_proyecto(config, recargar = TRUE)
cat("Sector:", config$meta$NOMBRE_SECTOR, "| Predios cargados:", nrow(df_maestro), "\n")

# ==============================================================================
# EJECUCIÓN DE DOCUMENTOS (formato = "pdf" usa Typst ultrarrápido)
# ==============================================================================

# --- A) Expediente completo (los 5 documentos para un predio) ---
# generar_expediente_completo("A", "1", config = config, formato = "pdf", sobrescribir = TRUE)

# --- B) Generación masiva por tipo de documento ---
# generar_todos_informes_sgpuat(config,  formato = "pdf", solo_numerados = TRUE, sobrescribir = TRUE)
# generar_todos_informes_gdur(config,    formato = "pdf", solo_numerados = TRUE, sobrescribir = TRUE)
# generar_todos_informes_legales(config, formato = "pdf", solo_numerados = TRUE, sobrescribir = TRUE)
# generar_todas_resoluciones(config,     formato = "pdf", solo_numerados = TRUE, sobrescribir = TRUE)
# generar_todos_titulos(config,          formato = "pdf", solo_numerados = TRUE, sobrescribir = TRUE)
