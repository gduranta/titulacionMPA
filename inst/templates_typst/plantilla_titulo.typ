#import "estilo_comun.typ": *

#let data = json(sys.inputs.at("json_file"))

#set page(
  paper: "a4",
  margin: (top: 3.0cm, bottom: 1.5cm, left: 3.0cm, right: 1.75cm),
  footer-descent: 0.6cm,
  footer: pie_folio()
)

#show: aplicar_texto_base.with(size: 11pt, leading: 0.62em, spacing: 0.95em, indent: 1.0cm)

#align(center)[
  #text(size: 14pt, weight: "bold")[
    #underline(offset: 2pt)[TÍTULO DE PROPIEDAD N. º#data.corr\-#data.anio –A-MPA-C]
  ]
]
#v(0.35cm)

LA MUNICIPALIDAD PROVINCIAL DE ANTA, representada por su Alcalde Sr. #data.alcalde, identificado con D.N.I N.º #data.dni_alc, con domicilio legal #data.dom_leg, en virtud de lo dispuesto en la Ley N.° 27972 "Ley Orgánica de Municipalidades" y la Ley N.° 28687 "Ley de Desarrollo y Complementaria de Formalización de la Propiedad Informal, Acceso al Suelo y Dotación de Servicios Básicos", y en uso de sus facultades de formalización de la Propiedad Informal; procede a la Declaración de Propiedad por FORMALIZACIÓN DE PREDIO INICIADO POR LA MUNICIPALIDAD PROVINCIAL DE ANTA, por lo que se emite el presente TÍTULO DE PROPIEDAD, en los términos y condiciones siguientes:

*PRIMERO.* - #data.txt_primero

*SEGUNDO.* - La Municipalidad Provincial de Anta, es propietaria de la superficie del LOTE N.° #data.lote de la Manzana “#data.mz” de la #data.sector ubicado en el distrito y provincia de ANTA, departamento de CUSCO, tiene acreditado e inscrito su dominio en la Partida Electrónica N.° #data.partida del Registro de Propiedad Inmueble de la Zona Registral N.° X de la Superintendencia Nacional de los Registros Públicos – Oficina Cusco, conforme al contenido de la Resolución de Alcaldía N.º#data.num_res, de fecha #data.fecha_res.

*TERCERO.* - En virtud a lo dispuesto en la Ley N.° 27972 – Ley Orgánica de Municipalidades, Ley N.º 28687- “Ley de Desarrollo y Complementaria de Formalización de la Propiedad Informal, Acceso al Suelo y Dotación de Servicios Básicos”, Decreto Supremo N°006-2006-VIVIENDA-Reglamento del Título I de la Ley N°28687, referido a la Formalización de la Propiedad Informal de Terrenos Ocupados por Posesiones Informales, Centros Urbanos Informales y Urbanizaciones Populares, y en aplicación del Decreto Supremo N°004-85.VC, Reglamento de Adjudicación de Terrenos Fiscales para Fines Urbanos, Ley N°31056 y su reglamento D.S. N°002-2021-VIVIENDA, se crea un régimen temporal extraordinario de formalización y titulación de predios urbanos, el cual tiene una vigencia hasta el 31 de diciembre del 2026. Asimismo, mediante la Ley N°32267 amplía por última vez hasta el 31 de diciembre de 2021 los plazos establecidos en las leyes 28687 y 31056 para la formalización de terrenos estatales ocupados por posesiones informales, D.S. N°005-2026-VIVIENDA, Decreto Supremo que modifica el Reglamento del Título I de la Ley N°28687, Ley de desarrollo y complementaria de formalización de la propiedad informal, acceso al suelo y dotación de servicios básicos y que el Texto Único de Procedimientos Administrativos TUPA de la Municipalidad Provincial de Anta, aprobado mediante #data.ordenanza_tupa; por el cual, la Municipalidad Provincial de Anta, está facultada para legalizar la transferencia de la propiedad de los predios a favor de los solicitantes que reúnan los requisitos de ley. Por lo que emite el presente en los términos y condiciones siguientes.

*CUARTO.* – #data.txt_cuarto_tit

Habiendo cumplido además con los requisitos establecidos por el Texto Único de Procedimiento Administrativo (TUPA) de la Municipalidad Provincial de Anta, por lo que #data.txt_cuarto_otorga correspondiente al predio Lote N.° #data.lote de la Manzana “#data.mz” de la #data.sector del distrito y provincia de ANTA, departamento de CUSCO, cuyas características se señalan en la cláusula quinta.

*QUINTO.* - El Predio materia de este TÍTULO tiene las siguientes características técnicas:

#set par(first-line-indent: 0pt)
#pad(left: 0.6cm)[
  - Partida Electrónica N.° #data.partida
  - El Predio está ubicado en el Lote N.° #data.lote de la Manzana ”#data.mz”
  - Área del Terreno = #data.area m2
  - Perímetro = #data.perimetro m.
  - Linderos y colindantes:
]

#par(first-line-indent: 1.0cm)[#data.txt_frente]

#par(first-line-indent: 1.0cm)[#data.txt_fondo]

#par(first-line-indent: 1.0cm)[#data.txt_derecha]

#par(first-line-indent: 1.0cm)[#data.txt_izquierda]

#set par(first-line-indent: (amount: 1.0cm, all: true))

*SEXTO.* - Para los efectos legales a que se contrae esta transferencia de predio de terreno, se otorga el presente Título de Propiedad, de conformidad al Expediente Administrativo N.° #data.expediente en el cual solicita FORMALIZACIÓN DE PREDIO.

*SEPTIMO.* - La Transferencia #data.txt_septimo_adj comprende el predio de terreno, con todo y cuanto por derecho sea inherente, sus usos, costumbres y servidumbres, sometiéndose además a las disposiciones legales.

OCTAVO. - Conforme a la Ley, es condición indispensable que el inmueble al momento de la adjudicación sea la única propiedad destinada a vivienda o lugar de trabajo #data.txt_octavo_tit. De comprobarse la contravención a la presente, quedará resuelto automáticamente este contrato y en consecuencia el bien inmueble revertirá al dominio de la Municipalidad Provincial De Anta

*NOVENO.* - No habiendo mediado vicio de voluntad que enerven los efectos del presente acto jurídico, ambas partes nos ratificamos en todas y cada una de las precedentes cláusulas, renunciando a cualquier acción y/o excepción derivada de vicio de voluntad dentro o fuera de juicio.

El presente *TÍTULO DE PROPIEDAD* constituye merito suficiente para su inscripción en la Superintendencia Nacional de Registros Públicos Oficina Registral Cusco.

Firmado en la ciudad de Anta a los #data.dia días del mes de #data.mes del #data.anio_letras.

#set par(first-line-indent: 0pt)
#v(2.0cm)

#align(center)[
  #box(width: 6.5cm)[
    #line(length: 100%, stroke: 0.5pt)
    #v(0.25em)
    *ALCALDE* \
    Municipalidad Provincial De Anta
  ]
]

#let n_tit = int(data.n_tit)

#if n_tit == 1 [
  #v(2.0cm)
  #align(center)[
    #box(width: 6.5cm)[
      #line(length: 100%, stroke: 0.5pt)
      #v(0.25em)
      *TITULAR*
    ]
  ]
] else [
  #let k = 1
  #while k <= n_tit {
    v(2.0cm)
    if k + 1 <= n_tit {
      grid(
        columns: (1fr, 1fr),
        gutter: 1.5cm,
        align(center)[
          #line(length: 5.5cm, stroke: 0.5pt)
          #v(0.25em)
          *TITULAR #k*
        ],
        align(center)[
          #line(length: 5.5cm, stroke: 0.5pt)
          #v(0.25em)
          *TITULAR #(k + 1)*
        ]
      )
    } else {
      align(center)[
        #box(width: 6.5cm)[
          #line(length: 100%, stroke: 0.5pt)
          #v(0.25em)
          *TITULAR #k*
        ]
      ]
    }
    k = k + 2
  }
]
