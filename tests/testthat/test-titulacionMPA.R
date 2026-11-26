test_that("cargar_config_proyecto lee la plantilla maestra de ejemplo", {
  excel_ej <- system.file("extdata", "EJEMPLO_PLANTILLA_MAESTRA_PARQUE_DEL_CARMEN.xlsx", package = "titulacionMPA")
  if (!nzchar(excel_ej)) {
    excel_ej <- file.path(localizar_raiz_paquete(), "inst", "extdata", "EJEMPLO_PLANTILLA_MAESTRA_PARQUE_DEL_CARMEN.xlsx")
  }
  expect_true(file.exists(excel_ej))

  cfg <- cargar_config_proyecto(excel_path = excel_ej, output_base = tempdir())
  expect_equal(cfg$meta$NOMBRE_SECTOR, "ADV PARQUE DEL CARMEN")

  df <- obtener_dataset_proyecto(cfg, recargar = TRUE)
  expect_gt(nrow(df), 0L)
  expect_true("beneficiarios" %in% names(df))

  # Verificar soporte N beneficiarios (Mz C Lote 1 tiene 10 titulares)
  c1 <- df[df$mz == "C" & df$lote == "1", ]
  expect_equal(nrow(c1), 1L)
  expect_equal(c1$num_beneficiarios[[1]], 10L)
})

test_that("linderos se cargan desde columnas Y-AB cuando no hay memoria docx", {
  excel_ej <- system.file("extdata", "EJEMPLO_PLANTILLA_MAESTRA_PARQUE_DEL_CARMEN.xlsx", package = "titulacionMPA")
  if (!nzchar(excel_ej)) {
    excel_ej <- file.path(localizar_raiz_paquete(), "inst", "extdata", "EJEMPLO_PLANTILLA_MAESTRA_PARQUE_DEL_CARMEN.xlsx")
  }
  cfg <- cargar_config_proyecto(excel_path = excel_ej, memoria_path = NULL, output_base = tempdir())
  df <- obtener_dataset_proyecto(cfg)
  a1 <- df[df$mz == "A" & df$lote == "1", ]
  expect_match(a1$linderos_frente[[1]], "Palmeras")
})
