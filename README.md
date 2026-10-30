# IoT Analytics Dashboard · SQL embebido con C (Tarea 10)

NexoDev Solutions · Programación de Base de Datos (TESE) · Luis Gael Monterrubio López

## Documentación

📄 [Abrir la documentación de la Tarea 10 (PDF)](docs/Documentacion_Tarea10.pdf)

Programa en C con **SQL embebido (ECPG)** que realiza operaciones CRUD sobre los datos de sensores IoT en PostgreSQL 16. Las sentencias `EXEC SQL` van dentro del código C y el precompilador `ecpg` las traduce a C antes de compilar.

```
iot_crud.pgc ──ecpg──► iot_crud.c ──gcc + libecpg──► iot_crud ──SSL──► PostgreSQL
```

## Comandos

| Operación | Comando |
|---|---|
| Crear | `crear-sensor <codigo> <dispositivo> <tipo> <unidad> <umbral>` · `registrar <sensor> <valor>` · `simular [s]` |
| Leer | `listar` · `sensor <codigo>` · `lecturas <sensor> [n]` · `resumen` · `monitor [s]` |
| Actualizar | `umbral <sensor> <nuevo>` · `estado <dispositivo> <estado>` |
| Eliminar | `eliminar-lectura <id>` · `eliminar-sensor <codigo> [--con-lecturas]` |
| Rendimiento | `benchmark [n]` |

## Técnicas de SQL embebido

`CONNECT` con SSL · variables de enlace (`DECLARE SECTION`) · variables indicadoras para `NULL` · `SELECT ... INTO` · cursores (`DECLARE`, `OPEN`, `FETCH`, `CLOSE`) · `INSERT ... RETURNING INTO` · sentencias preparadas (`PREPARE` / `EXECUTE ... USING`) · SQL dinámico (`EXECUTE IMMEDIATE`) · transacciones (`COMMIT` / `ROLLBACK`) · manejo de errores con `sqlca` y `WHENEVER SQLERROR`.

## Levantar

```bash
docker compose up -d --build
docker exec sqlc-cliente iot_crud listar
```
