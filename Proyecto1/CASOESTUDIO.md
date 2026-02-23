# Caso de Estudio: Optimización

**David Restrepo**  
**Sebastián Castaño**  
**Miguel Alejandro Gómez**

**Universidad EAFIT**  
**Bases de Datos Avanzadas**

**Profesor:** Edwin Nelson Montoya  
**Fecha:** 22/02/2026  

---

## Objetivo

Evaluar el desempeño del sistema **EAFITShop**, un e-commerce, con carga OLTP y reporting. Establecer una línea base con `EXPLAIN` y aplicar mejoras en el sistema. Comparar los resultados antes y después de las mejoras establecidas.

---

## Descripción del Caso

EAFITShop es un sistema de comercio electrónico OLTP con entidades como clientes, productos, órdenes y pagos, además de soportar analítica y reportes. El problema aparece cuando las consultas de los reportes ejecutan `Seq Scan` y agregaciones sobre tablas grandes, lo que degrada el motor transaccional y eleva la latencia.

---

## Situación Real

Este caso es presentado por **Calimatic**, una empresa tecnológica que ofrece desarrollos, automatizaciones y análisis de datos. Se reporta la optimización de una base de datos PostgreSQL con más de **50M registros**, donde un dashboard de analítica era prácticamente inutilizable.

**Problemas:**
- CPU constantemente > 95%
- Cargas de dashboards > 60 s
- Analíticas de ventas > 38 s
- Reportes de actividad > 45 s

**Soluciones aplicadas:**
- Logging de queries lentas
- Creación de índices en columnas usadas en `WHERE`, `JOIN` y `ORDER BY`
- Uso de índices compuestos
- Reescritura de queries (evitar N+1, reemplazar JOINs innecesarios)
- Performance tuning del servidor
- Particionamiento de tablas (>10M registros) por fecha o ID

**Resultados:**
- Reportes de actividad: 45 s → **200 ms**
- Analíticas de ventas: 38 s → **150 ms**
- Dashboards: 60 s → **800 ms**
- CPU: 95% → **25%**

En general, se mejoraron los tiempos en un **99%** y el uso de CPU en un **73%**, logrando mejor experiencia de usuario y mayor escalabilidad sin escalar hardware.

---

## Ambiente Tecnológico

- Instancia **EC2** con PostgreSQL dockerizado  
- Instancia **AWS RDS PostgreSQL**  
- Herramientas de medición: `EXPLAIN` y `EXPLAIN ANALYZE`

---

# Datos Antes de Optimizar

## EC2

| Query | Tiempo (ms) | Conclusión |
|-------|-------------|------------|
| Q1 | 3424.861 | Parallel Seq Scan sobre `orders` y `customer`, luego Parallel Hash Join. Dominado por I/O y procesamiento de cientos de miles de filas. |
| Q2 | 41660.617 | Dominado por Seq Scan en `order_item` y Hash Join masivo con `product`. |
| Q3 | 229.022 | Falta índice: Parallel Seq Scan en `orders`, alto I/O. |
| Q4 | 1.420 | Seq Scan en `product` por `ILIKE '%42%'`. No escala. |
| Q5 | 667.940 | Seq Scan por uso de `date_trunc` en filtro, impide uso de índice. |
| Q6 | 7052.471 | Seq Scan en `payment` y `orders`, Hash Join masivo. |
| Q7 | 19446.798 | Seq Scan en `order_item`, alto I/O y joins masivos. |
| Q8 | 7740.361 | Seq Scan en `orders` y `customer`, HashAggregate con uso de disco. |

## AWS RDS

(Se mantienen las mismas conclusiones técnicas, con variaciones de tiempos por caché frío/caliente y entorno administrado.)

---

# Datos Después de Optimizar

## EC2

| Query | Tiempo (ms) | Conclusión |
|-------|-------------|------------|
| Q1 | 3210 | Menor I/O, pero el volumen de datos sigue siendo el cuello de botella. |
| Q2 | 21600 | La mejora real viene de reducir volumen antes del join. |
| Q3 | 0.085 | Mejora drástica: índice compuesto evita sort y aplica LIMIT directo. |
| Q4 | 1.364 | El optimizador no usa el índice por baja selectividad y tamaño de tabla. |
| Q5 | 3.687 | Reescritura permite usar índice y reduce drásticamente el tiempo. |
| Q6 | 7070 | Índice parcial mejora `payment`, pero `orders` sigue siendo el cuello de botella. |
| Q7 | 2740 | Cambio a accesos indexados selectivos, gran reducción de volumen procesado. |
| Q8 | 7591.230 | Mejora leve: el cuello sigue en el Hash Join y HashAggregate. |

## AWS RDS

Resultados similares, con mejoras claras en Q3 y Q5, y mejoras limitadas en queries dominadas por escaneos masivos y joins de gran volumen.

---

# Particionamiento

- Particionamiento por **rango en `order_date`** (anual, ~1M registros por partición).
- Particionamiento por **lista en `payment_status`**, con partición específica para `'APPROVED'`.

**Efectos:**
- Habilita *partition pruning*.
- Mejora el acceso a `payment`.
- No elimina cuellos de botella cuando el problema principal sigue siendo el escaneo masivo de `orders` o `order_item`.

---

# Performance Tuning

## Configuraciones Aplicadas

- `work_mem = 128MB`
- `random_page_cost = 1.0`
- `effective_cache_size = 8GB`
- `effective_io_concurrency = 100`
- `max_parallel_workers_per_gather = 2`
- `track_io_timing = on`

## Resultados en EC2

| Query | Tiempo (ms) | Conclusión |
|-------|-------------|------------|
| Q1 | ~2900 | Sin mejora significativa |
| Q2 | ~0.1 | Óptima |
| Q3 | ~1.3 | Sin cambio relevante |
| Q4 | ~3–4 | Óptima |
| Q5 | ~20000 | Sin mejora significativa |
| Q6 | ~6400–6500 | Mejora leve |

**Conclusión general:**  
El cuello de botella principal no estaba en la configuración del motor, sino en la naturaleza de las consultas (procesamiento de millones de filas sin filtros selectivos). Se requieren cambios estructurales: rediseño de consultas, preagregaciones o estrategias orientadas a analítica.

---

# Líneas Futuras de Trabajo

- Enfocarse en cambios estructurales más que en tuning.
- Continuar con **vistas materializadas**.
- Implementar **preagregaciones** para reportes recurrentes.
- Refinar el diseño de índices.

---

# Uso de IA

La IA se utilizó para:
- Buscar la situación real en una empresa (Perplexity).
- Comprender mejor las queries.
- Interpretar resultados.
- Proponer posibles mejoras y optimizaciones.

---

# Referencias

- https://calimatic.com/blog/postgres-performance-optimization/

---

# Repositorio

- https://github.com/scastanoa1/BasesDeDatosAvanzadas/tree/main