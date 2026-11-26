// ==============================================================================
// ESTILOS COMUNES ESTANDARIZADOS - titulacionMPA (Times New Roman)
// ==============================================================================

#let FUENTE_MPA = "Times New Roman"

#let aplicar_texto_base(size: 11pt, leading: 0.60em, spacing: 0.90em, indent: 0pt, body) = {
  set text(font: FUENTE_MPA, size: size, lang: "es")
  set par(
    justify: true,
    leading: leading,
    spacing: spacing,
    first-line-indent: (amount: indent, all: true)
  )
  body
}

#let encabezado_institucional(subtitulo: none, compacto: false) = {
  let w_logo = if compacto { 1.50in } else { 1.75in }
  let h_logo = if compacto { 0.48in } else { 0.58in }
  let sz_tit = if compacto { 9pt } else { 11pt }
  let texto_centro = if subtitulo != none {
    [*MUNICIPALIDAD PROVINCIAL DE ANTA* \ #subtitulo]
  } else {
    [*MUNICIPALIDAD PROVINCIAL DE* \ *ANTA*]
  }
  block(width: 100%)[
    #grid(
      columns: (auto, 1fr, auto),
      align: (left + horizon, center + horizon, right + horizon),
      image("mpa.png", width: w_logo, height: h_logo, fit: "contain"),
      text(font: FUENTE_MPA, size: sz_tit, fill: rgb("#555555"), weight: "bold")[#texto_centro],
      image("choquequirao.png", width: w_logo, height: h_logo, fit: "contain")
    )
    #v(2pt)
    #line(length: 100%, stroke: if compacto { 0.5pt + black } else { 1.2pt + rgb("#9AB59B") })
  ]
}

#let pie_folio() = context {
  align(right, text(font: FUENTE_MPA, size: 9pt)[
    Folio N.° #counter(page).display() de #counter(page).final().first()
  ])
}

#let tabla_tupa(tupa_6, tupa_7, tupa_8, size: 9.5pt, booktabs: false) = {
  set par(first-line-indent: 0pt, justify: false)
  set text(font: FUENTE_MPA, size: size)
  let stroke_cfg = if booktabs {
    (x, y) => (
      top: if y == 0 { 0.8pt } else { 0pt },
      bottom: if y == 0 or y == 11 { 0.8pt } else { 0pt },
      left: 0pt,
      right: 0pt
    )
  } else {
    0.4pt + black
  }
  table(
    columns: (8%, 68%, 24%),
    align: (center + horizon, left + horizon, center + horizon),
    inset: (x: 5pt, y: 3.5pt),
    stroke: stroke_cfg,
    [*ITEM*], [*DESCRIPCIÓN*], [*OBSERVACIÓN*],
    [1], [Formato Único de Trámite (FUT) y solicitud dirigida al titular del pliego], [CUMPLE],
    [2], [Copia legalizada o fedateada del DNI de los titulares.], [CUMPLE],
    [3], [Declaración jurada de que sobre la superficie no exista proceso judicial ni administrativo pendiente en el que se discuta el mejor derecho de propiedad de posesión.], [CUMPLE],
    [4], [Constancia de ser socio activo del PP. JJ, AA.HH., COMUNIDAD, otorgado por la junta directiva vigente.], [CUMPLE],
    [5], [Constancia de posesión emitida por la junta directiva vigente.], [CUMPLE],
    [6], [Certificado o declaración jurada de defunción del cónyuge o del conviviente de ser el caso.], [#tupa_6],
    [7], [Copia de acta de matrimonio de ser el caso.], [#tupa_7],
    [8], [Acta de convivencia de ser el caso.], [#tupa_8],
    [9], [Copia de documentos que acrediten la posesión con 5 años de antigüedad (recibo de luz, autoevaluó, etc.).], [CUMPLE],
    [10], [Acta de colindancia (según modelo) con firmas legalizadas o fedateadas.], [CUMPLE],
    [11], [Recibo de pago por costos de desplazamiento de acuerdo a la zona y por inspección técnica (TUSNE).], [CUMPLE]
  )
}
