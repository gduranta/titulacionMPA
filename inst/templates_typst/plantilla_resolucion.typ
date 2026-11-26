#import "estilo_comun.typ": *

#let data = json(sys.inputs.at("json_file"))

#set page(
  paper: "a4",
  margin: (top: 3.0cm, bottom: 1.5cm, left: 2.5cm, right: 2.5cm),
  footer-descent: 0.6cm,
  footer: pie_folio()
)

#show: aplicar_texto_base.with(size: 11pt, leading: 0.60em, spacing: 0.85em, indent: 1.0cm)

#set par(first-line-indent: 0pt)
#align(center)[
  #text(weight: "bold")[#underline[RESOLUCIÓN DE ALCALDIA N. º#data.num_res\-#data.anio\-A-MPA/C]]
]
#v(0.15cm)
#align(right)[Anta, #data.fecha_doc.]
#v(0.15cm)
#align(center)[
  #text(weight: "bold")[#underline[EL ALCALDE DE LA MUNICIPALIDAD PROVINCIAL DE ANTA]]
]
#v(0.30cm)

#set par(first-line-indent: (amount: 1.0cm, all: true))

*VISTO:* El expediente administrado N.°#data.expediente, presentado de fecha #data.fecha_exp, el INFORME N°#data.num_sgpuat\-#data.anio\-SGPUAT-GDUR-MPA de la Subgerencia de Planeamiento Urbano y Acondicionamiento Territorial, el INFORME N°#data.num_gdur\-#data.anio\-EEIQ/GDUR-MPA de la Gerencia de Desarrollo Urbano y Rural; y el INFORME LEGAL N.º #data.num_legal\-#data.anio\-GAL-MPA de la Gerencia de Asesoría Legal de la Municipalidad Provincial de Anta, y;

*CONSIDERANDO:*

Que, el artículo 194° de la Constitución Política del Estado; concordante con el artículo II del Título Preliminar de la Ley N.º 27972 Ley Orgánica de Municipalidades, señala que la Autonomía conferida radica la facultad que tienen las Municipalidades de poder ejercer actos de Gobierno, actos administrativos y actos de administración, los mismos que deben estar impartidos con sujeción al ordenamiento jurídico vigente;

Que, el Principio de Legalidad reconocido en el artículo IV del Título Preliminar del Texto Único Ordenado de la Ley N.°27444 Ley del Procedimiento Administrativo General, aprobado por el Decreto Supremo N.°004-2019-JUS establece que; “todas las autoridades administrativas deben actuar con respeto a la Constitución, la ley y el derecho, dentro de sus facultades que le estén atribuidas y de acuerdo con los fines para los que les fueron conferidas”;

Que, el numeral 6 del artículo 195 de la Constitución Política del Perú, preceptúa que los gobiernos locales tienen competencia para planificar el desarrollo urbano y rural de sus circunscripciones, incluyendo la zonificación, urbanismo y el acondicionamiento territorial; y dentro de este marco normativo constitucional, el artículo 73° la Ley N.° 27972 Ley Orgánica de Municipalidades ha regulado que las Municipalidades, tomando en cuenta su condición de municipalidad provincial o distrital, asumen las competencias y ejercen las funciones específicas señaladas en el capítulo II del título V de dicha norma municipal con carácter exclusiva o compartido entre otras materias, en cuanto a la organización del espacio físico y uso de suelo del ámbito de su jurisdicción territorial, estando dentro de ello el reconocimiento, verificación, titulación y saneamiento físico legal de asentamientos humanos a que se refiere el artículo 79°, numeral 1.4.3 de la misma Ley;

Que, mediante Formulario Único de Tramite (FUT) con expediente administrado N.°#data.expediente, presentado de fecha #data.fecha_exp; interpuesto por #data.titular_fut, #data.verbo_fut de predio, donde #data.posesion_fut del predio ubicado en la #data.sector Mz. “#data.mz” Lote #data.lote del distrito de #data.distrito, provincia de #data.provincia y Departamento de #data.departamento;

Que mediante el INFORME N°#data.num_sgpuat\-#data.anio\-SGPUAT-GDUR-MPA de fecha #data.fecha_sgpuat la Subgerencia de Planeamiento Urbano y Acondicionamiento Territorial de la Municipalidad Provincial de Anta, habiendo realizado la evaluación técnico-administrativa de la solicitud presentada por #data.solicitante_eval mediante el Expediente N.°#data.expediente, del predio urbano ubicado en la #data.sector Mz. “#data.mz” Lote #data.lote del distrito de #data.distrito, provincia de #data.provincia y Departamento de #data.departamento; Inscrito con Partida Registral N.º PE. #data.partida - SUNARP por lo que da opinión favorable a favor de #data.titulares_res; para el proceso de formalización remitiendo el informe y actuados a Gerencia de Desarrollo Urbano y Rural, para su posterior emisión de título de alcaldía, previa opinión del Asesor Legal;

Que, mediante INFORME N°#data.num_gdur\-#data.anio\-EEIQ/GDUR-MPA de fecha #data.fecha_gdur, la Gerencia de Desarrollo Urbano y Rural, remite el expediente a Gerencia Municipal para la emisión de acto administrativo correspondiente;

Que, mediante INFORME LEGAL N.º #data.num_legal\-#data.anio\-GAL-MPA de fecha #data.fecha_legal, la Gerencia de Asesoría Legal opina de manera favorable a la petición formulada sobre la solicitud del “Proceso de formalización del predio ubicado en la #data.sector Mz. “#data.mz” Lote #data.lote, del distrito y provincia de #data.provincia, departamento del #data.departamento y recomienda que se emita el acto administrativo correspondiente, remitiendo el expediente a Gerencia Municipal;

Que, mediante proveído N°#data.num_prov\-#data.anio\-GM-MPA de fecha #data.fecha_prov la Gerencia Municipal remite el expediente administrativo a Secretaria General y emita el acto administrativo resolutivo según corresponda;

Que, el inciso 4.1 del artículo 4 de la Ley N.º 28687 Ley de Desarrollo y Complementaria de Formalización de La Propiedad Informal, Acceso al Suelo y Dotación de Servicios Básicos, señala: “Las Municipalidades Provinciales, en el ámbito de sus circunscripciones territoriales, asumen la competencia exclusiva y excluyente en materia de formalización de la propiedad informal, hasta la inscripción de los títulos de propiedad en el registro de predios”;

Que, el inciso 4.2 del artículo 4 de la Ley N.º 28687, modificado por el Artículo 3 de la Ley N.º 31560 señala: “Las municipalidades provinciales planifican, organizan y coordinan, en armonía con los planes de desarrollo urbano de cada localidad, el proceso de formalización de la propiedad informal mediante el reconocimiento, verificación y saneamiento físico legal de las posesiones informales, hasta la inscripción de los títulos u otros instrumentos en el Registro de Predios, de la Superintendencia Nacional de los Registros Públicos (SUNARP)”;

Que, el inciso 4.3 del artículo 4 del mismo cuerpo normativo señala: “Corresponde al alcalde provincial, en el ámbito de su circunscripción territorial, suscribir los títulos de propiedad y los demás instrumentos de formalización”;

Que, el numeral 5.1 del artículo 5 de la Ley N.º 28687 señala posesiones informales: A los denominados asentamientos humanos, pueblos jóvenes, barrios marginales, barriadas, programas de vivienda municipales, centros poblados y toda otra forma de posesión, ocupación o titularidad informal de predios con fines urbanos, cualquiera sea su denominación, siempre que presenten las características establecidas en el Reglamento de Formalización de la Propiedad, aprobado mediante Decreto Supremo N.º 013-99-MTC;

Que, el Decreto Legislativo N.º 803 Ley de Promoción del Acceso a la Propiedad Formal, se declaró de interés nacional la promoción del acceso a la propiedad formal y su inscripción registral con el fin de garantizar los derechos de todos los ciudadanos a la propiedad y al ejercicio de la iniciativa privada en una economía social de mercado;

Que, el Texto Único de Procedimientos Administrativos TUPA de la Municipalidad Provincial de Anta, aprobado mediante #data.ordenanza_tupa, los requisitos solicitados y presentados son los siguientes:

#v(0.15cm)
#tabla_tupa(data.tupa_6, data.tupa_7, data.tupa_8, size: 9pt, booktabs: true)
#v(0.15cm)

Que, mediante INFORME LEGAL N.º #data.num_legal\-#data.anio\-GAL-MPA de fecha #data.fecha_legal, la Gerencia de Asesoría Legal, opina por LA VIABILIDAD LEGAL Y PROCEDENCIA de la formalización a favor de #data.titulares_res del predio ubicado en la #data.sector Mz. “#data.mz” Lote #data.lote, del distrito y provincia de #data.provincia, departamento del #data.departamento;

Que, teniendo en cuenta el Principio de Legalidad, del debido procedimiento administrativo y principio de buena fe procedimental, corresponde en sede de instancia resolver los actuados conforme a los documentos que obran en el expediente administrativo y a las opiniones técnicas y legales que obran en autos, las mismas que tienen sustento conforme a las facultades delegadas a los funcionarios y servidores que las suscriben;

Estando a los documentos del Visto; y

En uso de las atribuciones conferidas por el inciso 6 del artículo 20 de la Ley N.º 27972, Ley Orgánica de Municipalidades, que establece que el alcalde tiene la facultad de ejercer la representación legal de la municipalidad;

*SE RESUELVE:*

*ARTICULO PRIMERO. - DISPONER* el OTORGAMIENTO DE TITULO DE PROPIEDAD a favor de #data.titulares_res, según Partida Registral N.º PE. #data.partida SUNARP Lote #data.lote Mz. #data.mz de la #data.sector del distrito de #data.distrito, provincia de #data.provincia del departamento de #data.departamento, tal como se establece en el INFORME N°#data.num_sgpuat\-#data.anio\-SGPUAT-GDUR-MPA, emitida por la Subgerencia de Planeamiento Urbano y Acondicionamiento Territorial.

*ARTICULO SEGUNDO. - DISPONER*, a la Oficina de Secretaria General de la Municipalidad Provincial de Anta, realizar los trámites correspondientes para la emisión del Título de Propiedad, teniendo en cuenta el INFORME N°#data.num_sgpuat\-#data.anio\-SGPUAT-GDUR-MPA, emitida por la Subgerencia de Planeamiento Urbano y Acondicionamiento Territorial.

*ARTICULO TERCERO. - TRANSCRIBIR*, la presente Resolución a la Gerencia Municipal, Gerencia de Desarrollo Urbano y Rural, #data.interesado_notif y demás áreas pertinentes para su conocimiento y fines de Ley.

*ARTICULO CUARTO. - DISPONER*, a la Subgerencia de Tecnologías de Información la publicación de la presente resolución en el portal web institucional.

#v(0.4cm)
#set par(first-line-indent: 0pt)
#align(center)[*REGISTRESE, COMUNÍQUESE Y PUBLIQUESE.*]
