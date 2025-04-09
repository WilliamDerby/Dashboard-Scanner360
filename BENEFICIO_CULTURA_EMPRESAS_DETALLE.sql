CREATE OR REPLACE TABLE TABLA_USO_BENEFICIOS_EMPRESAS AS

--Llamado a datos historicos de uso de beneficios
with uso_beneficio as (
SELECT RutPersona,AnioMes,Beneficio,Tipo_Beneficio,MontoBeneficio,NOMBRE_PRESTADOR
FROM TABLA_CONSOLIDADO_BENEFICIOS
where AnioMes > 202000),

--Llamado y ajuste de tabla que asigna mensualmente personas con empresas
base_afiliados as (
SELECT PER_RUT,PERIODO_SK,
cast(substr(trim(RUT_EMP_ENT_PAGADORA),1,length(trim(RUT_EMP_ENT_PAGADORA))-2) as int) AS RUT_EMP,
case when TIPO_AFILIADO in ("TRABAJADOR INDEPENDIENTE","TRABAJADOR SECTOR PRIVADO","TRABAJADOR SECTOR PÚBLICO") 
then "Activo" else "Pensionado" end as Tipo_Afiliado, SEM_SUCEMP 
FROM TABLA_ASIGNACION_PERSONA_EMPRESA
where PERIODO_SK > 202000), 

--Asignacion empresa a base de uso de beneficios
Uso_Empresa as (
select a.*,b.RUT_EMP,b.RUT_EMP as RutEmpresa,b.Tipo_Afiliado,b.SEM_SUCEMP,
DATE(CAST(SUBSTR(cast(a.aniomes as string),1,4) AS INT),CAST(SUBSTR(cast(a.aniomes as string),5,6) AS INT),1) as Periodo_OK
from uso_beneficio as a
left join base_afiliados as b
on concat(a.RutPersona,a.AnioMes) = concat(b.PER_RUT,b.PERIODO_SK)),

--Lista resumida de todos los afiliados por periodo y asignacion del mejor centro de costo
base_afiliados_x_periodo as (
select PERIODO_SK,RUT_EMP,PER_RUT,Tipo_Afiliado,max(SEM_SUCEMP) as SEM_SUCEMP
from base_afiliados 
group by PERIODO_SK,RUT_EMP,PER_RUT,Tipo_Afiliado),

--Lista resumida de todos los afiliados usadores de beneficios por periodo y asignacion del mejor centro de costo
base_uso_x_periodo as (
select AnioMes,RutEmpresa,RutPersona,max(SEM_SUCEMP) as SEM_SUCEMP
from Uso_Empresa
group by AnioMes,RutEmpresa,RutPersona),

--Deteccion de afiliados no usadores de beneficios por periodo
no_usadores_por_periodo as (
select a.*
from base_afiliados_x_periodo as a
left join base_uso_x_periodo as b
on concat(a.PERIODO_SK,"-",a.RUT_EMP,"-",a.PER_RUT) = concat(b.AnioMes,"-",b.RutEmpresa,"-",b.RutPersona)
where b.RutPersona is null),

--Union base usadores + no usadores
union_bases0 as (
select *
from Uso_Empresa
union all
select PER_RUT,PERIODO_SK,null,null,null,null,RUT_EMP,RUT_EMP,Tipo_Afiliado,SEM_SUCEMP,
DATE(CAST(SUBSTR(cast(PERIODO_SK as string),1,4) AS INT),CAST(SUBSTR(cast(PERIODO_SK as string),5,6) AS INT),1),
from no_usadores_por_periodo), 

--Llamado a datos de gestion de empresas
maestro_empresas as (
SELECT Periodo,RutEmpresa as RutEmpresa,EJECUTIVO_EMPRESA as Ejecutivo_Empresa,
if(SEGMENTO_EJECUTIVO is null,0,1) as Carterizada,
CODIGO_SUC_EJECUTIVO as Cod_Suc_Ejecutivo,
Sucursal_Ejecutivo,
CODIGO_SUC_EMPRESA as Cod_Suc_Empresa,
SUCURSAL_EMPRESA as SucursalEmpresa,
trim(SEGMENTO_EJECUTIVO) as Segmento_Ejecutivo,
SEGMENTO_EMPRESA_AJUSTADO,
REGION_EMPRESA_AJUSTADO,
REGION_EMPRESA_PARA_KPI,
RAZON_SOCIAL,
Rubro_Empresa,
RUT_HOLDING,
RUT_FINAL,
RAZON_SOCIAL_RUT_FINAL,
Rubro_Empresa_RUT_FINAL,
REGION_EMPRESA_AJUSTADO_RUT_FINAL,
AGENTE,
LIDER_GESTION_CANALES
FROM TABLA_MAESTRO_EMPRESA
where Periodo_OK > '2021-12-31')

--Asignacion datos de gestion por empresas a cada registro de la tabla de uso + identificacion del tipo de afiliacion de cada usador
select 
a.*,

case
when RUT_EMP is null then "No Afiliado"
when Tipo_Afiliado = 'Pensionado' then "Pensionado"
when b.RutEmpresa is null then "Empresa No Informada en Maestro"
when Carterizada = 1 then Sucursal_Ejecutivo
when Carterizada = 0 then SucursalEmpresa
else "Revisar" end as Sucursal_Empresa_Final,

case
when RUT_EMP is null then "No Afiliado"
when Tipo_Afiliado = 'Pensionado' then "Pensionado"
when b.RutEmpresa is null then "Empresa No Informada en Maestro"
when Carterizada = 1 then Sucursal_Ejecutivo
else "Revisar" end as Sucursal_Ejecutivo_Final,

case
when RUT_EMP is null then "No Afiliado"
when Tipo_Afiliado = 'Pensionado' then "Pensionado"
when b.RutEmpresa is null then "Empresa No Informada en Maestro"
when Carterizada = 1 then AGENTE
else "Revisar" end as AGENTE_final,

case
when RUT_EMP is null then 0
when Tipo_Afiliado = 'Pensionado' then 0
when b.RutEmpresa is null then 0
when Carterizada = 1 then Cod_Suc_Ejecutivo
when Carterizada = 0 then Cod_Suc_Empresa
else 0 end as Cod_Sucursal_Empresa_Final,

case
when RUT_EMP is null then "No Afiliado"
when Tipo_Afiliado = 'Pensionado' then "Pensionado"
when b.RutEmpresa is null then "Empresa No Informada en Maestro"
when Carterizada = 1 then "Carterizada"
when Carterizada = 0 then "No Carterizada"
else "Revisar" end as Marca_Carterizado_y_tipo_Afiliado,

case
when RUT_EMP is null then "No Afiliado"
when Tipo_Afiliado = 'Pensionado' then "Pensionado"
when b.RutEmpresa is null then "Empresa No Informada en Maestro"
when Carterizada = 1 then Segmento_Ejecutivo
when Carterizada = 0 then "No Carterizada"
else "Revisar" end as Segmento_Ejecutivo_Final,

case
when RUT_EMP is null then "No Afiliado"
when Tipo_Afiliado = 'Pensionado' then "Pensionado"
when b.RutEmpresa is null then "Empresa No Informada en Maestro"
when Carterizada = 1 then Ejecutivo_Empresa
when Carterizada = 0 then "No Carterizada"
else "Revisar" end as Ejecutivo_Empresa_Final,

case
when RUT_EMP is null then "No Afiliado"
when Tipo_Afiliado = 'Pensionado' then "Pensionado"
when b.RutEmpresa is null then "Empresa No Informada en Maestro"
when Carterizada is not null then SEGMENTO_EMPRESA_AJUSTADO
else "Revisar" end as SEGMENTO_EMPRESA_AJUSTADO,

case
when RUT_EMP is null then "No Afiliado"
when Tipo_Afiliado = 'Pensionado' then "Pensionado"
when b.RutEmpresa is null then "Empresa No Informada en Maestro"
when Carterizada is not null then REGION_EMPRESA_AJUSTADO
else "Revisar" end as REGION_EMPRESA_AJUSTADO,

case
when RUT_EMP is null then "No Afiliado"
when Tipo_Afiliado = 'Pensionado' then "Pensionado"
when b.RutEmpresa is null then "Empresa No Informada en Maestro"
when Carterizada is not null then REGION_EMPRESA_PARA_KPI
else "Revisar" end as REGION_EMPRESA_PARA_KPI,

case
when RUT_EMP is null then "No Afiliado"
when Tipo_Afiliado = 'Pensionado' then "Pensionado"
when b.RutEmpresa is null then "Empresa No Informada en Maestro"
when Carterizada is not null then Rubro_Empresa
else "Revisar" end as Rubro_Empresa,

case
when RUT_EMP is null then null
when Tipo_Afiliado = 'Pensionado' then "Pensionado"
when b.RutEmpresa is null then null
when Carterizada is not null then RAZON_SOCIAL_RUT_FINAL
else "Revisar" end as RAZON_SOCIAL_RUT_FINAL,

case
when RUT_EMP is null then null
when Tipo_Afiliado = 'Pensionado' then "Pensionado"
when b.RutEmpresa is null then null
when Carterizada is not null then Rubro_Empresa_RUT_FINAL
else "Revisar" end as Rubro_Empresa_RUT_FINAL,

case
when RUT_EMP is null then null
when Tipo_Afiliado = 'Pensionado' then "Pensionado"
when b.RutEmpresa is null then null
when Carterizada is not null then REGION_EMPRESA_AJUSTADO_RUT_FINAL
else "Revisar" end as REGION_EMPRESA_AJUSTADO_RUT_FINAL,

case
when RUT_EMP is null then null
when Tipo_Afiliado = 'Pensionado' then null
when b.RutEmpresa is null then null
when Carterizada is not null then RUT_HOLDING
else null end as RUT_HOLDING,

case
when RUT_EMP is null then null
when Tipo_Afiliado = 'Pensionado' then null
when b.RutEmpresa is null then null
when Carterizada is not null then RUT_FINAL
else null end as RUT_FINAL,

case
when RUT_EMP is null then null
when Tipo_Afiliado = 'Pensionado' then null
when b.RutEmpresa is null then null
when Carterizada is not null then LIDER_GESTION_CANALES
else null end as LIDER_GESTION_CANALES,


from union_bases0 as a
left join maestro_empresas as b
on concat(a.RUT_EMP,"-",a.AnioMes) = concat(b.RutEmpresa,"-",b.Periodo);

CREATE OR REPLACE TABLE TABLA_USO_BENEFICIOS_EMPRESAS2 AS

--Llamado y ajuste de tabla que asigna mensualmente personas con empresas
with base_afiliados as (
SELECT PER_RUT,
DATE_SUB(DATE(CAST(SUBSTR(CAST(PERIODO_SK AS STRING),1,4) AS INT),CAST(SUBSTR(CAST(PERIODO_SK AS STRING),5,6) AS INT),1),INTERVAL 0 MONTH) as PERIODO_OK,PERIODO_SK,
cast(substr(trim(RUT_EMP_ENT_PAGADORA),1,length(trim(RUT_EMP_ENT_PAGADORA))-2) as int) AS RUT_EMP,
case when TIPO_AFILIADO in ("TRABAJADOR INDEPENDIENTE","TRABAJADOR SECTOR PRIVADO","TRABAJADOR SECTOR PÚBLICO") 
then "Activo" else "Pensionado" end as Tipo_Afiliado,
SEM_SUCEMP 
FROM TABLA_ASIGNACION_PERSONA_EMPRESA
where PERIODO_SK > 202200),

--Base de todas las personas con antecedentes en sistema 
base_rut_completa as (
select PER_RUT
from TABLA_INFORMACION_PERSONAS
group by PER_RUT),

--Base de afiliados ultimo periodo
base_rut_ultimo_mes as (
select RutPersona
from TABLA_USO_BENEFICIOS_EMPRESAS
where Periodo_OK = (select max(Periodo_OK) from base_afiliados)
group by RutPersona),

--Base no afiliados actualmente
base_no_afiliados as (
select a.*
from base_rut_completa as a
left join base_rut_ultimo_mes as b
on a.PER_RUT = b.RutPersona
where b.RutPersona is null),

-- Total de periodos y pensionados + ultimo periodo con no afiliados 
union_bases_final as (
select *
from TABLA_USO_BENEFICIOS_EMPRESAS
union all
select PER_RUT,(select max(PERIODO_SK) from base_afiliados),
null,null,null,null,null,null,"No Afiliado",null,
(select max(Periodo_OK) from base_afiliados),
null,null,null,null,null,null,null,null,null,null,null,null,
null,null,null,null,null,null,null,null,null,null,null,null,null,null
from base_no_afiliados),

--Ultimo registro de nombre de cada persona
ultimo_registro as (
SELECT PER_RUT,NOMBRE_AFILIADO
FROM (SELECT *, 
ROW_NUMBER() OVER (PARTITION BY PER_RUT ORDER BY PERIODO_SK DESC) as RN  
FROM TABLA_ASIGNACION_PERSONA_EMPRESA) 
WHERE RN = 1),

--Penetracion actual de beneficios (por empresa)
penetracion_ultimo_periodo as (
select *
from TABLA_PENETRACION_BENEFICIOS
where Periodo_Penetracion = (select max(Periodo_Penetracion) from TABLA_PENETRACION_BENEFICIOS)), 

-- Datos de gestion y demografico ultimo maestro empresas
Ultimo_Registro_Empresa_Maestro as (
SELECT Periodo,RUT_EMPRESA,REGION_EMPRESA_AJUSTADO,Rubro_Empresa,EJECUTIVO_EMPRESA
FROM (SELECT *, 
ROW_NUMBER() OVER (PARTITION BY RUT_EMPRESA ORDER BY Periodo DESC) as RN  
FROM TABLA_MAESTRO_EMPRESAS) 
WHERE RN = 1),

-- Incorporacion de datos al consolidado final
base_clave_nombre as (
select a.*,b.NOMBRE_AFILIADO,
e.Penetracion_Empresa_Periodo as Penetracion_Empresa,e.Penetracion_Segmento_Periodo,
e.cumplimiento as cumplimiento_penetracion,
f.REGION_EMPRESA_AJUSTADO as REGION_EMPRESA_PENETRACION,f.Rubro_Empresa AS Rubro_Empresa_Penetracion,
f.EJECUTIVO_EMPRESA as EJECUTIVO_EMPRESA_ULTIMO 
from union_bases_final as a
left join ultimo_registro as b
on a.RutPersona = b.PER_RUT
left join penetracion_ultimo_periodo as e
on concat(a.RutEmpresa,'-',a.Periodo_OK) = concat(e.RutEmpresa,'-',e.Periodo_Penetracion)
left join Ultimo_Registro_Empresa_Maestro as f
on a.RutEmpresa = f.RUT_EMPRESA),

--Ultimo registro de cada empresa en consolidado
ultimo_registro_empresa as (
SELECT AnioMes,RutEmpresa
FROM (SELECT *, 
ROW_NUMBER() OVER (PARTITION BY RutEmpresa ORDER BY AnioMes DESC) as RN  
FROM base_clave_nombre) 
WHERE RN = 1),

--Incorporacion de datos para filtros de panel
base_y_marca_ultimo_registro_empresa as (
select a.*,if(b.RutEmpresa is null,0,1) as Marca_Ultimo_Registro_Empresa,
if(a.AnioMes = (select max(AnioMes) from base_clave_nombre),1,0) as Marca_Ultimo_Periodo
from base_clave_nombre as a
left join ultimo_registro_empresa as b
on concat(a.AnioMes,a.RutEmpresa) = concat(b.AnioMes,b.RutEmpresa)),

--Ultimo periodo que ocupa beneficios cada persona
ultimo_periodo_uso_beneficio_rut as (
SELECT RutPersona,Periodo_OK
FROM (SELECT *, 
ROW_NUMBER() OVER (PARTITION BY RutPersona ORDER BY Periodo_OK DESC) as RN  
FROM (select * from TABLA_USO_BENEFICIOS_EMPRESAS 
where Beneficio is not null)) 
WHERE RN = 1),

--Ultimo periodo que ocupa un beneficio una persona en una empresa especifica
ultimo_periodo_uso_beneficio_rut_empresa as (
SELECT RutPersona,RutEmpresa,Periodo_OK
FROM (SELECT *, 
ROW_NUMBER() OVER (PARTITION BY concat(RutPersona,'-',RutEmpresa) ORDER BY Periodo_OK DESC) as RN  
FROM (select * from TABLA_USO_BENEFICIOS_EMPRESAS 
where Beneficio is not null)) 
WHERE RN = 1),

-- Incorporacion de datos anteriores al consolidado
marca_gestion_penetracion as (
select a.*,b.Periodo_OK as Periodo_ultimo_uso_Beneficio_RUT,c.Periodo_OK as Periodo_ultimo_uso_Beneficio_RUT_Empresa,
from base_y_marca_ultimo_registro_empresa as a
left join ultimo_periodo_uso_beneficio_rut as b
on a.RutPersona = b.RutPersona
left join ultimo_periodo_uso_beneficio_rut_empresa as c
on concat(a.RutPersona,'-',a.RutEmpresa) = concat(c.RutPersona,'-',c.RutEmpresa)),

-- Ultima razon social informada por cada empresa (homologar nombre)
razon_social as (
SELECT RutEmpresa,RAZON_SOCIAL
FROM (SELECT *, 
ROW_NUMBER() OVER (PARTITION BY RutEmpresa ORDER BY Periodo_OK DESC) as RN  
FROM (select * from marca_gestion_penetracion where RAZON_SOCIAL is not null)) 
WHERE RN = 1)

-- Consolidado final, con incorporacion de filtros para los dashboard
select 
a.*,case when RUT_EMP = 81826800 then 1 else 0 end as Marca_CLA,

case when Periodo_ultimo_uso_Beneficio_RUT is null then 1
when Periodo_ultimo_uso_Beneficio_RUT < date_add(current_date, interval -13 month) then 1
else 0 end as Marca_Gestion_Penetracion,b.RAZON_SOCIAL as RazonSocialEmpresa_total,

FROM marca_gestion_penetracion as a
left join razon_social as b
on a.RutEmpresa = b.RutEmpresa

