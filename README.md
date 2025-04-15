# Scanner360: Visualización y Análisis de Datos

⚠ Importante:
Scanner360 es una herramienta corporativa, por lo que no tiene acceso público. Para solucionar esta limitación, se han incorporado animaciones originales y se han modificado los nombres de las tablas para garantizar la confidencialidad de la información.

## 📌 Contexto de la Herramienta
__Scanner360__ es una herramienta desarrollada para _Caja Los Andes_, empresa chilena de carácter público-privado con más de 3.000 trabajadores. Permite a sus ejecutivos gestionar las mas de **50.000 empresas afiliadas** y más de **4 millones de trabajadores**, resolviendo la falta de sistematización en plataformas internas y proporcionando una **visión integral** de los clientes mediante:  

* Indicadores de gestión
* Indicadores de Bienestar
* Indicadores demográficos

Esta estructura facilita la toma de decisiones estratégicas y fortalece la relación con las empresas afiliadas.

--- 

## ⚙️ Descripción General
Scanner360 fue desarrollado en __SQL__ sobre __BigQuery (GCP)__. La generación de indicadores se basa en múltiples fuentes de datos, tanto internas como externas a Caja Los Andes. Para ello, se utiliza la automatización de procesos __ELT/API__ para la carga de datos en BigQuery, lo que permite ejecutar consultas programadas y generar un __panel 100% automatizado en Looker Studio__.

Los indicadores se construyen desde el identificador único de cada ciudadano (rut persona) para garantizar la trazabilidad y confiabilidad de la información. Luego de un proceso de transformacion, se resumen los datos de los trabajadores para obtener indicadores por cada empresa. Finalmente se consolidan estos indicadores en un __maestro empresas__.

A partir de este maestro, se desarrollaron tres tipos de análisis clave para la gestión de clientes empresariales:
* Scanner Cartera
* Caracterización
* Scanner Empresas (Aperturado en Holding, Centro de Cotización y Dar Cuenta)

---

## 🔎 Funcionalidades Clave  
### 🔹 Scanner Cartera  
Esta herramienta permite priorizar las empresas según su nivel de criticidad para ser atendidas. La priorización se basa en una lógica de puntajes considerando indicadores clave de bienestar, tales como:

* Cantidad, calidad, tipo, y satisfacción de visitas de los ejecutivos. 
* Bloqueo de crédito
* Modelo de clúster cercanía/lejanía
* Modelo de propensión de fuga
* Alertas levantadas por ejecutivos y notificaciones externas (Estados de Vigilancia)
  
Incorpora filtros por cada agente que maneja grupos de empresas, desde el nivel ejecutivo, pasando por sucursal y líder de gestión.

[CODIGO SCANNER CARTERA](https://github.com/WilliamDerby/Dashboard-Scanner360/blob/main/Codigos/Scanner%20Cartera.sql)

![GIF SCANNER CARTERA](https://github.com/WilliamDerby/Dashboard-Scanner360/blob/main/GIFs/Scanner%20Cartera2.gif)

---

### 🔹 Caracterización 
Herramienta que centraliza **datos demográficos, uso de beneficios, productos y canales** para estrategias segmentadas  

[CODIGO CARACTERIZACION AFILIADOS](https://github.com/WilliamDerby/Dashboard-Scanner360/blob/main/Codigos/Codigo%20Caracterizacion.sql)

![GIF CARACTERIZACION](https://github.com/WilliamDerby/Dashboard-Scanner360/blob/main/GIFs/Caracterizacion.gif)

---

### 🔹 Scanner Empresas  
Dashboard que presenta inicialmente un resumen de los principales __indicadores de bienestar__ y, posteriormente, __indicadores de gestión__ por empresa.
Para ofrecer un marco de comparación, se genera un indicador de referencia basado en trabajadores de la misma región y rubro, permitiendo evaluar si una empresa está por encima o por debajo de su entorno. Se miden indicadores como:
* Stock de productos financieros
* Penetración de beneficios sociales
* Penetración de canales digitales
* Morosidad de créditos

Adicionalmente, se han desarrollado dashboards para:
* Scanner Holding: Visualización de empresas con gestión centralizada
* Holding Centro de Cotización: Empresas con subdivisiones internas que requieren gestiones diferenciadas

[CODIGO CALCULO INDICADOR PENETRACION BENEFICIOS](https://github.com/WilliamDerby/Dashboard-Scanner360/blob/main/Codigos/Penetracion%20Beneficios%20por%20Empresa%20y%20Segmento.sql)

![GIF SCANNER EMPRESAS](https://github.com/WilliamDerby/Dashboard-Scanner360/blob/main/GIFs/Scanner%20Empresas2.gif)

---

 ### 🔹 Análisis Detallado de Indicadores  
Cada indicador tiene un dashboard específico con mayor nivel de detalle y filtros avanzados  

[CODIGO CONSOLIDADO USO BENEFICIOS](https://github.com/WilliamDerby/Dashboard-Scanner360/blob/main/Codigos/Consolidado%20Uso%20Beneficios.sql)

![GIF DETALLE SCANNER](https://github.com/WilliamDerby/Dashboard-Scanner360/blob/main/GIFs/Detalle%20Scanner.gif)

---

### 🔹 Dar Cuenta  
Tras la implementación de Scanner360, los ejecutivos identificaron la necesidad de compartir indicadores clave con las empresas. Dado que algunos datos son sensibles, se consolidó una vista resumida y estandarizada, destacando los indicadores más relevantes de cada empresa y sus afiliados en relación con la propuesta de valor de Caja Los Andes.

Fue presentado al **85% de las 13.000 empresas** con ejecutivo asignado en 2024.

![GIF DAR CUENTA](https://github.com/WilliamDerby/Dashboard-Scanner360/blob/main/GIFs/Dar%20Cuenta.gif)

---

## 📅 Plan de Trabajo (Ejecución 2025)
Durante la implementación del _Dar Cuenta_, se solicitó a los ejecutivos recopilar respuestas a dos preguntas clave:
* ¿Cuál es la principal necesidad de sus trabajadores?
* ¿Cuál es la principal necesidad de recursos humanos?
  
Actualmente se esta desarrollando:
* Desarrollo de un **pack de tres indicadores clave** por empresa basado en necesidades detectadas
* Seguimiento automatizado en **Scanner360**  

(Incorporar Visualizacion)

