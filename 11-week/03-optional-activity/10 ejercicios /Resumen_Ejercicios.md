# Resumen de Proyecto: Solución de 10 Ejercicios PostgreSQL

Este documento describe el trabajo de organización, análisis y desarrollo realizado sobre el modelo de datos de un Sistema de Aerolínea.

## Estructura del Proyecto
Cada ejercicio se encuentra en su propia carpeta e incluye el enunciado original (`.md`) y la solución técnica (`.sql`).

## Metodología y Acciones Realizadas

Para completar este proyecto, se llevaron a cabo las siguientes acciones técnicas:

1.  **Análisis del Modelo Base**: Se realizó una revisión exhaustiva del archivo `modelo_postgresql.sql`, identificando más de 60 entidades distribuidas en dominios como Geografía, Identidad, Seguridad, Fidelización, Operaciones de Vuelo y Finanzas.
2.  **Organización Estructural**: Se crearon carpetas independientes para cada ejercicio y se migraron los archivos `.md` originales, asegurando un entorno de trabajo limpio y modular.
3.  **Desarrollo de Soluciones Técnicas**: Para cada uno de los 10 casos de uso, se desarrolló:
    *   **Consultas Relacionales**: Cruce de información mediante `INNER JOIN` de 5+ tablas para garantizar trazabilidad.
    *   **Automatización con Triggers**: Programación de triggers de tipo `AFTER` vinculados a funciones de PostgreSQL para disparar acciones automáticas basadas en lógica de negocio.
    *   **Encapsulamiento con Procedimientos**: Creación de `STORED PROCEDURES` para centralizar la inserción de datos complejos, simplificando la interacción con el modelo normalizado.
4.  **Validación**: Se incluyeron scripts de prueba unitaria en cada solución para demostrar el correcto funcionamiento de los objetos creados sin alterar la estructura original del modelo.

---

## Dominios Cubiertos del Modelo

El desarrollo se integró con los siguientes dominios funcionales del sistema:

*   **Geografía y Referencia**: Ubicación de aeropuertos y divisas.
*   **Identidad**: Gestión de personas, documentos y contactos.
*   **Seguridad**: Control de usuarios, roles y permisos.
*   **Fidelización**: Programas de millas y niveles de membresía.
*   **Operaciones**: Gestión de aeronaves, mantenimiento, vuelos y retrasos.
*   **Comercial**: Reservas, ventas, tiquetes, equipaje y asignación de asientos.
*   **Finanzas y Facturación**: Pagos, reembolsos, impuestos y facturas.

---

## Detalle de los Ejercicios

### [01. Check-in y Trazabilidad](./ejercicio_01/)
- **Objetivo**: Integrar el flujo desde la reserva hasta el pase de abordar.
- **Lo que se hizo**: 
    - Se construyó una consulta que une **7 tablas** (`reservation` hasta `flight`) para ver el itinerario completo del pasajero.
    - Se programó un **Trigger AFTER** que genera el `boarding_pass` físico en la base de datos automáticamente al insertar el check-in.
    - Se encapsuló el flujo en un **Procedimiento Almacenado** para asegurar registros consistentes.

### [02. Control de Pagos](./ejercicio_02/)
- **Objetivo**: Auditar transacciones financieras y gestionar reembolsos.
- **Lo que se hizo**: 
    - Se diseñó una consulta de **7 tablas** para rastrear desde la venta hasta la transacción bancaria.
    - Se implementó un **Trigger AFTER** que detecta transacciones de tipo 'REFUND' y crea automáticamente la evidencia en la tabla `refund`.
    - El procedimiento permite registrar transacciones externas vinculándolas a pagos existentes.

### [03. Facturación e Impuestos](./ejercicio_03/)
- **Objetivo**: Garantizar la consistencia entre la cabecera de la factura y su detalle.
- **Lo que se hizo**: 
    - Consulta de **6 tablas** para validar montos, impuestos y monedas de cada factura.
    - Se configuró un **Trigger AFTER** que concatena información de cada nueva línea en las notas de la factura principal para auditoría rápida.
    - El procedimiento facilita la inserción de líneas de detalle con cálculo de impuestos.

### [04. Fidelización y Millas](./ejercicio_04/)
- **Objetivo**: Gestionar la acumulación de millas y niveles de cliente.
- **Lo que se hizo**: 
    - Consulta de **7 tablas** para obtener el historial de movimientos y nivel de lealtad actual.
    - Se desarrolló un **Trigger AFTER** que recalcula el total de millas e inserta al cliente en un nuevo nivel (`loyalty_tier`) si cumple con los requisitos.
    - Procedimiento para acreditar millas por vuelos o promociones.

### [05. Mantenimiento de Aeronaves](./ejercicio_05/)
- **Objetivo**: Controlar la disponibilidad y eventos técnicos de la flota.
- **Lo que se hizo**: 
    - Consulta de **6 tablas** relacionando fabricante, modelo y eventos técnicos.
    - Se implementó un **Trigger AFTER** que actualiza el estado de la aeronave al finalizar un mantenimiento.
    - Procedimiento para registrar inspecciones técnicas programadas.

### [06. Retrasos Operativos](./ejercicio_06/)
- **Objetivo**: Analizar el impacto de demoras en los segmentos de vuelo.
- **Lo que se hizo**: 
    - Consulta de **6 tablas** vinculando el motivo del retraso con la ruta del vuelo.
    - Trigger para marcar la traza del retraso en el segmento operativo.
    - Procedimiento para reportar minutos de demora con códigos de razón estandarizados.

### [07. Asientos y Equipaje](./ejercicio_07/)
- **Objetivo**: Vincular los servicios adicionales al tiquete del pasajero.
- **Lo que se hizo**: 
    - Consulta masiva de **7 tablas** uniendo tiquetes, asientos físicos y etiquetas de equipaje.
    - Trigger que sincroniza el estado del segmento de viaje con el registro de las maletas.
    - Procedimiento para el despacho de equipaje en mostrador.

### [08. Seguridad y Roles](./ejercicio_08/)
- **Objetivo**: Administrar permisos y auditoría de cuentas de usuario.
- **Lo que se hizo**: 
    - Consulta de **5 tablas** para auditar quién tiene acceso a qué roles y permisos.
    - Trigger de auditoría que actualiza los metadatos del usuario al cambiar sus privilegios.
    - Procedimiento para asignar roles basado en el nombre de usuario (`username`).

### [09. Tarifas y Reservas](./ejercicio_09/)
- **Objetivo**: Gestionar la estrategia de precios y análisis comercial.
- **Lo que se hizo**: 
    - Consulta de **8 tablas** para analizar qué tarifas se están vendiendo más.
    - Trigger que notifica a la entidad de la aerolínea sobre cambios en su catálogo de precios.
    - Procedimiento para actualizar precios de forma masiva por código de tarifa.

### [10. Identidad de Pasajeros](./ejercicio_10/)
- **Objetivo**: Mantener perfiles de pasajeros completos y actualizados.
- **Lo que se hizo**: 
    - Consulta de **7 tablas** uniendo datos personales, pasaportes y múltiples canales de contacto (Email, Celular).
    - Trigger que marca la última fecha de actualización de los datos personales.
    - Procedimiento para registrar nuevos medios de contacto asegurando la integridad referencial.

---

## Cómo usar las soluciones
Cada archivo `.sql` contiene scripts de prueba al final (dentro de bloques de comentarios). Para validar el funcionamiento:
1. Asegúrese de tener cargado el modelo base `modelo_postgresql.sql`.
2. Ejecute el script de la solución para crear las funciones, triggers y procedimientos.
3. Descomente y ejecute el bloque de prueba final para verificar los resultados.
