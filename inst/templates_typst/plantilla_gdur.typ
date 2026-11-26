#import "estilo_comun.typ": *

#let data = json(sys.inputs.at("json_file"))

#set page(
  paper: "a4",
  margin: (top: 2.7cm, bottom: 1.8cm, left: 2.8cm, right: 2.0cm),
  header-ascent: 0.35cm,
  header: encabezado_institucional(subtitulo: "GERENCIA DE DESARROLLO URBANO Y RURAL", compacto: true),
  footer-descent: 0.35cm,
  footer: context {
    grid(
      columns: (1fr, 1fr),
      align: (left + bottom, right + bottom),
      text(font: FUENTE_MPA, size: 8pt)[Archivo \ GDUR \ EEIQ],
      text(font: FUENTE_MPA, size: 8pt)[Página #counter(page).display()]
    )
  }
)

#show: aplicar_texto_base.with(size: 10pt, leading: 0.50em, spacing: 0.65em)

#align(center)[
  #text(size: 11pt, weight: "bold")[
    #underline[INFORME N° #data.num_gdur - #data.anio - EEIQ / GDUR-MPA]
  ]
]
#v(0.08cm)

#set par(first-line-indent: 0pt)
#grid(
  columns: (2.3cm, 0.35cm, 1fr),
  row-gutter: 3.5pt,
  [*A*], [:], [*#upper(data.asesor_legal)* \ GERENCIA DE ASESORIA LEGAL],
  [*DE*], [:], [*#data.gerente_gdur* \ GERENTE DE DESARROLLO URBANO Y RURAL.],
  [*ASUNTO*], [:], [Procedimiento para la formalización de predios en el marco de la Ley N.° 28687. \ *#data.tratamiento #data.t1_nombre - PREDIO Mz. #data.mz Lote #data.lote #data.sector.*],
  [*REFERENCIA*], [:], [*INFORME N° #data.num_sgpuat\-#data.anio\-SGPUAT-GDUR-MPA.* \ *EXP. ADM. N.° #data.expediente*],
  [*FECHA*], [:], [Anta; #data.fecha_doc.]
)
#v(2pt)
#line(length: 100%, stroke: 0.4pt + black)
#v(0.08cm)

Previo un cordial saludo, me dirijo a usted para remitir el informe sobre el procedimiento de formalización del predio indicado.

*ANTECEDENTES*

Mediante el expediente administrativo N.° #data.expediente, #data.nombres_resumen #data.sujeto_solicitan la formalización del predio ubicado en la Mz. #data.mz Lote #data.lote de la #data.sector, distrito y provincia de #data.provincia, departamento de #data.departamento.

El INFORME N° #data.num_sgpuat\-#data.anio\-SGPUAT-GDUR-MPA evalúa la solicitud y sus documentos sustentatorios. Los requisitos consignados para la continuación del trámite son los siguientes:

#tabla_tupa(data.tupa_6, data.tupa_7, data.tupa_8, size: 8.5pt, booktabs: false)
#v(0.08cm)

*NORMATIVA*

El numeral 4.3 del artículo 4 de la Ley N.° 28687 establece la competencia del alcalde provincial para suscribir los títulos de propiedad dentro de su jurisdicción. El numeral 27 del artículo 20 de la Ley Orgánica de Municipalidades, Ley N.° 27972, atribuye al alcalde el otorgamiento de títulos de propiedad emitidos en el ámbito de su jurisdicción y competencia.

*CONCLUSIÓN*

De acuerdo con la evaluación técnico administrativa detallada en el INFORME N° #data.num_sgpuat\-#data.anio\-SGPUAT-GDUR-MPA, se emite *OPINIÓN FAVORABLE* para la continuación del procedimiento de formalización del predio Mz. #data.mz Lote #data.lote de la #data.sector, a favor de #data.nombres_resumen. Corresponde remitir el expediente a Gerencia Municipal para la continuación del trámite y la opinión legal que corresponda.

Es todo cuanto informo para los fines pertinentes, adjuntando el expediente administrativo en original.

#v(0.15cm)
#align(center)[Atentamente.]
