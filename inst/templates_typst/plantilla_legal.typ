#import "estilo_comun.typ": *

#let data = json(sys.inputs.at("json_file"))

#set page(
  paper: "a4",
  margin: (top: 4.8cm, bottom: 3.1cm, left: 2.45cm, right: 2.45cm),
  background: image("FONDO_INFORME_LEGAL.png", width: 100%, height: 100%),
  header-ascent: 1.1cm,
  header: align(center)[
    #text(font: FUENTE_MPA, size: 10.5pt, weight: "bold")[GERENCIA DE ASESORÍA LEGAL] \
    #text(font: FUENTE_MPA, size: 8.5pt, weight: "bold")[“Año de la Recuperación y Consolidación de la Economía Peruana”]
  ]
)

#show: aplicar_texto_base.with(size: 10.5pt, leading: 0.55em, spacing: 0.85em)

#align(center)[
  #text(size: 11.5pt, weight: "bold")[
    #underline[INFORME LEGAL N.° #data.num_legal \-#data.anio\-GAL-MPA]
  ]
]
#v(0.15cm)

#set par(first-line-indent: 0pt)
#grid(
  columns: (2.6cm, 0.4cm, 1fr),
  row-gutter: 5pt,
  [*A*], [:], [#data.gerente_mun \ Gerente Municipal - MPA.],
  [*DE*], [:], [#data.asesor_legal \ Asesor Legal - MPA],
  [*ASUNTO*], [:], [FORMALIZACION DE PREDIOS.],
  [*REFERENCIA*], [:], [#data.sector Mz. “#data.mz” Lote #data.lote_str \ \ EXPEDIENTE ADMINISTRATIVO N.°#data.expediente \ INFORME N°#data.num_sgpuat\-#data.anio\-SGPUAT-GDUR-MPA \ INFORME N°#data.num_gdur\-#data.anio\-EEIQ/GDUR-MPA],
  [*FECHA*], [:], [Anta, #data.fecha_doc]
)
#v(4pt)
#line(length: 100%, stroke: 0.4pt + black)
#v(0.2cm)

Previo un atento y cordial saludo, tengo el agrado de dirigirme a usted, en atención al documento de referencia, respecto a la solicitud, por lo que cumplo con emitir el correspondiente Informe Legal, en los siguientes términos:

*I. ANTECEDENTES:*

1. Mediante EXPEDIENTE ADMINISTRATIVO N.°#data.expediente ingresado por mesa de partes; en fecha #data.fecha_exp, #data.admin_solic_ant, solicita formalización de la #data.sector Mz. “#data.mz” Lote #data.lote_str del distrito de #data.distrito, provincia de #data.provincia y Departamento de #data.departamento.

2. Mediante Informe N.º #data.num_sgpuat\-#data.anio\-SGPUAT-GDUR-MPA de fecha #data.fecha_sgpuat, el Subgerente de Planeamiento Urbano y Acondicionamiento Territorial se dirige al Gerente de Desarrollo Urbano y Rural remitiendo opinión favorable de proceso de formalización de predios en merito a que habiendo realizado la evaluación técnico-administrativa del Exp. #data.expediente cumple con los requisitos establecidos en el TUPA de la Entidad y por lo que solicita opinión legal para su continuación del proceso de titulación del predio de la #data.sector Mz. “#data.mz” Lote #data.lote_str del distrito de #data.distrito, provincia de #data.provincia y Departamento de #data.departamento.

3. Mediante Informe N.° #data.num_gdur\-#data.anio\-EEIQ/GDUR-MPA de fecha #data.fecha_gdur, la Gerente de Desarrollo Urbano y Rural se dirige al Gerente Municipal remitiendo expediente administrativo de formalización de predio para su trámite.

*II. BASE LEGAL:*

1. Constitución Política del Perú.
2. Ley N° 27972 Ley Orgánica de Municipalidades.
3. Ley N° 27444, Ley del Procedimiento Administrativo General.
4. Ley N° 28687, Ley de Desarrollo y Complementaria de Formalización de la Propiedad Informal Acceso al Suelo y Dotación de Servicios Básicos y su Reglamento aprobado por Decreto Supremo N° 006-2006, modificado por Decreto Supremo N° 030-2008-VIVIENDA, y el Decreto Supremo N° 020-2012-VIVIENDA. Decreto Supremo N° 004-2020-VIVIENDA.

*III. ANALISIS:*

1. La Municipalidad Provincial de Anta, es un órgano de Gobierno Local, promotor de desarrollo, con personería jurídica de derecho público y plena capacidad para el cumplimiento de sus fines, con autonomía política, económica y administrativa en los asuntos de su competencia.

2. Respecto a la titularidad de predios en procedimientos administrativos, la Ley 27444 establece: Administrados con Interés Legítimo: Quienes promueven procedimientos como titulares de derechos (incluyendo derechos sobre predios) o intereses legítimos son considerados administrados.

3. De la documentación presentada, y del sustento favorable de la Sub Gerencia de Planeamiento Urbano y Acondicionamiento Territorial se evidencia que #data.sujeto_posesion, se encuentra en posesión del predio, de la #data.sector Mz. “#data.mz” Lote #data.lote_str con un área total de #data.area m2, según la partida electrónica #data.partida SUNARP.

4. Mediante la Ley N°29802 se amplió el plazo por un período de cinco años, el cual fue ampliado por Ley N°30513 hasta el 31 de diciembre de 2017 que a su vez se amplió por Ley N°30711 hasta el 31 de diciembre de 2021, plazo que fuese ampliado por Ley N° 31056 hasta el 31 de diciembre del 2026.

5. Ahora bien, haciendo mención a la Ley N.°28687 Ley de desarrollo y complementaria de formalización de la propiedad informal, acceso al suelo y dotación de servicios básicos, en su Artículo 2 indica: _“Formalización de la propiedad Declárase de preferente interés nacional la formalización de la propiedad informal, con su respectiva inscripción registral, respecto de los terrenos ocupados por posesiones informales...”_

6. En este orden de ideas el Decreto Supremo N°006-2006-VIVIENDA en su artículo 2 numeral 2.1 señala: _“Las entidades formalizadoras en el ámbito de sus circunscripciones territoriales, asumen la competencia en materia de formalización de la propiedad informal, hasta la inscripción de los Títulos de propiedad en el Registro de predios”_; en este sentido, el Texto Único de Procedimientos Administrativos (TUPA), aprobado mediante #data.ordenanza_tupa, indica que la Municipalidad está facultada para legalizar la transferencia de propiedad de los predios a favor de los solicitantes que reúnan los requisitos de ley.

*IV. OPINIÓN LEGAL:*

Estando a las consideraciones expuestas y al marco normativo vigente, esta Gerencia de Asesoría Legal opina por la *VIABILIDAD LEGAL Y PROCEDENCIA* de la solicitud de formalización y titulación del predio ubicado en la #data.sector Mz. “#data.mz” Lote #data.lote_str del distrito de #data.distrito, provincia de #data.provincia y Departamento de #data.departamento, a favor de #data.titulares_legal, recomendando remitir los actuados a Secretaría General para la emisión de la Resolución de Alcaldía y Título de Propiedad correspondiente.

Es todo cuanto informo a usted, para su conocimiento y fines pertinentes.

#v(0.3cm)
#align(center)[Atentamente.]
