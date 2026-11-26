# Aplicación Shiny interactiva: Tablero de Ingreso de Datos + Editor de Plantillas Typst
# Se ejecuta mediante titulacionMPA::lanzar_editor_mpa(config)

options(shiny.maxRequestSize = 50 * 1024^2)

config <- shiny::getShinyOption("mpa_config", getOption("titulacionMPA.shiny_config", NULL))
if (is.null(config)) {
  config <- titulacionMPA::cargar_config_proyecto()
}

pkg_ns <- asNamespace("titulacionMPA")
typst_bin <- pkg_ns$buscar_typst_mpa()
diccionario_excel <- pkg_ns$obtener_diccionario_campos_excel()

doc_choices <- c(
  "Informe Técnico SGPUAT" = "sgpuat",
  "Informe Técnico GDUR"   = "gdur",
  "Opinión Legal (OAJ)"    = "legal",
  "Resolución de Alcaldía" = "resolucion",
  "Título de Propiedad"    = "titulo"
)

obtener_dir_plantillas_typst <- function(config) {
  if (!is.null(config$templates_typst) && length(config$templates_typst) > 0L) {
    d <- dirname(config$templates_typst[[1L]])
    if (dir.exists(d)) return(d)
  }
  d_pkg <- system.file("templates_typst", package = "titulacionMPA")
  if (nzchar(d_pkg) && dir.exists(d_pkg)) return(d_pkg)
  file.path("titulacionMPA", "inst", "templates_typst")
}

plantilla_archivo <- function(doc_tipo) {
  switch(
    doc_tipo,
    sgpuat     = "plantilla_sgpuat.typ",
    gdur       = "plantilla_gdur.typ",
    legal      = "plantilla_legal.typ",
    resolucion = "plantilla_resolucion.typ",
    titulo     = "plantilla_titulo.typ"
  )
}

escape_html_mpa <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x
}

escape_typst_str_mpa <- function(x) {
  x <- gsub("\\", "\\\\", x, fixed = TRUE)
  x <- gsub("\"", "\\\"", x, fixed = TRUE)
  x
}

construir_reglas_resaltado_typst <- function(payload) {
  vals <- character()
  for (nm in names(payload)) {
    v <- payload[[nm]]
    if (is.character(v) && length(v) == 1L) {
      v <- trimws(v)
      if (nzchar(v) && nchar(v) >= 4L && !grepl("\n", v, fixed = TRUE)) {
        vals <- c(vals, v)
      }
    }
  }
  vals <- unique(vals)
  if (length(vals) == 0L) return("")
  # Ordenar de más largo a más corto para evitar coincidencias parciales previas
  vals <- vals[order(nchar(vals), decreasing = TRUE)]
  reglas <- vapply(vals, function(v) {
    sprintf('#show "%s": it => highlight(fill: rgb("#FFF3CD"), extent: 1pt, it)', escape_typst_str_mpa(v))
  }, character(1L))
  paste(reglas, collapse = "\n")
}

resaltar_plantilla_html <- function(texto_typ, payload) {
  if (is.null(texto_typ) || !nzchar(texto_typ)) return("")
  html_txt <- escape_html_mpa(texto_typ)

  # Reemplazar tokens #data.<campo> o data.<campo> con badge amarillo + tooltip de valor actual
  m <- gregexpr("(#?data\\.[A-Za-z0-9_]+)", html_txt, perl = TRUE)
  matches <- regmatches(html_txt, m)[[1L]]
  if (length(matches) > 0L) {
    repls <- vapply(matches, function(tok) {
      campo <- sub("^#?data\\.", "", tok)
      val_actual <- ""
      if (!is.null(payload) && !is.null(payload[[campo]])) {
        val_actual <- as.character(payload[[campo]])[1L]
      }
      meta <- diccionario_excel[diccionario_excel$variable == paste0("data.", campo), , drop = FALSE]
      origen <- if (nrow(meta) > 0L) paste0(meta$etiqueta[1L], " | ", meta$origen[1L]) else "Campo del Excel maestro"
      titulo_tip <- escape_html_mpa(paste0(origen, "\nValor actual: ", val_actual, "\nNO modificar este marcador arbitrariamente."))
      sprintf(
        '<span class="excel-token" title="%s">%s</span>',
        titulo_tip,
        tok
      )
    }, character(1L))
    regmatches(html_txt, m) <- list(repls)
  }

  paste0('<pre class="typst-highlight-code">', html_txt, '</pre>')
}

renderizar_preview_typst <- function(doc_tipo, item, config, fecha_doc, plantilla_texto = NULL,
                                     resaltar_excel = FALSE, tmp_dir, prefix = "prev") {
  tpl_dir <- obtener_dir_plantillas_typst(config)
  tpl_name <- plantilla_archivo(doc_tipo)
  tpl_src <- file.path(tpl_dir, tpl_name)

  # Copiar estilo_comun.typ, imágenes/fondos de templates_typst y logo al directorio temporal
  estilo_src <- file.path(tpl_dir, "estilo_comun.typ")
  if (file.exists(estilo_src)) {
    file.copy(estilo_src, file.path(tmp_dir, "estilo_comun.typ"), overwrite = TRUE)
  }
  activos <- list.files(tpl_dir, pattern = "\\.(png|jpg|jpeg|svg|gif|webp|ttf|otf)$", ignore.case = TRUE, full.names = TRUE)
  if (length(activos) > 0L) {
    file.copy(activos, file.path(tmp_dir, basename(activos)), overwrite = TRUE)
  }
  if (!is.null(config$logo_path) && file.exists(config$logo_path)) {
    file.copy(config$logo_path, file.path(tmp_dir, "logo_muni.png"), overwrite = TRUE)
    if (!file.exists(file.path(tmp_dir, "mpa.png"))) {
      file.copy(config$logo_path, file.path(tmp_dir, "mpa.png"), overwrite = TRUE)
    }
  }

  txt_tpl <- if (!is.null(plantilla_texto)) plantilla_texto else paste(readLines(tpl_src, encoding = "UTF-8", warn = FALSE), collapse = "\n")

  payload <- pkg_ns$construir_payload_typst_mpa(item, config, fecha_doc)

  if (isTRUE(resaltar_excel)) {
    reglas <- construir_reglas_resaltado_typst(payload)
    if (nzchar(reglas)) {
      # Insertar las reglas #show en modo markup justo después de #import
      if (grepl('#import\\s+"[^"]+"\\s*:[^\n]*', txt_tpl)) {
        txt_tpl <- sub(
          '(#import\\s+"[^"]+"\\s*:[^\n]*)',
          paste0("\\1\n", reglas),
          txt_tpl
        )
      } else {
        txt_tpl <- paste0(reglas, "\n", txt_tpl)
      }
    }
  }

  typ_tmp <- file.path(tmp_dir, paste0(prefix, "_", doc_tipo, ".typ"))
  json_tmp <- file.path(tmp_dir, paste0(prefix, "_", doc_tipo, ".json"))
  pdf_name <- paste0(prefix, "_", doc_tipo, "_", format(Sys.time(), "%H%M%S"), ".pdf")
  pdf_tmp <- file.path(tmp_dir, pdf_name)

  # Limpiar PDFs anteriores del mismo prefijo para no acumular archivos
  viejos <- list.files(tmp_dir, pattern = paste0("^", prefix, "_.*\\.pdf$"), full.names = TRUE)
  if (length(viejos) > 0L) unlink(viejos)

  writeLines(enc2utf8(txt_tpl), typ_tmp, useBytes = TRUE)
  pkg_ns$escribir_json_mpa(payload, json_tmp)

  res <- system2(
    typst_bin,
    args = c("compile", shQuote(typ_tmp), shQuote(pdf_tmp), "--input", paste0("json_file=", basename(json_tmp))),
    stdout = TRUE,
    stderr = TRUE
  )
  status <- attr(res, "status")
  list(
    ok = is.null(status) || status == 0L,
    pdf_name = pdf_name,
    log = paste(res, collapse = "\n"),
    payload = payload
  )
}

ui <- bslib::page_navbar(
  title = paste("titulacionMPA —", config$asentamiento),
  theme = bslib::bs_theme(version = 5, bootswatch = "flatly"),
  header = shiny::tags$head(
    shiny::tags$style(shiny::HTML("
      .excel-token {
        background-color: #fff3cd;
        border: 1px solid #f0ad4e;
        color: #664d03;
        font-weight: 700;
        padding: 1px 4px;
        border-radius: 4px;
        cursor: help;
      }
      .typst-highlight-code {
        background-color: #f8f9fa;
        border: 1px solid #dee2e6;
        border-radius: 6px;
        padding: 12px;
        font-family: Consolas, 'Courier New', monospace;
        font-size: 12px;
        line-height: 1.45;
        max-height: 360px;
        overflow-y: auto;
        white-space: pre-wrap;
        word-break: break-word;
      }
      .ben-card {
        background: #f8f9fa;
        border: 1px solid #dee2e6;
        border-radius: 6px;
        padding: 8px 10px;
        margin-bottom: 8px;
      }
      .shiny-input-container {
        width: 100% !important;
      }
      .panel-izq-scroll {
        height: calc(100vh - 82px);
        overflow-y: auto;
        padding-right: 6px;
      }
      .panel-der-preview {
        height: calc(100vh - 82px);
        display: flex;
        flex-direction: column;
      }
      .panel-der-preview .card-body {
        display: flex;
        flex-direction: column;
        flex: 1 1 auto;
        min-height: 0;
        overflow: hidden;
      }
      .visor-pdf-wrap {
        flex: 1 1 auto;
        min-height: 360px;
        display: flex;
        flex-direction: column;
      }
      .visor-pdf-wrap iframe {
        flex: 1 1 auto;
        width: 100%;
        height: 100% !important;
        min-height: 360px;
        border: 1px solid #dee2e6;
        border-radius: 6px;
      }
      @media (max-width: 991.98px) {
        .panel-izq-scroll, .panel-der-preview {
          height: auto;
          overflow-y: visible;
        }
        .visor-pdf-wrap iframe {
          height: 600px !important;
        }
      }
    "))
  ),

  # ============================================================================
  # PESTAÑA 1: TABLERO DE INGRESO DE DATOS Y GENERACIÓN DE DOCUMENTOS
  # ============================================================================
  bslib::nav_panel(
    title = "Tablero de Ingreso y Generación",
    icon = shiny::icon("table-columns"),

    bslib::layout_columns(
      col_widths = c(6, 6),

      # Columna Izquierda (50%): Carga, Filtro Mz/Lote, Formulario con Scroll
      shiny::div(
        class = "panel-izq-scroll",

        bslib::card(
          class = "mb-2",
          bslib::card_header("Carga de Excel Maestro y Filtro de Predios"),
          bslib::layout_columns(
            col_widths = c(7, 5),
            shiny::div(
              shiny::fileInput(
                "archivo_excel_upload",
                "1. Cargar Excel Maestro (.xlsx)",
                accept = c(".xlsx"),
                buttonLabel = "Subir .xlsx",
                placeholder = "Usando archivo del servidor",
                width = "100%"
              ),
              shiny::div(
                class = "small text-muted",
                style = "margin-top: -10px;",
                shiny::textOutput("lbl_excel_actual", inline = TRUE)
              )
            ),
            shiny::div(
              style = "margin-top: 30px;",
              bslib::layout_columns(
                col_widths = c(6, 6),
                shiny::actionButton("btn_nuevo_predio", "Nuevo", icon = shiny::icon("plus"), class = "btn-outline-secondary w-100"),
                shiny::downloadButton("btn_descargar_excel", "Excel", class = "btn-outline-success w-100")
              )
            )
          ),
          shiny::hr(class = "my-2"),
          bslib::layout_columns(
            col_widths = c(4, 4, 4),
            shiny::textInput("filtro_mz", "Filtrar Manzana (MZ)", "", placeholder = "Ej: A, B, C"),
            shiny::textInput("filtro_lote", "Filtrar Lote", "", placeholder = "Ej: 1, 12"),
            shiny::div(
              style = "margin-top: 31px;",
              shiny::actionButton("btn_limpiar_filtro", "Limpiar filtro", icon = shiny::icon("eraser"), class = "btn-outline-secondary w-100")
            )
          ),
          shiny::selectizeInput(
            "dash_cargar_lote",
            "2. Seleccionar Predio (Mz - Lote - Posesionario)",
            choices = c("-- Nuevo Predio --" = "__NUEVO__"),
            options = list(placeholder = "Escriba Mz, Lote o nombre..."),
            width = "100%"
          )
        ),

        bslib::navset_card_tab(
          id = "tabs_formulario",
          bslib::nav_panel(
            title = "Predio y Evaluación",
            icon = shiny::icon("house"),
            bslib::layout_columns(
              col_widths = c(3, 3, 6),
              shiny::textInput("f_mz", "Manzana (MZ) *", ""),
              shiny::textInput("f_lote", "Lote *", ""),
              shiny::textInput("f_anio_posesion", "Año de Posesión", "2020")
            ),
            shiny::textInput("f_evaluacion", "Evaluación / Observación", "TITULABLE", width = "100%"),
            bslib::layout_columns(
              col_widths = c(6, 6),
              shiny::textInput("f_area", "Área (m2) *", ""),
              shiny::textInput("f_perimetro", "Perímetro (ml) *", "")
            ),
            bslib::layout_columns(
              col_widths = c(6, 6),
              shiny::textInput("f_partida", "Partida Matriz", ""),
              shiny::textInput("f_constancia", "N.° Constancia Posesión", "")
            ),
            bslib::layout_columns(
              col_widths = c(4, 4, 4),
              shiny::textInput("f_exp_constancia", "Exp. Constancia", ""),
              shiny::textInput("f_exp_titulo", "Exp. Título", ""),
              shiny::textInput("f_fecha_solicitud", "Fecha Solicitud", "")
            )
          ),

          bslib::nav_panel(
            title = "Posesionarios",
            icon = shiny::icon("users"),
            shiny::div(
              class = "d-flex justify-content-between align-items-center mb-2",
              shiny::span(class = "text-muted small", "Agregue uno o más posesionarios/titulares para este lote."),
              shiny::div(
                shiny::actionButton("btn_add_ben", "+ Agregar Posesionario", class = "btn-sm btn-outline-primary me-1"),
                shiny::actionButton("btn_del_ben", "- Quitar Último", class = "btn-sm btn-outline-danger")
              )
            ),
            shiny::div(
              style = "max-height: 520px; overflow-y: auto;",
              shiny::uiOutput("ui_beneficiarios")
            )
          ),

          bslib::nav_panel(
            title = "Linderos",
            icon = shiny::icon("compass"),
            shiny::textInput("f_lindero_frente", "Por el Frente", "", width = "100%"),
            shiny::textInput("f_lindero_fondo", "Por el Fondo", "", width = "100%"),
            shiny::textInput("f_lindero_derecha", "Por la Derecha", "", width = "100%"),
            shiny::textInput("f_lindero_izquierda", "Por la Izquierda", "", width = "100%")
          ),

          bslib::nav_panel(
            title = "Correlativos y TUPA",
            icon = shiny::icon("list-ol"),
            bslib::layout_columns(
              col_widths = c(4, 4, 4),
              shiny::textInput("f_inf_sgpuat", "Inf. SGPUAT", ""),
              shiny::textInput("f_inf_gdur", "Inf. GDUR", ""),
              shiny::textInput("f_inf_legal", "Inf. Legal", "")
            ),
            bslib::layout_columns(
              col_widths = c(4, 4, 4),
              shiny::textInput("f_proveido", "Proveído", ""),
              shiny::textInput("f_resolucion", "Resolución", ""),
              shiny::textInput("f_titulo", "Título N.°", "")
            ),
            bslib::layout_columns(
              col_widths = c(6, 6),
              shiny::textInput("f_matrimonio", "TUPA Matrimonio (Col Q)", ""),
              shiny::textInput("f_convivencia", "TUPA Convivencia (Col R)", "")
            )
          )
        ),

        shiny::actionButton(
          "btn_guardar_excel",
          "Guardar en Excel Maestro y Generar Vista Previa",
          icon = shiny::icon("floppy-disk"),
          class = "btn-success btn-lg w-100 mt-2"
        )
      ),

      # Columna Derecha (50%): Selector de Documento + Vista Previa PDF + Exportación
      bslib::card(
        class = "panel-der-preview",
        bslib::card_header("Vista Previa y Generación de Documentos (Typst)"),
        bslib::layout_columns(
          col_widths = c(5, 4, 3),
          shiny::selectInput("dash_doc", "Documento", choices = doc_choices, selected = "resolucion"),
          shiny::textInput("dash_fecha", "Fecha del documento", value = format(Sys.Date(), "%d de %B del %Y")),
          shiny::div(
            style = "margin-top: 31px;",
            shiny::actionButton("btn_dash_refrescar", "Actualizar Vista", class = "btn-outline-primary w-100")
          )
        ),
        bslib::layout_columns(
          col_widths = c(6, 6),
          shiny::actionButton("btn_dash_export_uno", "Exportar Documento Actual (PDF)", icon = shiny::icon("file-pdf"), class = "btn-primary w-100"),
          shiny::actionButton("btn_dash_export_todos", "Generar los 5 Documentos (PDF)", icon = shiny::icon("layer-group"), class = "btn-warning w-100")
        ),
        shiny::hr(class = "my-2"),
        shiny::div(
          class = "visor-pdf-wrap",
          shiny::uiOutput("dash_visor_pdf", style = "flex: 1 1 auto; display: flex; flex-direction: column;")
        ),
        shiny::div(class = "mt-2", shiny::verbatimTextOutput("dash_estado"))
      )
    )
  ),

  # ============================================================================
  # PESTAÑA 2: EDITOR DE PLANTILLAS TYPST (CON RESALTADO DE CAMPOS DEL EXCEL)
  # ============================================================================
  bslib::nav_panel(
    title = "Editor de Plantillas (Campos Resaltados)",
    icon = shiny::icon("file-code"),
    bslib::layout_sidebar(
      sidebar = bslib::sidebar(
        width = 300,
        shiny::selectInput("doc_tipo", "Plantilla Typst", choices = doc_choices, selected = "resolucion"),
        shiny::selectInput("lote_id", "Predio de prueba (Mz - Lote)", choices = character()),
        shiny::textInput("fecha_doc", "Fecha del documento", value = format(Sys.Date(), "%d de %B del %Y")),
        shiny::checkboxInput("chk_resaltar_pdf", "Resaltar datos del Excel en PDF (vista previa)", value = TRUE),
        shiny::hr(),
        shiny::actionButton("btn_preview", "Actualizar Vista Previa", class = "btn-primary w-100 mb-2"),
        shiny::actionButton("btn_guardar", "Guardar Cambios en Plantilla", class = "btn-warning w-100 mb-2"),
        shiny::actionButton("btn_exportar", "Exportar PDF a Resultados", class = "btn-success w-100 mb-2"),
        shiny::hr(),
        shiny::helpText(
          "Los bloques resaltados en amarillo (#data.*) provienen directamente del Excel maestro. ",
          "Edite libremente la redacción legal/técnica alrededor de ellos, sin alterar los nombres de las variables."
        ),
        shiny::verbatimTextOutput("estado_compilacion")
      ),

      bslib::layout_columns(
        col_widths = c(6, 6),
        bslib::navset_card_tab(
          title = "Plantilla Typst (.typ)",
          bslib::nav_panel(
            title = "Vista con Campos Protegidos Resaltados",
            shiny::p(
              class = "text-muted small mb-2",
              "Pase el cursor sobre cualquier marcador amarillo (#data.*) para ver su columna en el Excel y su valor actual para el lote seleccionado."
            ),
            shiny::uiOutput("plantilla_resaltada"),
            shiny::hr(class = "my-2"),
            shiny::strong("Campos del Excel usados en esta plantilla:"),
            shiny::uiOutput("panel_campos_excel")
          ),
          bslib::nav_panel(
            title = "Editar Texto de la Plantilla",
            shiny::textAreaInput(
              "txt_plantilla",
              label = NULL,
              value = "",
              width = "100%",
              height = "620px"
            )
          )
        ),
        bslib::card(
          bslib::card_header("Vista Previa PDF (Typst en vivo)"),
          shiny::uiOutput("visor_pdf")
        )
      )
    )
  )
)

preview_root <- tempfile("titulacion_shiny_root_")
dir.create(preview_root, recursive = TRUE, showWarnings = FALSE)
shiny::addResourcePath("preview_pdf", preview_root)

server <- function(input, output, session) {
  session_id <- if (!is.null(session$token) && nzchar(session$token)) session$token else basename(tempfile("s_"))
  tmp_dir <- file.path(preview_root, session_id)
  dir.create(tmp_dir, recursive = TRUE, showWarnings = FALSE)
  session$onSessionEnded(function() {
    unlink(tmp_dir, recursive = TRUE)
  })

  rv <- shiny::reactiveValues(
    config = config,
    df = titulacionMPA::obtener_dataset_proyecto(config),
    pdf_url = NULL,
    dash_pdf_url = NULL,
    payload_editor = NULL,
    beneficiarios = list(
      list(nombre = "", dni = "", genero = "f", solicitante = TRUE, estado_civil = "soltero")
    )
  )

  output$lbl_excel_actual <- shiny::renderText({
    paste0("Archivo activo: ", basename(rv$config$excel_path), " (", nrow(rv$df), " predios)")
  })

  shiny::observeEvent(input$archivo_excel_upload, {
    req(input$archivo_excel_upload$datapath)
    tryCatch({
      dest_xlsx <- file.path(tmp_dir, paste0("maestro_", format(Sys.time(), "%Y%m%d_%H%M%S"), "_", basename(input$archivo_excel_upload$name)))
      file.copy(input$archivo_excel_upload$datapath, dest_xlsx, overwrite = TRUE)
      nuevo_cfg <- titulacionMPA::cargar_config_proyecto(excel_path = dest_xlsx, output_base = rv$config$output_dir)
      rv$config <- nuevo_cfg
      rv$df <- titulacionMPA::obtener_dataset_proyecto(nuevo_cfg, recargar = TRUE)
      rv$dash_pdf_url <- NULL
      rv$pdf_url <- NULL
      limpiar_formulario()
      shiny::showNotification(
        paste0("Excel cargado: ", basename(input$archivo_excel_upload$name), " (", nrow(rv$df), " predios)"),
        type = "message"
      )
    }, error = function(e) {
      shiny::showNotification(paste("Error al cargar el Excel:", conditionMessage(e)), type = "error")
    })
  })

  output$btn_descargar_excel <- shiny::downloadHandler(
    filename = function() {
      basename(rv$config$excel_path)
    },
    content = function(file) {
      file.copy(rv$config$excel_path, file, overwrite = TRUE)
    }
  )

  # Sincronizar selectores de lotes cuando cambia rv$df o los filtros de Mz/Lote
  shiny::observe({
    df <- rv$df
    ids <- paste0(toupper(df$mz), "_", df$lote)
    etiquetas <- paste0("Mz. ", df$mz, " - Lt. ", df$lote, ifelse(nzchar(df$t1_nombre), paste0(" | ", df$t1_nombre), ""))
    choices_editor <- stats::setNames(ids, etiquetas)
    shiny::updateSelectInput(session, "lote_id", choices = choices_editor, selected = if (length(choices_editor) > 0L) choices_editor[[1L]] else NULL)
  })

  shiny::observe({
    df <- rv$df
    mz_q <- toupper(trimws(if (is.null(input$filtro_mz)) "" else input$filtro_mz))
    lt_q <- toupper(trimws(if (is.null(input$filtro_lote)) "" else input$filtro_lote))

    df_filt <- df
    if (nzchar(mz_q)) {
      df_filt <- df_filt[toupper(trimws(as.character(df_filt$mz))) == mz_q |
                           grepl(mz_q, toupper(trimws(as.character(df_filt$mz))), fixed = TRUE), , drop = FALSE]
    }
    if (nzchar(lt_q)) {
      df_filt <- df_filt[toupper(trimws(as.character(df_filt$lote))) == lt_q, , drop = FALSE]
    }

    ids_filt <- paste0(toupper(df_filt$mz), "_", df_filt$lote)
    etiq_filt <- paste0("Mz. ", df_filt$mz, " - Lt. ", df_filt$lote, ifelse(nzchar(df_filt$t1_nombre), paste0(" | ", df_filt$t1_nombre), ""))
    choices_dash <- c("-- Nuevo Predio --" = "__NUEVO__", stats::setNames(ids_filt, etiq_filt))

    selected_val <- NULL
    if (nzchar(mz_q) && nzchar(lt_q) && nrow(df_filt) > 0L) {
      exact_idx <- which(toupper(trimws(as.character(df_filt$mz))) == mz_q &
                         toupper(trimws(as.character(df_filt$lote))) == lt_q)
      if (length(exact_idx) > 0L) {
        selected_val <- ids_filt[exact_idx[1L]]
      } else {
        selected_val <- ids_filt[1L]
      }
    }

    shiny::updateSelectizeInput(
      session,
      "dash_cargar_lote",
      choices = choices_dash,
      selected = selected_val,
      server = FALSE
    )
  })

  shiny::observeEvent(input$btn_limpiar_filtro, {
    shiny::updateTextInput(session, "filtro_mz", value = "")
    shiny::updateTextInput(session, "filtro_lote", value = "")
  })

  # ============================================================================
  # LÓGICA DEL TABLERO DE INGRESO DE DATOS
  # ============================================================================
  limpiar_formulario <- function() {
    shiny::updateTextInput(session, "f_mz", value = "")
    shiny::updateTextInput(session, "f_lote", value = "")
    shiny::updateTextInput(session, "f_evaluacion", value = "TITULABLE")
    shiny::updateTextInput(session, "f_area", value = "")
    shiny::updateTextInput(session, "f_perimetro", value = "")
    shiny::updateTextInput(session, "f_anio_posesion", value = "2020")
    shiny::updateTextInput(session, "f_partida", value = "")
    shiny::updateTextInput(session, "f_constancia", value = "")
    shiny::updateTextInput(session, "f_exp_constancia", value = "")
    shiny::updateTextInput(session, "f_exp_titulo", value = "")
    shiny::updateTextInput(session, "f_fecha_solicitud", value = "")
    shiny::updateTextInput(session, "f_lindero_frente", value = "")
    shiny::updateTextInput(session, "f_lindero_fondo", value = "")
    shiny::updateTextInput(session, "f_lindero_derecha", value = "")
    shiny::updateTextInput(session, "f_lindero_izquierda", value = "")
    shiny::updateTextInput(session, "f_inf_sgpuat", value = "")
    shiny::updateTextInput(session, "f_inf_gdur", value = "")
    shiny::updateTextInput(session, "f_inf_legal", value = "")
    shiny::updateTextInput(session, "f_proveido", value = "")
    shiny::updateTextInput(session, "f_resolucion", value = "")
    shiny::updateTextInput(session, "f_titulo", value = "")
    shiny::updateTextInput(session, "f_matrimonio", value = "")
    shiny::updateTextInput(session, "f_convivencia", value = "")
    rv$beneficiarios <- list(
      list(nombre = "", dni = "", genero = "f", solicitante = TRUE, estado_civil = "soltero")
    )
  }

  shiny::observeEvent(input$btn_nuevo_predio, {
    shiny::updateSelectInput(session, "dash_cargar_lote", selected = "__NUEVO__")
    limpiar_formulario()
  })

  shiny::observeEvent(input$dash_cargar_lote, {
    req(input$dash_cargar_lote)
    if (identical(input$dash_cargar_lote, "__NUEVO__")) return()

    ids <- paste0(toupper(rv$df$mz), "_", rv$df$lote)
    fila <- rv$df[ids == input$dash_cargar_lote, , drop = FALSE]
    if (nrow(fila) == 0L) return()
    item <- fila[1L, ]

    val_str <- function(...) {
      for (col in c(...)) {
        if (col %in% names(item)) {
          v <- item[[col]]
          if (!is.null(v) && !is.na(v) && nzchar(as.character(v))) return(as.character(v))
        }
      }
      ""
    }

    shiny::updateTextInput(session, "f_mz", value = val_str("mz"))
    shiny::updateTextInput(session, "f_lote", value = val_str("lote"))
    shiny::updateTextInput(session, "f_evaluacion", value = val_str("evaluacion_excel"))
    shiny::updateTextInput(session, "f_area", value = val_str("area_excel", "area_final", "area"))
    shiny::updateTextInput(session, "f_perimetro", value = val_str("perimetro_excel", "perimetro_final", "perimetro"))
    shiny::updateTextInput(session, "f_anio_posesion", value = val_str("anio_posesion"))
    shiny::updateTextInput(session, "f_partida", value = val_str("partida"))
    shiny::updateTextInput(session, "f_constancia", value = val_str("num_constancia"))
    shiny::updateTextInput(session, "f_exp_constancia", value = val_str("exp_constancia"))
    shiny::updateTextInput(session, "f_exp_titulo", value = val_str("exp_titulo"))
    shiny::updateTextInput(session, "f_fecha_solicitud", value = val_str("fecha_solicitud"))
    shiny::updateTextInput(session, "f_lindero_frente", value = val_str("linderos_frente"))
    shiny::updateTextInput(session, "f_lindero_fondo", value = val_str("linderos_fondo"))
    shiny::updateTextInput(session, "f_lindero_derecha", value = val_str("linderos_derecha"))
    shiny::updateTextInput(session, "f_lindero_izquierda", value = val_str("linderos_izquierda"))
    shiny::updateTextInput(session, "f_inf_sgpuat", value = val_str("num_informe_sgpuat"))
    shiny::updateTextInput(session, "f_inf_gdur", value = val_str("num_informe_gdur"))
    shiny::updateTextInput(session, "f_inf_legal", value = val_str("num_informe_legal"))
    shiny::updateTextInput(session, "f_proveido", value = val_str("num_proveido_sg"))
    shiny::updateTextInput(session, "f_resolucion", value = val_str("num_resolucion_sg"))
    shiny::updateTextInput(session, "f_titulo", value = val_str("num_titulo_propiedad"))
    shiny::updateTextInput(session, "f_matrimonio", value = val_str("acta_matrimonio"))
    shiny::updateTextInput(session, "f_convivencia", value = val_str("acta_convivencia"))

    # Extraer posesionarios desde item$beneficiarios
    if ("beneficiarios" %in% names(item) && is.data.frame(item$beneficiarios[[1L]]) && nrow(item$beneficiarios[[1L]]) > 0L) {
      raw_df <- item$beneficiarios[[1L]]
      rv$beneficiarios <- lapply(seq_len(nrow(raw_df)), function(i) {
        sol_val <- if ("solicitante" %in% names(raw_df)) tolower(trimws(as.character(raw_df$solicitante[i]))) else ""
        list(
          nombre = as.character(raw_df$nombre[i] %||% ""),
          dni = as.character(raw_df$dni[i] %||% ""),
          genero = tolower(as.character(raw_df$genero[i] %||% "f")),
          solicitante = identical(sol_val, "x") || isTRUE(raw_df$solicitante[i]),
          estado_civil = tolower(as.character(raw_df$estado_civil[i] %||% "soltero"))
        )
      })
    } else {
      rv$beneficiarios <- list(
        list(nombre = val_str("t1_nombre"), dni = val_str("t1_dni"), genero = tolower(val_str("t1_genero")), solicitante = TRUE, estado_civil = tolower(val_str("estado_civil")))
      )
    }

    compilar_dash_preview(item)
  })

  # Leer inputs actuales de beneficiarios antes de agregar/quitar/guardar
  capturar_beneficiarios_inputs <- function() {
    n <- length(rv$beneficiarios)
    lapply(seq_len(n), function(i) {
      list(
        nombre = input[[paste0("ben_nombre_", i)]] %||% rv$beneficiarios[[i]]$nombre,
        dni = input[[paste0("ben_dni_", i)]] %||% rv$beneficiarios[[i]]$dni,
        genero = input[[paste0("ben_genero_", i)]] %||% rv$beneficiarios[[i]]$genero,
        solicitante = isTRUE(input[[paste0("ben_sol_", i)]]),
        estado_civil = input[[paste0("ben_ec_", i)]] %||% rv$beneficiarios[[i]]$estado_civil
      )
    })
  }

  shiny::observeEvent(input$btn_add_ben, {
    cur <- capturar_beneficiarios_inputs()
    cur[[length(cur) + 1L]] <- list(nombre = "", dni = "", genero = "m", solicitante = FALSE, estado_civil = "soltero")
    rv$beneficiarios <- cur
  })

  shiny::observeEvent(input$btn_del_ben, {
    cur <- capturar_beneficiarios_inputs()
    if (length(cur) > 1L) {
      rv$beneficiarios <- cur[-length(cur)]
    }
  })

  output$ui_beneficiarios <- shiny::renderUI({
    bens <- rv$beneficiarios
    shiny::tagList(lapply(seq_along(bens), function(i) {
      b <- bens[[i]]
      shiny::div(
        class = "ben-card",
        shiny::strong(paste0("Posesionario #", i)),
        bslib::layout_columns(
          col_widths = c(7, 5),
          shiny::textInput(paste0("ben_nombre_", i), "Apellidos y Nombres", value = b$nombre),
          shiny::textInput(paste0("ben_dni_", i), "DNI", value = b$dni)
        ),
        bslib::layout_columns(
          col_widths = c(4, 4, 4),
          shiny::selectInput(paste0("ben_genero_", i), "Género", choices = c("Femenino (f)" = "f", "Masculino (m)" = "m"), selected = b$genero),
          shiny::selectInput(paste0("ben_ec_", i), "Estado Civil", choices = c("soltero", "casado", "conviviente", "viudo", "divorciado"), selected = b$estado_civil),
          shiny::div(
            style = "margin-top: 30px;",
            shiny::checkboxInput(paste0("ben_sol_", i), "Solicitante (x)", value = isTRUE(b$solicitante))
          )
        )
      )
    }))
  })

  compilar_dash_preview <- function(item) {
    res <- renderizar_preview_typst(
      doc_tipo = input$dash_doc,
      item = item,
      config = rv$config,
      fecha_doc = input$dash_fecha,
      plantilla_texto = NULL,
      resaltar_excel = FALSE,
      tmp_dir = tmp_dir,
      prefix = "dash"
    )
    if (res$ok && file.exists(file.path(tmp_dir, res$pdf_name))) {
      rv$dash_pdf_url <- paste0("preview_pdf/", session_id, "/", res$pdf_name)
      output$dash_estado <- shiny::renderText(paste0("Vista previa lista: Mz. ", item$mz, " Lote ", item$lote, " (", input$dash_doc, ")."))
    } else {
      output$dash_estado <- shiny::renderText(paste("Error de compilación Typst:\n", res$log))
    }
  }

  shiny::observeEvent(input$btn_guardar_excel, {
    mz_val <- trimws(input$f_mz)
    lote_val <- trimws(input$f_lote)
    bens <- capturar_beneficiarios_inputs()
    rv$beneficiarios <- bens

    if (!nzchar(mz_val) || !nzchar(lote_val)) {
      shiny::showNotification("Manzana (MZ) y Lote son obligatorios.", type = "error")
      return()
    }
    if (!nzchar(trimws(bens[[1L]]$nombre))) {
      shiny::showNotification("Ingrese al menos el nombre del primer posesionario.", type = "error")
      return()
    }

    payload_excel <- list(
      mz = mz_val,
      lote = lote_val,
      evaluacion = input$f_evaluacion,
      area = input$f_area,
      perimetro = input$f_perimetro,
      anio_posesion = input$f_anio_posesion,
      partida = input$f_partida,
      constancia = input$f_constancia,
      exp_constancia = input$f_exp_constancia,
      exp_titulo = input$f_exp_titulo,
      fecha_solicitud = input$f_fecha_solicitud,
      lindero_frente = input$f_lindero_frente,
      lindero_fondo = input$f_lindero_fondo,
      lindero_derecha = input$f_lindero_derecha,
      lindero_izquierda = input$f_lindero_izquierda,
      inf_sgpuat = input$f_inf_sgpuat,
      inf_gdur = input$f_inf_gdur,
      inf_legal = input$f_inf_legal,
      proveido = input$f_proveido,
      resolucion = input$f_resolucion,
      titulo = input$f_titulo,
      matrimonio = input$f_matrimonio,
      convivencia = input$f_convivencia,
      beneficiarios = lapply(bens, function(b) {
        list(
          nombre = trimws(b$nombre),
          dni = trimws(b$dni),
          genero = b$genero,
          solicitante = if (isTRUE(b$solicitante)) "x" else "",
          estado_civil = b$estado_civil
        )
      })
    )

    tryCatch({
      res_crud <- titulacionMPA::guardar_predio_excel(rv$config, payload_excel)
      rv$df <- titulacionMPA::obtener_dataset_proyecto(rv$config, recargar = TRUE)
      id_target <- paste0(toupper(mz_val), "_", lote_val)
      ids <- paste0(toupper(rv$df$mz), "_", rv$df$lote)
      fila <- rv$df[ids == id_target, , drop = FALSE]
      if (nrow(fila) > 0L) {
        shiny::updateSelectInput(session, "dash_cargar_lote", selected = id_target)
        compilar_dash_preview(fila[1L, ])
      }
      shiny::showNotification(
        paste0("Excel actualizado (", res_crud$action, "): Mz. ", mz_val, " Lt. ", lote_val),
        type = "message"
      )
    }, error = function(e) {
      shiny::showNotification(paste("Error al guardar en Excel:", conditionMessage(e)), type = "error")
    })
  })

  shiny::observeEvent(list(input$dash_doc, input$btn_dash_refrescar), {
    req(input$dash_cargar_lote)
    if (identical(input$dash_cargar_lote, "__NUEVO__")) return()
    ids <- paste0(toupper(rv$df$mz), "_", rv$df$lote)
    fila <- rv$df[ids == input$dash_cargar_lote, , drop = FALSE]
    if (nrow(fila) > 0L) compilar_dash_preview(fila[1L, ])
  }, ignoreInit = TRUE)

  output$dash_visor_pdf <- shiny::renderUI({
    if (is.null(rv$dash_pdf_url)) {
      return(shiny::div(
        class = "alert alert-info mt-3",
        "Seleccione un predio existente o ingrese los datos y pulse 'Guardar en Excel Maestro y Generar Vista Previa'."
      ))
    }
    shiny::tags$iframe(
      src = rv$dash_pdf_url,
      style = "width: 100%; height: 680px; border: 1px solid #dee2e6; border-radius: 6px;"
    )
  })

  shiny::observeEvent(input$btn_dash_export_uno, {
    req(input$dash_cargar_lote)
    if (identical(input$dash_cargar_lote, "__NUEVO__")) {
      shiny::showNotification("Primero guarde el predio en el Excel maestro.", type = "warning")
      return()
    }
    ids <- paste0(toupper(rv$df$mz), "_", rv$df$lote)
    fila <- rv$df[ids == input$dash_cargar_lote, , drop = FALSE]
    if (nrow(fila) == 0L) return()
    mz <- fila$mz[1L]; lt <- fila$lote[1L]
    fn <- switch(
      input$dash_doc,
      sgpuat     = titulacionMPA::generar_informe_sgpuat,
      gdur       = titulacionMPA::generar_informe_gdur,
      legal      = titulacionMPA::generar_informe_legal,
      resolucion = titulacionMPA::generar_resolucion_alcaldia,
      titulo     = titulacionMPA::generar_titulo_propiedad
    )
    ruta <- fn(mz, lt, config = rv$config, fecha = input$dash_fecha, formato = "pdf", sobrescribir = TRUE)
    shiny::showNotification(paste("PDF generado:", basename(ruta)), type = "message")
    output$dash_estado <- shiny::renderText(paste("Archivo exportado en:\n", ruta))
  })

  shiny::observeEvent(input$btn_dash_export_todos, {
    req(input$dash_cargar_lote)
    if (identical(input$dash_cargar_lote, "__NUEVO__")) {
      shiny::showNotification("Primero guarde el predio en el Excel maestro.", type = "warning")
      return()
    }
    ids <- paste0(toupper(rv$df$mz), "_", rv$df$lote)
    fila <- rv$df[ids == input$dash_cargar_lote, , drop = FALSE]
    if (nrow(fila) == 0L) return()
    mz <- fila$mz[1L]; lt <- fila$lote[1L]
    res <- titulacionMPA::generar_expediente_completo(
      mz, lt, config = rv$config, fecha = input$dash_fecha, formato = "pdf", sobrescribir = TRUE
    )
    shiny::showNotification(paste("Expediente completo generado (5 PDFs) para Mz.", mz, "Lt.", lt), type = "message")
    output$dash_estado <- shiny::renderText(paste(c("5 documentos generados:", unlist(res)), collapse = "\n"))
  })

  # ============================================================================
  # LÓGICA DEL EDITOR DE PLANTILLAS (CON RESALTADO DE CAMPOS DEL EXCEL)
  # ============================================================================
  shiny::observeEvent(input$doc_tipo, {
    tpl_dir <- obtener_dir_plantillas_typst(rv$config)
    ruta_tpl <- file.path(tpl_dir, plantilla_archivo(input$doc_tipo))
    if (file.exists(ruta_tpl)) {
      txt <- paste(readLines(ruta_tpl, encoding = "UTF-8", warn = FALSE), collapse = "\n")
      shiny::updateTextAreaInput(session, "txt_plantilla", value = txt)
    }
  }, ignoreInit = FALSE)

  compilar_preview <- function() {
    req(input$lote_id, input$doc_tipo, input$txt_plantilla)
    ids <- paste0(toupper(rv$df$mz), "_", rv$df$lote)
    item <- rv$df[ids == input$lote_id, , drop = FALSE]
    if (nrow(item) == 0L) return()

    res <- renderizar_preview_typst(
      doc_tipo = input$doc_tipo,
      item = item[1L, ],
      config = rv$config,
      fecha_doc = input$fecha_doc,
      plantilla_texto = input$txt_plantilla,
      resaltar_excel = isTRUE(input$chk_resaltar_pdf),
      tmp_dir = tmp_dir,
      prefix = "edit"
    )

    rv$payload_editor <- res$payload
    if (res$ok && file.exists(file.path(tmp_dir, res$pdf_name))) {
      rv$pdf_url <- paste0("preview_pdf/", session_id, "/", res$pdf_name)
      output$estado_compilacion <- shiny::renderText(
        paste0("Compilado OK (", format(Sys.time(), "%H:%M:%S"), ")", if (isTRUE(input$chk_resaltar_pdf)) " [Campos Excel resaltados]" else "")
      )
    } else {
      output$estado_compilacion <- shiny::renderText(paste("Error Typst:\n", res$log))
    }
  }

  shiny::observeEvent(
    list(input$btn_preview, input$lote_id, input$doc_tipo, input$chk_resaltar_pdf),
    {
      compilar_preview()
    },
    ignoreInit = TRUE
  )

  output$plantilla_resaltada <- shiny::renderUI({
    req(input$txt_plantilla)
    shiny::HTML(resaltar_plantilla_html(input$txt_plantilla, rv$payload_editor))
  })

  output$panel_campos_excel <- shiny::renderUI({
    req(input$txt_plantilla)
    m <- gregexpr("#?data\\.([A-Za-z0-9_]+)", input$txt_plantilla, perl = TRUE)
    toks <- unique(regmatches(input$txt_plantilla, m)[[1L]])
    if (length(toks) == 0L) {
      return(shiny::p(class = "text-muted small", "No se detectaron variables #data.* en esta plantilla."))
    }
    campos <- unique(sub("^#?data\\.", "", toks))
    payload <- rv$payload_editor
    filas <- lapply(campos, function(cmp) {
      meta <- diccionario_excel[diccionario_excel$variable == paste0("data.", cmp), , drop = FALSE]
      etiq <- if (nrow(meta) > 0L) meta$etiqueta[1L] else cmp
      orig <- if (nrow(meta) > 0L) meta$origen[1L] else "Excel maestro"
      val <- if (!is.null(payload) && !is.null(payload[[cmp]])) as.character(payload[[cmp]])[1L] else ""
      shiny::tags$tr(
        shiny::tags$td(shiny::tags$span(class = "excel-token", paste0("#data.", cmp))),
        shiny::tags$td(etiq),
        shiny::tags$td(shiny::tags$small(class = "text-muted", orig)),
        shiny::tags$td(shiny::tags$small(val))
      )
    })
    shiny::div(
      style = "max-height: 210px; overflow-y: auto;",
      shiny::tags$table(
        class = "table table-sm table-bordered mb-0",
        shiny::tags$thead(
          shiny::tags$tr(
            shiny::tags$th("Marcador protegido"),
            shiny::tags$th("Campo"),
            shiny::tags$th("Origen"),
            shiny::tags$th("Valor actual")
          )
        ),
        shiny::tags$tbody(filas)
      )
    )
  })

  shiny::observeEvent(input$btn_guardar, {
    req(input$doc_tipo, input$txt_plantilla)
    tpl_dir <- obtener_dir_plantillas_typst(rv$config)
    ruta_tpl <- file.path(tpl_dir, plantilla_archivo(input$doc_tipo))
    writeLines(enc2utf8(input$txt_plantilla), ruta_tpl, useBytes = TRUE)
    shiny::showNotification(paste("Plantilla guardada:", basename(ruta_tpl)), type = "message")
    compilar_preview()
  })

  shiny::observeEvent(input$btn_exportar, {
    req(input$lote_id, input$doc_tipo)
    ids <- paste0(toupper(rv$df$mz), "_", rv$df$lote)
    item <- rv$df[ids == input$lote_id, , drop = FALSE]
    if (nrow(item) == 0L) return()
    mz <- item$mz[1L]; lt <- item$lote[1L]
    fn <- switch(
      input$doc_tipo,
      sgpuat     = titulacionMPA::generar_informe_sgpuat,
      gdur       = titulacionMPA::generar_informe_gdur,
      legal      = titulacionMPA::generar_informe_legal,
      resolucion = titulacionMPA::generar_resolucion_alcaldia,
      titulo     = titulacionMPA::generar_titulo_propiedad
    )
    ruta <- fn(mz, lt, config = rv$config, fecha = input$fecha_doc, formato = "pdf", sobrescribir = TRUE)
    shiny::showNotification(paste("PDF exportado en:", ruta), type = "message")
  })

  output$visor_pdf <- shiny::renderUI({
    if (is.null(rv$pdf_url)) {
      return(shiny::p("Seleccione un predio y pulse 'Actualizar Vista Previa'."))
    }
    shiny::tags$iframe(
      src = rv$pdf_url,
      style = "width: 100%; height: 680px; border: 1px solid #dee2e6; border-radius: 6px;"
    )
  })
}

shiny::shinyApp(ui, server)
