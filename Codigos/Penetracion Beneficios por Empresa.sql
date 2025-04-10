CREATE OR REPLACE TABLE TABLA_PENETRACION_BENEFICIOS_POR_EMPRESA AS

--Llamado a base consolidado de uso de beneficios, solo afiliacion tipo trabajadores
with base as (
select *
from TABLA_USO_BENEFICIOS_EMPRESAS2 
where Tipo_Afiliado = "Activo"),

--Asignacion de periodos que seran usados para calcular penetracion
periodo_penetracion as (
select Periodo_OK as Periodo_Penetracion
from base
where  Periodo_OK > '2019-12-01'
group by Periodo_OK),

--Ingreso de datos de los ultimos 12 meses para cada mes que se requiere calcular penetracion
base_datos_por_periodo_penetracion as (
select *
from periodo_penetracion as a
left join base as b
on b.Periodo_OK between date_add(a.Periodo_Penetracion, interval -11 month) and a.Periodo_Penetracion),

--Resumen de data en periodo y rut persona, incorporando marca para utilizar en calculo de indicador
marca_penetracion_rut as (
select Periodo_Penetracion,RutPersona,if(max(Beneficio) is null,0,1) as marca_penetracion_periodo
from base_datos_por_periodo_penetracion 
--where beneficio is not null
group by Periodo_Penetracion,RutPersona),

--Base completa y unica de periodo/persona/empresa
base_periodo_empresa_afiliado as (
select Periodo_OK,RutEmpresa,RutPersona
from base 
group by Periodo_OK,RutEmpresa,RutPersona),

--Incorporacion de marca penetracion a consolidado
marca_penetracion_periodo_empresa_afiliado as (
select a.*,b.marca_penetracion_periodo
from (select * from base_periodo_empresa_afiliado where Periodo_OK > '2020-12-31') as a
left join marca_penetracion_rut as b
on concat(a.Periodo_OK,"-",a.RutPersona) = concat(b.Periodo_Penetracion,"-",b.RutPersona)),

--Ultimo registro de empresa para homologar datos de region y rubro, que se usaran para segmentar
Ultimo_Registro_Empresa as (
SELECT Periodo,RutEmpresa,REGION_EMPRESA_AJUSTADO,Rubro_Empresa,Peso_Empresa_Segmento
FROM (SELECT *, 
ROW_NUMBER() OVER (PARTITION BY RutEmpresa ORDER BY Periodo DESC) as RN  
FROM TABLA_MAESTRO_EMPRESAS) 
WHERE RN = 1),

--Incorporacion de datos para segmentar en consolidado
datos_segmentacion_empresa_ultimo_periodo as (
select a.*,b.REGION_EMPRESA_AJUSTADO,b.Rubro_Empresa,b.Peso_Empresa_Segmento
from marca_penetracion_periodo_empresa_afiliado as a
left join Ultimo_Registro_Empresa as b
on a.RutEmpresa = b.RutEmpresa),

--Indicadores de segmento para empresas con segmento rubro/region
estadisticas_segmento_penetracion_RUBRO_REGION as (
SELECT Periodo_OK,Rubro_Empresa,REGION_EMPRESA_AJUSTADO,
count(distinct(case when marca_penetracion_periodo = 0 
then null else RutPersona end)) / count(distinct(RutPersona)) as Penetracion_Segmento_Periodo_RUBRO_REGION,
count(distinct(RutEmpresa)) as N_Empresas_Segmentoo_RUBRO_REGION
FROM datos_segmentacion_empresa_ultimo_periodo
GROUP BY Periodo_OK,Rubro_Empresa,REGION_EMPRESA_AJUSTADO),

--Indicadores Penetracion de segmento para empresas con segmento region
estadisticas_segmento_penetracion_SOLO_REGION as (
SELECT Periodo_OK,REGION_EMPRESA_AJUSTADO,
count(distinct(case when marca_penetracion_periodo = 0 
then null else RutPersona end)) / count(distinct(RutPersona)) as Penetracion_Segmento_Periodo_SOLO_REGION,
count(distinct(RutEmpresa)) as N_Empresas_Segmento_SOLO_REGION
FROM datos_segmentacion_empresa_ultimo_periodo
GROUP BY Periodo_OK,REGION_EMPRESA_AJUSTADO),

--Indicadores Penetracion de segmento para empresas con segmento rubro
estadisticas_segmento_penetracion_SOLO_RUBRO as (
SELECT Periodo_OK,Rubro_Empresa,
count(distinct(case when marca_penetracion_periodo = 0 
then null else RutPersona end)) / count(distinct(RutPersona)) as Penetracion_Segmento_Periodo_SOLO_RUBRO,
count(distinct(RutEmpresa)) as N_Empresas_Segmento_SOLO_RUBRO
FROM datos_segmentacion_empresa_ultimo_periodo
GROUP BY Periodo_OK,Rubro_Empresa),

--Indicadores Penetracion de segmento para empresas con segmento Fuenzas Armadas
estadisticas_segmento_penetracion_FAOS as (
SELECT Periodo_OK,
count(distinct(case when marca_penetracion_periodo = 0 
then null else RutPersona end)) / count(distinct(RutPersona)) as Penetracion_Segmento_Periodo_FAOS,
count(distinct(RutEmpresa)) as N_Empresas_Segmento_FAOS
FROM datos_segmentacion_empresa_ultimo_periodo
where Rubro_Empresa in ('Ejercito','PDI','Armada','Carabineros','Otros FAOS')
GROUP BY Periodo_OK),

--Indicador de penetracion por empresa
penetracion_por_empresa as (
select Periodo_OK as Periodo_Penetracion,RutEmpresa,Rubro_Empresa,REGION_EMPRESA_AJUSTADO,max(Peso_Empresa_Segmento) as Peso_Empresa_Segmento,
sum(marca_penetracion_periodo)/count(*) as Penetracion_Empresa_Periodo
from datos_segmentacion_empresa_ultimo_periodo
group by Periodo_OK,RutEmpresa,Rubro_Empresa,REGION_EMPRESA_AJUSTADO),

--Consolidado final que captura el tipo de segmento con el que se debe comparar la empresa y el indicador de penetracion por empresa 
base_y_estadisticos_de_segmento_penetracion as (
SELECT a.*,
case when a.Rubro_Empresa in ('Ejercito','PDI','Armada','Carabineros','Otros FAOS') then e.Penetracion_Segmento_Periodo_FAOS
when a.Peso_Empresa_Segmento <= 0.3 then b.Penetracion_Segmento_Periodo_RUBRO_REGION
when a.Peso_Empresa_Segmento > 0.3 and (a.REGION_EMPRESA_AJUSTADO = 'Region Metropolitana'
or a.REGION_EMPRESA_AJUSTADO is null) then d.Penetracion_Segmento_Periodo_SOLO_RUBRO
when a.Peso_Empresa_Segmento > 0.3 then c.Penetracion_Segmento_Periodo_SOLO_REGION
end as Penetracion_Segmento_Periodo,

b.Penetracion_Segmento_Periodo_RUBRO_REGION,
d.Penetracion_Segmento_Periodo_SOLO_RUBRO,
c.Penetracion_Segmento_Periodo_SOLO_REGION,
e.Penetracion_Segmento_Periodo_FAOS,

FROM penetracion_por_empresa as a
left join estadisticas_segmento_penetracion_RUBRO_REGION as b
on concat(a.Periodo_Penetracion,a.Rubro_Empresa,a.REGION_EMPRESA_AJUSTADO) 
= concat(b.Periodo_OK,b.Rubro_Empresa,b.REGION_EMPRESA_AJUSTADO)

left join estadisticas_segmento_penetracion_SOLO_REGION as c
on concat(a.Periodo_Penetracion,a.REGION_EMPRESA_AJUSTADO) 
= concat(c.Periodo_OK,c.REGION_EMPRESA_AJUSTADO)

left join estadisticas_segmento_penetracion_SOLO_RUBRO as d
on concat(a.Periodo_Penetracion,a.Rubro_Empresa) 
= concat(d.Periodo_OK,d.Rubro_Empresa)

left join estadisticas_segmento_penetracion_FAOS as e
on a.Periodo_Penetracion = e.Periodo_OK)

--Resumen final respecto al estado de la empresa con respecto a su segmento + incorporacion de datos para filtros de dashboard
select *,RutEmpresa as RUT_EMP,
if(Periodo_Penetracion = (select max(Periodo_Penetracion) from base_y_estadisticos_de_segmento_penetracion),1,0) as Marca_Ultimo_Periodo,
case when Penetracion_Empresa_Periodo >= Penetracion_Segmento_Periodo*1.05 then "Sobre Promedio Segmento"
when Penetracion_Empresa_Periodo >= Penetracion_Segmento_Periodo*0.95 then "Similar Promedio Segmento"
when Penetracion_Empresa_Periodo < Penetracion_Segmento_Periodo*0.95 then "Bajo Promedio Segmento"
else "Revisar" end as cumplimiento,

if(Periodo_Penetracion<=date_add((select max(Periodo_Penetracion) from base_y_estadisticos_de_segmento_penetracion),interval -1 month),1,0) as Marca_Periodo_Penultimo_Periodo,
if(Periodo_Penetracion=date_add((select max(Periodo_Penetracion) from base_y_estadisticos_de_segmento_penetracion),interval -1 month),1,0) as Marca_Penultimo_Periodo,

from base_y_estadisticos_de_segmento_penetracion
