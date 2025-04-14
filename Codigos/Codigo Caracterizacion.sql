CREATE OR REPLACE TABLE TABLA_CARACTERIZACION_AFILIADOS AS

--BASE DE ASIGNACION AFILIADOS PERSONA/EMPRESA/PERIODO
with base_afiliados as (
select DATE_SUB(DATE(CAST(SUBSTR(CAST(PERIODO_SK AS STRING),1,4) AS INT),CAST(SUBSTR(CAST(PERIODO_SK AS STRING),5,6) AS INT),1),INTERVAL 0 MONTH) as PERIODO_OK,
PERIODO_SK,PER_RUT,NOMBRE_AFILIADO,cast(FECHA_NACIMIENTO as date) as FECHA_NACIMIENTO,SEXO,CARGAS_FAMILIARES,
FECHA_AFILIACION,REGION_CASA_MATRIZ,RENTA_IMPONIBLE,PREVISION,  
case
when TIPO_AFILIADO in ("TRABAJADOR INDEPENDIENTE","TRABAJADOR SECTOR PRIVADO","TRABAJADOR SECTOR PÚBLICO") 
then "Activo" else "Pensionado" end as Tipo_Afiliado,
cast(substr(trim(RUT_EMP_ENT_PAGADORA),1,length(trim(RUT_EMP_ENT_PAGADORA))-2) as int) AS RUT_EMP,
SEM_SUCEMP
from TABLA_ASIGNACION_PERSONA_EMPRESA),


--REGISTRO PERIODICO POR PERSONA DE DATOS DEMOGRAFICOS
afiliados_totales as (
SELECT PERIODO_SK,RutPersona,Ciclo_Vida,Generacion,ISE,GSE
FROM (SELECT *, 
ROW_NUMBER() OVER (PARTITION BY concat(PERIODO_SK,"-",RutPersona) ORDER BY PERIODO_SK DESC) as RN  
FROM TABLA_MENSUAL_DATOS_DEMOGRAFICOS) WHERE RN = 1),


--REGISTRO PERIODICO POR PERSONA DE DATOS DEMOGRAFICOS ADICIONALES
CLA_AFILIADO as (
SELECT PERIODO_SK,RUT_PERSONA,COMUNA_PERSONA,CIUDAD_PERSONA,
case when trim(REGION_PERSONA) = "" then null
else trim(REGION_PERSONA) end as REGION_PERSONA,
ESTADO_CIVIL,CODIGO_OF_VIRTUAL
FROM (SELECT *, 
ROW_NUMBER() OVER (PARTITION BY concat(PERIODO_SK,"-",RUT_PERSONA) ORDER BY RENTA_IMPONIBLE DESC) as RN  
FROM TABLA_NO_MENSUAL_DATOS_DEMOGRAFICOS) WHERE RN = 1),


--INCORPORACION DATOS DEMOGRAFICOS A BASE DE AFILIADOS
datos_demograficos as (
select a.*,c.SubSegmentoA,c.RazonSocial,
date_diff(PERIODO_OK,cast(FECHA_NACIMIENTO as date),MONTH)/12 as EDAD,
date_diff(PERIODO_OK,cast(FECHA_AFILIACION as date),MONTH)/12 as ANTIGUDAD_LABORAL_MESES,
b.Ciclo_Vida,b.Generacion,if(b.ISE is null,b.GSE,b.ISE) as Estrato_Social,
d.COMUNA_PERSONA,d.CIUDAD_PERSONA,d.REGION_PERSONA,d.ESTADO_CIVIL,d.CODIGO_OF_VIRTUAL,
e.REGION_EMPRESA_AJUSTADO,e.SEGMENTO_EJECUTIVO,e.Marca_Carterizado,e.RUT_HOLDING,
f.Rotacion12M

from base_afiliados  as a

left join afiliados_totales as b
on concat(a.PERIODO_SK,"-",a.PER_RUT) = concat(b.PERIODO_SK,"-",b.RutPersona)

left join TABLA_RUBROS_EMPRESAS as c
on a.RUT_EMP = c.Rut_Empresa

left join CLA_AFILIADO as d
on concat(a.PERIODO_SK,"-",a.PER_RUT) = concat(d.PERIODO_SK,"-",d.RUT_PERSONA)

left join TABLA_MAESTRO_EMPRESAS as e
on concat(a.PERIODO_SK,"-",a.RUT_EMP) = concat(e.PERIODO,"-",e.RUT_EMPRESA)

left join TABLA_INDICADORES_ROTACION as f
on concat(a.PERIODO_SK,"-",a.RUT_EMP) = concat(f.periodo,"-",f.RutEmpresa)),

-------------------FIN DATOS DEMOGRAFICOS--------------------------------------------------

--ULTIMA VISITA APP MOVIL
ultima_visita_APP as (
select rut_persona,max(fecha_visita) as ultima_visita_APP
FROM TABLA_USO_CANALES_DIGITALES
where (case when Canal = 'SVP' then "MS" else Canal end) = 'APP'
group by rut_persona),

--ULTIMA INTERACCION CANAL WHATSAPP
ultima_visita_WSP as (
select rut_persona,max(fecha_visita) as ultima_visita_WSP
FROM TABLA_USO_CANALES_DIGITALES
where (case when Canal = 'SVP' then "MS" else Canal end) = 'WSP'
group by rut_persona),

--ULTIMA VISITA A SUCURSAL
ultima_visita_SUC as (
select rut_persona_visita,max(Fecha_visita) AS ultima_visita_SUC
FROM TABLA_VISITAS_SUCURSAL
group by rut_persona_visita),

--ULTIMA VISITA PAGINA WEB PRIVADA
ultima_visita_MS as (
select rut_persona,max(fecha_visita) AS ultima_visita_MS
FROM TABLA_USO_CANALES_DIGITALES
where (case when Canal = 'SVP' then "MS" else Canal end) = 'MS'
group by rut_persona),

--BASE UNICA DE PERSONAS
rut_totales as (
SELECT PER_RUT
FROM datos_demograficos
group by PER_RUT),

--CONSOLIDADO RUT UNICO 
consolidado_penetracion_canales as (
select a.*,
if(b.ultima_visita_APP>date_add(current_date,interval -12 month),1,0) as Marca_Penetracion_APP,
if(c.ultima_visita_WSP>date_add(current_date,interval -12 month),1,0) as Marca_Penetracion_WSP,
if(d.ultima_visita_SUC>date_add(current_date,interval -12 month),1,0) as Marca_Penetracion_SUC,
if(e.ultima_visita_MS >date_add(current_date,interval -12 month),1,0) as Marca_Penetracion_MS,
from rut_totales as a
left join ultima_visita_APP as b
on a.PER_RUT = b.rut_persona
left join ultima_visita_WSP as c
on a.PER_RUT = c.rut_persona
left join ultima_visita_SUC as d
on a.PER_RUT = d.rut_persona_visita
left join ultima_visita_MS as e
on a.PER_RUT = e.rut_persona),

--INCORPORACION DE INDICADORES USO CANALES DIGITALES A CONSOLIDADO DE PRINCIPAL DE AFILIADOS
final_uso_canales as (
SELECT a.*,b.Marca_Penetracion_APP,b.Marca_Penetracion_WSP,
b.Marca_Penetracion_SUC,b.Marca_Penetracion_MS,
if(PERIODO_OK = (select max(PERIODO_OK) from base_afiliados),1,0) as Marca_ultimo_periodo,
if(PERIODO_OK = date_add((select max(PERIODO_OK) from base_afiliados),interval -1 month),1,0) as Marca_penultimo_periodo,
if(PERIODO_SK = (select max(PERIODO_SK) from TABLA_DATOS_DEMOGRAFICOS_POR_PERIODO),1,0) as Marca_ultimo_periodo_afiliados_totales,
if(PERIODO_SK = (select max(PERIODO_SK) from TABLA_DATOS_DEMOGRAFICOS_SIN_PERIODO),1,0) as Marca_ultimo_periodo_CLA_AFILIADO,
if(PERIODO_SK = (select max(periodo) from TABLA_INDICADOR_ROTACION_EMPRESAS),1,0) as Marca_ultimo_periodo_rotacion_empresas
FROM datos_demograficos as a
LEFT JOIN consolidado_penetracion_canales as b
on a.PER_RUT = b.PER_RUT),

-------------------FIN USO CANALES--------------------------------------------------

--LLAMADO Y AJUSTE DE BASE USO DE BENEFICIOS 
AJUSTE_BBSS as (
select RutPersona,AnioMes,Tipo_Beneficio,Beneficio,
CASE 
WHEN Beneficio ='FARMACIAS SALCOBRAND' THEN 'MASIVO'
WHEN Beneficio ='ABASTIBLE' THEN 'MASIVO'
WHEN Beneficio ='FARMACIAS AHUMADA' THEN 'MASIVO'
WHEN Beneficio ='CRUZ VERDE' THEN 'MASIVO'
WHEN Beneficio ='CAMPANA FARMACIAS' THEN 'MASIVO'
ELSE "NO MASIVO" END AS BBSS_MASIVOS
from TABLA_USO_BENEFICIOS
where AnioMes > 202200),

--ULTIMO USO DE BENEFICIOS POR PERSONA
ultimo_uso_BBSS as (
select RutPersona,max(AnioMes) as ultimo_uso_BBSS
FROM AJUSTE_BBSS
group by RutPersona),

--ULTIMO USO DE BENEFICIOS NO MASIVO POR PERSONA
uso_no_masivo as (
select RutPersona,max(AnioMes) as ultimo_uso_no_masivo
FROM AJUSTE_BBSS
WHERE BBSS_MASIVOS != 'MASIVO'
group by RutPersona),

--CONSOLIDADO USO BENEFICIOS + NO MASIVOS
consolidado_beneficios as (
SELECT a.RutPersona,
if(date(cast(substr(cast(a.ultimo_uso_BBSS as string),1,4) as int),cast(substr(cast(a.ultimo_uso_BBSS as string),5,2) as int),1)
>date_add(current_date,interval -13 month),1,0) as Marca_Penetracion_BBSS,
if(date(cast(substr(cast(b.ultimo_uso_no_masivo as string),1,4) as int),cast(substr(cast(b.ultimo_uso_no_masivo as string),5,2) as int),1)
>date_add(current_date,interval -13 month),1,0) as Marca_Penetracion_bbss_no_masivos,
FROM ultimo_uso_BBSS AS a
left join uso_no_masivo as b
on a.RutPersona = b.RutPersona),

--INCORPORACION DE USO BENEFICIOS A CONSOLIDADO DE AFILIADOS
final_uso_beneficios as (
select a.*,b.Marca_Penetracion_BBSS,b.Marca_Penetracion_bbss_no_masivos
from final_uso_canales as a
left join consolidado_beneficios as b
on a.PER_RUT = b.RutPersona),

-------------------FIN USO BBSS--------------------------------------------------

--LLAMADO, CONSOLIDADO DE DIFERENTES FUENTES Y AJUSTE DE BASES STOCK VIGENTE DE PRODUCTOS 
base_PPFF_stock as 
(SELECT cast(BENEFICIARIO_RUT as int) as RUT_PERSONA,cast(PERIODO as int) as PERIODO
FROM TABLA_STOCK_CREDITO_POR_PERIODO
WHERE periodo = (select max(periodo) from TABLA_STOCK_CREDITO_POR_PERIODO)
union all
SELECT RUT_PERSONA,PERIODO
FROM TABLA_STOCK_AHORRO_POR_PERIODO
WHERE periodo = (select max(periodo) from TABLA_STOCK_AHORRO_POR_PERIODO)
and SALDO_PROVISORIO_PESOS > 0
union all
SELECT RUT_PERSONA,PERIODO
FROM TABLA_STOCK_CREDITO_HIPOTECARIO_POR_PERIODO
WHERE periodo = (select max(periodo) from TABLA_STOCK_CREDITO_HIPOTECARIO_POR_PERIODO)
union all
SELECT RUT_PERSONA,PERIODO
FROM TABLA_STOCK_SEGUROS_POR_PERIODO
WHERE periodo = (select max(periodo) from TABLA_STOCK_SEGUROS_POR_PERIODO)
union all
SELECT RutPersona,AnioMes
FROM (SELECT *, 
ROW_NUMBER() OVER (PARTITION BY concat(RutPersona,"-",Producto) ORDER BY ANIOMES DESC) as RN  
FROM (select * FROM TABLA_USO_PRODUCTOS_CONSOLIDADO
WHERE Producto in ("SOYFOCUS","TARJETA TAPP","PESOAPESO","PPC")
and PERIODO_OK > date_add(current_date,interval -13 month))) WHERE RN = 1),

--AGRUPACION FINAL DE PERSONAS QUE TIENEN AL MENOS UN PRODUCTOS VIGENTE
consolidado_stock_ppff as (
select RUT_PERSONA
from base_PPFF_stock 
group by RUT_PERSONA),

--INCORPORACION DE STOCK VIGENTE PRODUCTO A CONSOLIDADO DE AFILIADOS
final_STOCK_PPFF_1 AS (
select a.*,if(b.RUT_PERSONA is null,0,1) as Marca_ultimo_stock_ppff
from final_uso_beneficios as a
left join consolidado_stock_ppff as b
on a.PER_RUT = b.RUT_PERSONA),

-------------------FIN STOCK PPFF--------------------------------------------------

--LLAMADO, CONSOLIDADO DE DIFERENTES FUENTES Y AJUSTE DE BASES STOCK VIGENTE DE PRODUCTOS, ELIMINANDO BASE DE 1 PRODUCTO EN SEGUROS
base_PPFF_stock_ajustado_pensionados as 
(SELECT cast(BENEFICIARIO_RUT as int) as RUT_PERSONA,cast(PERIODO as int) as PERIODO
FROM TABLA_STOCK_CREDITO_VIGENTE
WHERE periodo = (select max(periodo) from TABLA_STOCK_CREDITO_VIGENTE)
union all
SELECT RUT_PERSONA,PERIODO
FROM TABLA_STOCK_AHORRO
WHERE periodo = (select max(periodo) from TABLA_STOCK_AHORRO)
and SALDO_PROVISORIO_PESOS > 0
union all
SELECT RUT_PERSONA,PERIODO
FROM TABLA_STOCK_CREDITO_HIPOTECARIO
WHERE periodo = (select max(periodo) from TABLA_STOCK_CREDITO_HIPOTECARIO)
union all
SELECT RUT_PERSONA,PERIODO
FROM TABLA_STOCK_SEGUROS
WHERE periodo = (select max(periodo) from TABLA_STOCK_SEGUROS)
and TIPO_DE_SEGURO != 'PSP SEGUROS'
union all
SELECT RutPersona,AnioMes
FROM (SELECT *, 
ROW_NUMBER() OVER (PARTITION BY concat(RutPersona,"-",Producto) ORDER BY ANIOMES DESC) as RN  
FROM (select * FROM TABLA_CONSOLIDADO_BENEFICIOS
WHERE Producto in ("SOYFOCUS","TARJETA TAPP","PESOAPESO","PPC")
and PERIODO_OK > date_add(current_date,interval -13 month))) WHERE RN = 1),

--AGRUPACION FINAL DE PERSONAS QUE TIENEN AL MENOS UN PRODUCTOS VIGENTE SIN CONSIDERAR 1 PRODUCTO DE SEGUROS
consolidado_stock_ppff_ajustado_pensionados as (
select RUT_PERSONA
from base_PPFF_stock_ajustado_pensionados 
group by RUT_PERSONA),

--INCORPORACION DE STOCK VIGENTE PRODUCTO A CONSOLIDADO DE AFILIADOS SIN CONSIDERAR 1 PRODUCTO DE SEGUROS
final_STOCK_PPFF AS (
select a.*,if(b.RUT_PERSONA is null,0,1) as Marca_ultimo_stock_ppff_ajustado_pensionados
from final_STOCK_PPFF_1 as a
left join consolidado_stock_ppff_ajustado_pensionados as b
on a.PER_RUT = b.RUT_PERSONA),

-------------------FIN STOCK PPFF JUSTADO PSP PENSIONADOS--------------------------------------------------

--LLAMADO, CONSOLIDADO DE DIFERENTES FUENTES Y AJUSTE DE BASES VENTA DE PRODUCTOS, ELIMINANDO BASE DE 1 PRODUCTO EN SEGUROS
venta_productos as (
SELECT RutPersona,AnioMes FROM (SELECT *, 
ROW_NUMBER() OVER (PARTITION BY concat(RutPersona,"-",Producto) ORDER BY ANIOMES) as RN  
FROM (select * FROM TABLA_CONSOLIDADO_BENEFICIOS
WHERE Producto in ("SOYFOCUS","TARJETA TAPP","PESOAPESO","PPC"))) WHERE RN = 1

union all

SELECT RUT_PERSONA,PERIODO FROM (SELECT *, 
ROW_NUMBER() OVER (PARTITION BY CUENTA_REGION_SUCURSAL_FOLIO ORDER BY PERIODO) as RN  
FROM TABLA_STOCK_AHORRO) WHERE RN = 1

union all

SELECT RUT_PERSONA,PERIODO FROM (SELECT *, 
ROW_NUMBER() OVER (PARTITION BY FOLIO_DEL_CREDITO ORDER BY PERIODO) as RN  
FROM TABLA_STOCK_CREDITO_HIPOTECARIO) WHERE RN = 1

union all

SELECT RUT_PERSONA,PERIODO FROM (SELECT *, 
ROW_NUMBER() OVER (PARTITION BY CODIGO_SEGURO ORDER BY PERIODO) as RN  
FROM TABLA_STOCK_SEGUROS) WHERE RN = 1

union all

SELECT RUT_PERSONA,PERIODO FROM (SELECT *, 
ROW_NUMBER() OVER (PARTITION BY FOLIO_DEL_CREDITO ORDER BY PERIODO) as RN  
FROM TABLA_STOCK_CREDITO) WHERE RN = 1),

--CREACION MARCA DE VENTA DE AL MENOS 1 PRODUCTO EN EL ULTIMO AÑO
consolidado_venta_ppff as (
select RutPersona,if(date(cast(substr(cast(max(AnioMes) as string),1,4) as int),cast(substr(cast(max(AnioMes) as string),5,2) as int),1)
>date_add(current_date,interval -13 month),1,0) as Marca_ultima_venta_ppff
from venta_productos group by RutPersona),

--INCORPORACION MARCA VENTA AÑO MOVIL EN CONSOLIDADO GENERAL DE AFILIADOS
final_VENTA_PPFF AS (
select a.*,b.Marca_ultima_venta_ppff
from final_STOCK_PPFF as a
left join consolidado_venta_ppff as b
on a.PER_RUT = b.RutPersona),


-------------------FIN VENTA PPFF--------------------------------------------------

--CREACION MARCA USO TOTAL DE SERVICIOS (PRODUCTOS O BENEFICIOS)
Uso_CLA_penetracion as (
select RutPersona from (select RutPersona 
from consolidado_beneficios
where Marca_Penetracion_BBSS = 1
union all
select RUT_PERSONA
from consolidado_stock_ppff)
group by RutPersona),

--CREACION MARCA USO TOTAL DE SERVICIOS (PRODUCTOS O BENEFICIOS) SIN CONSIDERAR 1 PRODUCTO SE SEGUROS
Uso_CLA_penetracion_ajustado_pensionados as (
select RutPersona from (select RutPersona 
from consolidado_beneficios
where Marca_Penetracion_BBSS = 1
union all
select RUT_PERSONA
from consolidado_stock_ppff_ajustado_pensionados)
group by RutPersona),


-------------------FIN PENETRACION CLA--------------------------------------------------

--MARCA SOLO STOCK VIGENTE CREDITO POR PERIODO
consolidado_credito_stock as 
(SELECT cast(BENEFICIARIO_RUT as int) as RUT_PERSONA,cast(PERIODO as int) as PERIODO
FROM TABLA_STOCK_CREDITO_PERIODO
--WHERE periodo = (select max(periodo) from `respaldo-inteligencia-riesgo.GESTION_CARTERA.VS_OPE_CRE_CARTERA_VIGENTE`)
GROUP BY periodo,RUT_PERSONA
),

-------------------FIN STOCK CREDITO PERIODO--------------------------------------------------

--MARCA SOLO VENTA VIGENTE CREDITO POR PERIODO
Venta_Credito as (
SELECT RUT_PERSONA,PERIODO FROM (SELECT *, 
ROW_NUMBER() OVER (PARTITION BY FOLIO_DEL_CREDITO ORDER BY PERIODO) as RN  
FROM TABLA_STOCK_CREDITO) WHERE RN = 1
group by RUT_PERSONA,PERIODO),


-------------------FIN VENTA CREDITO PERIODO--------------------------------------------------

--CREACION MARCA CLUSTER MODELO FUGA EMPRESAS
cluster_Empresas as (
SELECT Rut_Empresa,max(Cluster) as Cluster_Emp
FROM TABLA_CLUSTER_MODELO_FUGA_EMPRESAS
group by Rut_Empresa),

--ULTIMA INFORMACION DE GESTION EMPRESAS
ULTIMO_MAESTRO_EMPRESAS AS (
select *
from TABLA_MAESTRO_EMPRESAS
where Periodo_OK = (select max(Periodo_OK) from TABLA_MAESTRO_EMPRESAS))


--INCORPORACION DE ULTIMOS INDICADORES + CAMPOS DE GESTION PARA FILTROS DE PANEL
select if(a.RUT_HOLDING is null,a.RUT_EMP,a.RUT_HOLDING) as RUT_FINAL,a.*,
a.SubSegmentoA as Rubro_Empresa,

if(b.RutPersona is not null,1,0) as Marca_Penetracion_CLA,

c.Cluster_Emp,

d.FECHA_AFILIACION as FECHA_AFILIACION_EMPRESA,
d.Ejecutivo_Empresa,
d.SUBLIDER,
d.SUCURSAL_EJECUTIVO,
d.AGENTE,
d.RAZON_SOCIAL_RUT_FINAL,
d.LIDER_GESTION_CANALES,

if(e.RutPersona is not null,1,0) as Marca_Penetracion_CLA_ajustado_pensionados,


date_diff(current_date,d.FECHA_AFILIACION,year) as ANOS_AFILIACION,

if(f.RUT_PERSONA is null,0,1) as Marca_Stock_Credito_Periodo,
if(g.RUT_PERSONA is null,0,1) as Marca_Venta_Credito_Periodo


from final_VENTA_PPFF as a
left join Uso_CLA_penetracion as b
on a.PER_RUT = b.RutPersona
left join cluster_Empresas as c
on cast(a.RUT_EMP as string) = trim(c.Rut_Empresa)
left join ULTIMO_MAESTRO_EMPRESAS as d
on a.RUT_EMP = d.RutEmpresa
left join Uso_CLA_penetracion_ajustado_pensionados as e
on a.PER_RUT = e.RutPersona
left join consolidado_credito_stock as f    
on a.PER_RUT = f.RUT_PERSONA
and a.PERIODO_SK = f.PERIODO 
left join Venta_Credito as g
on a.PER_RUT = g.RUT_PERSONA
and a.PERIODO_SK = g.PERIODO 




