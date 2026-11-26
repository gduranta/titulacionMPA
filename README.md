# `titulacionMPA` — Sistema Estandarizado de Formalización y Titulación de Predios

Paquete base reutilizable de la **Municipalidad Provincial de Anta** para la generación ultrarrápida de expedientes completos de titulación (5 documentos por predio) a partir de una **plantilla maestra única en Excel**:

1. **Informe Técnico de Subgerencia (SGPUAT)**
2. **Informe de Gerencia de Desarrollo Urbano y Rural (GDUR)** *(1 página)*
3. **Informe Legal (GAL)** *(con fondo membretado oficial)*
4. **Resolución de Alcaldía** *(márgenes papel membretado: `3.0 cm` sup / `1.5 cm` inf)*
5. **Título de Propiedad** *(márgenes papel membretado: `3.0 cm` sup / `1.5 cm` inf + firmas dinámicas para 1 a $N$ titulares)*

---

## Arquitectura del Paquete

```text
titulacionMPA/
├── DESCRIPTION
├── NAMESPACE
├── README.md
├── INICIAR_PROYECTO.R                        <- Punto de partida ejecutable
├── R/
│   ├── 00_config.R                           <- Lee hoja CONFIGURACION del Excel Maestro
│   ├── 01_extractor_memoria.R                <- Lector opcional de Memoria Descriptiva (.docx)
│   ├── 02_extractor_excel.R                  <- Lector Excel (cols. A–X + linderos Y–AB + N titulares)
│   ├── 03_transformador.R                    <- Cruce relacional, TUPA (Q/R), gramática y caché
│   ├── 04_motor_render.R                     <- Motor Typst (PDF ~0.2s) + Quarto/Python (DOCX)
│   └── 05_generadores.R                      <- API pública estandarizada (individual, lote, expediente)
└── inst/
    ├── extdata/
    │   ├── PLANTILLA_MAESTRA_TITULACION.xlsx                  <- Plantilla limpia para nuevos sectores
    │   └── EJEMPLO_PLANTILLA_MAESTRA_PARQUE_DEL_CARMEN.xlsx   <- Ejemplo completo lleno
    ├── formatos/                             <- Referencias Word (.docx)
    ├── python/
    │   └── postprocesar_docx.py              <- Postprocesador Times New Roman + XML
    ├── templates_typst/                      <- Motor principal PDF (Typst + estilo_comun.typ)
    └── templates/                            <- Plantillas Quarto (.qmd) para exportación DOCX
```

---

## Cómo Iniciar un Nuevo Grupo de Títulos

1. **Copia** `inst/extdata/PLANTILLA_MAESTRA_TITULACION.xlsx` (puedes guiarte con `EJEMPLO_PLANTILLA_MAESTRA_PARQUE_DEL_CARMEN.xlsx`).
2. **Completa la hoja `CONFIGURACION`**: nombre del sector/ADV, partida matriz, resolución de lotización, autoridades y fechas.
3. **Completa la hoja `PREDIOS`**:
   - Columnas **A–X**: datos de lote, titular(es) en filas consecutivas sin repetir MZ/LOTE, estado civil, ítems TUPA Q/R y correlativos.
   - Columnas **Y–AB** *(opcionales)*: linderos completos si no cuentas con Memoria Descriptiva en Word.
4. **Ejecuta `INICIAR_PROYECTO.R`** en R o RStudio.

---

## Referencia Completa de Funciones Exportadas

### Configuración y Datos
| Función | Descripción |
| :--- | :--- |
| `cargar_config_proyecto(excel_path, memoria_path, output_base, overrides)` | Lee la hoja `CONFIGURACION` del Excel Maestro y prepara rutas y plantillas. |
| `construir_dataset_maestro(config, guardar_archivos)` | Cruza Excel y Memoria Descriptiva, evalúa TUPA y concordancias para $N$ beneficiarios. |
| `obtener_dataset_proyecto(config, recargar)` | Obtiene el dataset maestro desde caché y recarga automáticamente si el Excel cambió. |

### Generación Individual y Expediente Completo
| Función | Descripción |
| :--- | :--- |
| `generar_informe_sgpuat(mz_nombre, lote_nombre, config, ...)` | Genera el Informe Técnico SGPUAT de un predio. |
| `generar_informe_gdur(mz_nombre, lote_nombre, config, ...)` | Genera el Informe GDUR (1 página) de un predio. |
| `generar_informe_legal(mz_nombre, lote_nombre, config, ...)` | Genera el Informe Legal GAL de un predio. |
| `generar_resolucion_alcaldia(mz_nombre, lote_nombre, config, ...)` | Genera la Resolución de Alcaldía de un predio. |
| `generar_titulo_propiedad(mz_nombre, lote_nombre, config, ...)` | Genera el Título de Propiedad de un predio (con firmas para 1 a $N$ titulares). |
| `generar_expediente_completo(mz_nombre, lote_nombre, config, ...)` | Genera los 5 documentos completos para un único predio. |

### Generación Masiva (con reporte de avance `[i/N]` y tiempo total)
| Función | Parámetros estándar |
| :--- | :--- |
| `generar_todos_informes_sgpuat(...)` | `config, fecha, formato = c("pdf", "ambos", "docx"), output_dir, solo_numerados = TRUE, mz_nombre = NULL, sobrescribir = FALSE` |
| `generar_todos_informes_gdur(...)` | Mismos argumentos estandarizados |
| `generar_todos_informes_legales(...)` | Mismos argumentos estandarizados |
| `generar_todas_resoluciones(...)` | Mismos argumentos estandarizados |
| `generar_todos_titulos(...)` | Mismos argumentos estandarizados + `fecha_emision`, `fecha_resolucion` |
