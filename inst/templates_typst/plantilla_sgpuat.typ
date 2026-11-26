#import "estilo_comun.typ": *

#let data = json(sys.inputs.at("json_file"))

#set page(
  paper: "a4",
  margin: (top: 3.2cm, bottom: 2.3cm, left: 2.5cm, right: 2.2cm),
  header-ascent: 0.4cm,
  header: encabezado_institucional(),
  footer-descent: 0.4cm,
  footer: context {
    let is_last = counter(page).get().first() == counter(page).final().first()
    if is_last {
      grid(
        columns: (1fr, 1fr),
        align: (left + bottom, right + bottom),
        text(font: FUENTE_MPA, size: 9pt, weight: "bold")[GDUR \ SGPUAT \ CEEL],
        text(font: FUENTE_MPA, size: 9pt)[C.c. Archivo]
      )
    }
  }
)

#show: aplicar_texto_base.with(size: 11pt, leading: 0.58em, spacing: 0.85em)

#align(center)[
  #text(size: 12pt, weight: "bold")[INFORME N°#data.num_sgpuat\-#data.anio\-SGPUAT-GDUR-MPA]
]
#v(0.2cm)

#set par(first-line-indent: 0pt)
#grid(
  columns: (2.6cm, 0.4cm, 1fr),
  row-gutter: 5pt,
  [*A:*], [:], [*#data.gerente_gdur* \ _GERENTE DE DESARROLLO URBANO Y RURAL._],
  [*DE:*], [:], [*#data.subgerente_sg* \ _SUBGERENTE DE PLANEAMIENTO URBANO Y ACONDICIONAMIENTO TERRITORIAL_],
  [*ASUNTO:*], [:], [REMITO OPINION FAVORABLE DE PROCESO DE FORMALIZACION DE PREDIOS Y SOLICITO OPINION LEGAL PARA SU CONTINUACION DEL PROCESO DE TITULACION DEL PREDIO UBICADO EN LA MZ #data.mz LOTE #data.lote DE LA #data.sector],
  [*REFERENCIA:*], [:], [EXP. ADM. N°#data.expediente],
  [*FECHA:*], [:], [#data.fecha_doc]
)
#v(2pt)
#line(length: 100%, stroke: (paint: black, thickness: 0.5pt, dash: "dotted"))
#v(0.15cm)

Previo cordial saludo, por el presente tengo el agrado de dirigirme a usted, para remitir el informe respecto a la solicitud de #data.solicitante_saludo, #data.quien_solicita PROCESO PARA LA FORMALIZACIÓN DE PREDIOS de la #data.sector, ubicado en la Mz #data.mz Lote #data.lote. Al respecto se informa lo siguiente:

*ANTECEDENTES*

En virtud a lo dispuesto en la Ley N°27972 – Ley Orgánica de Municipalidades, Ley N.º 28687- “Ley de Desarrollo y Complementaria de Formalización de la Propiedad Informal, Acceso al Suelo y Dotación de Servicios Básicos”, Decreto Supremo N°006-2006-VIVIENDA-Reglamento del Título I de la Ley N°28687, referido a la Formalización de la Propiedad Informal de Terrenos Ocupados por Posesiones Informales, Centros Urbanos Informales y Urbanizaciones Populares, y en aplicación del Decreto Supremo N°004-85.VC, Reglamento de Adjudicación de Terrenos Fiscales para Fines Urbanos, y que el Texto Único de Procedimientos Administrativos TUPA de la Municipalidad Provincial de Anta, aprobado mediante #data.ordenanza_tupa; por el cual, la Municipalidad Provincial De Anta, está facultada para legalizar la transferencia de la propiedad de los predios a favor de los solicitantes que reúnan los requisitos de ley.

Mediante la Ley N°31056 y su reglamento D.S. N°002-2021-VIVIENDA, se crea un régimen temporal extraordinario de formalización y titulación de predios urbanos, el cual tiene una vigencia hasta el 31 de diciembre del 2026. Asimismo, mediante la Ley N°32267 amplía por última vez hasta el 31 de diciembre de 2021 los plazos establecidos en las leyes 28687 y 31056 para la formalización de terrenos estatales ocupados por posesiones informales.

En el D.S. N°005-2026-VIVIENDA, Decreto Supremo que modifica el Reglamento del Título I de la Ley N°28687, Ley de desarrollo y complementaria de formalización de la propiedad informal, acceso al suelo y dotación de servicios básicos, denominado “Formalización de la Propiedad Informal de Terrenos Ocupados por Posesiones Informales, Centros Urbanos Informales y Urbanizaciones Populares”, aprobado por el Decreto Supremo N°006-2006-VIVIENDA, en su artículo 2.1 señala lo siguiente: _“Las entidades formalizadoras, en el ámbito de sus circunscripciones territoriales, asumen la competencia en materia de formalización de la propiedad informal, hasta la inscripción de los títulos de propiedad en el Registro de Predios.”_

Mediante el Exp. Adm. N°#data.expediente #data.titulares_informe, #data.sujeto_solicitan el procedimiento de formalización en el marco de la Ley N°28687 y su respectivo reglamento, así como el marco normativo Ley N°31056, Ley N°32267 y sus respectivos reglamentos, en donde #data.sujeto_vienen posesión del predio ubicado en la Mz #data.mz Lote #data.lote de la #data.sector, distrito de #data.distrito, provincia de #data.provincia, cuyo predio ha pasado a nombre de la Municipalidad Provincial de Anta inscrito en la partida electrónica #data.partida, para continuar con el proceso de formalización, el cual fue saneada por la Municipalidad Provincia de Anta mediante #data.res_lotizacion de fecha #data.fecha_lotizacion.

Mediante el Exp. Adm. N°#data.expediente #data.nombres_resumen, #data.sujeto_adjuntan documentos sustentatorios del predio en posesión, entre ellos la constancia de posesión emitida por la Municipalidad Provincial de Anta, en la cual se constató la posesión de manera pacífica, pública y continua del predio situado en la Mz #data.mz Lote #data.lote de la #data.sector.

De acuerdo al TUPA de la Municipalidad Provincial de Anta, los requisitos solicitados y presentados son los siguientes:

#tabla_tupa(data.tupa_6, data.tupa_7, data.tupa_8, size: 9.5pt, booktabs: false)
#v(0.15cm)

#data.sujeto_admin_cap #data.sujeto_adjuntan una declaración jurada en donde #data.sujeto_declaran la ubicación real del predio a formalizar, así como la conformidad del área y medias perimétricas que corresponde al predio en posesión y que está en base al plano de trazado y lotización aprobado mediante #data.res_lotizacion.

*BASE LEGAL*

- Ley Orgánica de Municipalidades – Ley N° 27972.
- Ley N° 28687 - Ley de Formalización de la Propiedad Informal, Acceso al Suelo y Dotación de Servicios Básicos.
- Ley N°30711– Ley que Establece Medidas Complementarias para la Promoción del Acceso a la Propiedad Formal.
- Ley N°31056 – Ley que Amplía los Plazos de la Titulación de Terrenos Ocupados por Posesiones Informales y Dicta Medidas para la Formalización.
- Ley Nº31560 – Ley que Otorga Funciones Compartidas a los Gobiernos Locales en los procesos de Formalización de la Propiedad Informal.
- Ley N°32267 – Ley que amplían plazo para formalización de terrenos ocupados por posesiones informales.
- D.S. 005-2026-VIVIENDA - Decreto Supremo que modifica el Reglamento del Título I de la Ley N°28687.

*EVALUACION*

#data.sujeto_admin_cap, #data.sujeto_cumplido con los requisitos establecidos en el TUPA para el procedimiento de formalización de predios, el cual se pasa a detallar:

- Mediante la declaración jurada, #data.sujeto_admin #data.sujeto_declaran no tener procedimiento judicial ni administrativo sobre el predio. Dicha manifestación escrita se declara como cierto, el cual se encuentra descrito en la Ley N°27444, Ley de Procedimiento Administrativo General.
- #data.sujeto_admin_cap #data.sujeto_presentan una constancia de posesión remitida por la Municipalidad Provincial de Anta del predio ubicado en la Mz. #data.mz Lote #data.lote de la #data.sector, en la que se describe que #data.sujeto_admin, #data.sujeto_vienen ejerciendo posesión de forma continua, pacífica y publica del predio en mención.
#if data.evaluacion_formateada != "" [
- #data.evaluacion_formateada
]
- De acuerdo a la declaración jurada anexada al presente expediente para el proceso de formalización, el predio se encuentra ubicado en la #data.sector en la Mz #data.mz Lote #data.lote. El predio forma parte del terreno matriz que fue transferido por la asamblea de la #data.sector a la Municipalidad Provincial de Anta para realizar el proceso de formalización en el marco de la Ley N°28687 y la Ley N°31056. El predio matriz se encuentra inscrito en la #data.partida.
- Se ha verificado que el predio se encuentra físicamente ubicados conforme al plano de trazado y lotización de la #data.sector, aprobado por la Gerencia de Desarrollo Urbano y Rural de la Municipalidad Provincial de Anta, mediante la #data.res_lotizacion de fecha #data.fecha_lotizacion.
- De acuerdo a la constancia de posesión remitida por la Municipalidad Provincial de Anta, se constata la posesión de #data.nombres_constata, en forma continua, pacífica y publica desde el #data.anio_pos, y que, conforme a la Ley N°32267 – Ley que amplían plazo para formalización de terrenos ocupados por posesiones informales.
- No se evidencian superposiciones con otras propiedades registradas ni con bienes de dominio público ni antecedentes registrales que impidan su saneamiento.

*CONCLUSION*

Habiéndose realizado la evaluación técnico-administrativa de la solicitud presentada por #data.sujeto_admin mediante el expediente N°#data.expediente, del procedimiento para la formalización de predios, del predio urbano ubicado en la #data.sector Mz #data.mz Lote #data.lote del distrito de #data.distrito, provincia de #data.provincia, del departamento de #data.departamento, con un área de #data.area m2 y un perímetro de #data.perimetro m, según la partida electrónica #data.partida SUNARP, se da *OPINIÓN FAVORABLE* para el proceso de formalización a favor de: #data.titulares_informe, cumpliendo con los requisitos establecidos en el TUPA de la Municipalidad Provincial de Anta, por lo que solicita remitir el presente informe y sus actuados a la Gerencia Municipal para su posterior emisión del título de alcaldía, previo opinión por parte de la Gerencia de Asesoría Legal.

Es todo cuanto informo a usted, para su conocimiento y fines correspondientes.

#v(0.2cm)
#align(center)[Atentamente.]
