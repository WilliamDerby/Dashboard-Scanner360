# Contexto Herramienta
__Scanner360__ es una herramienta de visualización y análisis de datos desarrollada para _Caja Los Andes_, una empresa chilena de carácter público-privado con más de 3.000 trabajadores. Su modelo de negocio se basa en la afiliación de empresas, permitiendo que sus trabajadores accedan a una amplia gama de productos financieros y beneficios. Actualmente, cuenta con aproximadamente 60.000 empresas afiliadas, representando a más de 4 millones de trabajadores.

El usuario final de la herramienta son los ejecutivos de _Caja Los Andes_, quienes se relacionan directamente con los gerentes de recursos humanos y sindicatos de las empresas afiliadas. A cada ejecutivo se le asigna una cartera de empresas con las que trabaja en conjunto para mejorar la calidad de vida de sus trabajadores a través de los beneficios y productos ofrecidos.

Gracias a una disposición simplificada de indicadores, __Scanner360__ permite a los ejecutivos obtener una visión integral de la situación de sus clientes, analizando aspectos clave como:

* Indicadores de gestión.
* Uso de canales y productos.
* Niveles de satisfacción.
* Resumen demográfico.

Esta estructura facilita la toma de decisiones estratégicas y mejora la relación con las empresas afiliadas.

# Descripción general
__Scanner360__ fue desarrollado en SQL sobre la plataforma BigQuery de GCP. La generación de indicadores se basa en diversas fuentes de datos, tanto internas como externas a _Caja los Andes_. Para ello, se aprovecha la automatización de las áreas de TI en la carga de datos a BigQuery mediante API y procesos ELT, lo que permite ejecutar consultas programadas y lograr un panel 100% automatizado. La visualización de gráficos e indicadores se realiza en Looker Studio.

Como base del sistema, se creó un "maestro de empresas" (dejar consulta linkeada), que consolida mensualmente el cierre de cada empresa para todos los indicadores. Esta tabla actúa como un repositorio final de datos, permitiendo analizar su evolución en el tiempo.

A partir de este maestro, se desarrollaron tres tipos de análisis que facilitan la gestión de la cartera de clientes empresariales en distintos ámbitos:
* Scanner Cartera
* Scanner Empresas, Holding, Centro de Cotización y Dar Cuenta
* Caracterización

__Dado que Scanner360 es una herramienta de uso corporativo, el acceso libre a Looker Studio no es posible. Para solucionar esta limitación, se han incorporado animaciones originales. Además, en las lógicas compartidas para la creación de indicadores, se han modificado los nombres de las tablas para garantizar la confidencialidad de la institución.__

# Scanner Cartera
![Prueba GIF Scanner](https://raw.githubusercontent.com/WilliamDerby/Dashboard-Scanner360/refs/heads/main/GIFs/PruebaScanner2.gif)
