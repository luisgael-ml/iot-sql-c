-- =====================================================================
-- TAREA 10 · Programacion del lado del cliente: SQL embebido con C
-- IoT Analytics Dashboard (NexoDev Solutions) · PostgreSQL 16
-- Base de datos que el programa en C (ECPG) administra con operaciones CRUD.
-- =====================================================================

CREATE TABLE dispositivos (
    id        SERIAL PRIMARY KEY,
    codigo    VARCHAR(20) NOT NULL UNIQUE,
    nombre    VARCHAR(60) NOT NULL,
    ubicacion VARCHAR(60) NOT NULL,
    estado    VARCHAR(15) NOT NULL DEFAULT 'activo'
              CHECK (estado IN ('activo', 'mantenimiento', 'inactivo'))
);

CREATE TABLE sensores (
    id             SERIAL PRIMARY KEY,
    dispositivo_id INT NOT NULL REFERENCES dispositivos(id),
    codigo         VARCHAR(20) NOT NULL UNIQUE,
    tipo           VARCHAR(20) NOT NULL CHECK (tipo IN ('temperatura', 'vibracion', 'energia', 'humedad')),
    unidad         VARCHAR(10) NOT NULL,
    umbral_max     NUMERIC(10,2) NOT NULL CHECK (umbral_max > 0)
);

CREATE TABLE lecturas (
    id        BIGSERIAL PRIMARY KEY,
    sensor_id INT NOT NULL REFERENCES sensores(id),
    valor     NUMERIC(10,2) NOT NULL,
    medido_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_lecturas_sensor_fecha ON lecturas (sensor_id, medido_en DESC);
CREATE INDEX idx_lecturas_fecha        ON lecturas (medido_en DESC);

CREATE TABLE alertas (
    id         SERIAL PRIMARY KEY,
    lectura_id BIGINT NOT NULL REFERENCES lecturas(id) ON DELETE CASCADE,
    sensor_id  INT NOT NULL REFERENCES sensores(id),
    severidad  VARCHAR(12) NOT NULL CHECK (severidad IN ('advertencia', 'critica')),
    valor      NUMERIC(10,2) NOT NULL,
    umbral     NUMERIC(10,2) NOT NULL,
    creada_en  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atendida   BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE INDEX idx_alertas_lectura ON alertas (lectura_id);

-- Alerta automatica (de la Tarea 9): el programa en C solo inserta la lectura
CREATE FUNCTION trg_lecturas_alerta() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
    v_umbral NUMERIC;
BEGIN
    SELECT umbral_max INTO v_umbral FROM sensores WHERE id = NEW.sensor_id;
    IF NEW.valor > v_umbral THEN
        INSERT INTO alertas (lectura_id, sensor_id, severidad, valor, umbral, creada_en)
        VALUES (NEW.id, NEW.sensor_id,
                CASE WHEN NEW.valor > v_umbral * 1.2 THEN 'critica' ELSE 'advertencia' END,
                NEW.valor, v_umbral, NEW.medido_en);
    END IF;
    RETURN NULL;
END $$;

CREATE TRIGGER t_lecturas_alerta AFTER INSERT ON lecturas
FOR EACH ROW EXECUTE FUNCTION trg_lecturas_alerta();

-- Usuario del programa en C: CRUD sobre las tablas, sin poder cambiar la estructura
CREATE ROLE app_iot LOGIN PASSWORD 'app123';
GRANT SELECT, INSERT, UPDATE, DELETE ON dispositivos, sensores, lecturas, alertas TO app_iot;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO app_iot;

-- Datos iniciales
INSERT INTO dispositivos (codigo, nombre, ubicacion) VALUES
('PRE-03', 'Prensa hidraulica 3', 'Linea 1'),
('TOR-01', 'Torno CNC 1',        'Linea 2'),
('EMB-02', 'Embotelladora 2',    'Linea 3');

INSERT INTO sensores (dispositivo_id, codigo, tipo, unidad, umbral_max) VALUES
(1, 'PRE03-TEMP', 'temperatura', '°C',   85.00),
(1, 'PRE03-VIB',  'vibracion',   'mm/s',  7.00),
(1, 'PRE03-ENE',  'energia',     'kWh',  30.00),
(2, 'TOR01-TEMP', 'temperatura', '°C',   80.00),
(2, 'TOR01-VIB',  'vibracion',   'mm/s',  6.00),
(2, 'TOR01-ENE',  'energia',     'kWh',  25.00),
(3, 'EMB02-TEMP', 'temperatura', '°C',   75.00),
(3, 'EMB02-VIB',  'vibracion',   'mm/s',  5.00),
(3, 'EMB02-ENE',  'energia',     'kWh',  20.00);

-- 6 horas de historico (una lectura cada 30 s por sensor)
SELECT setseed(0.5);
INSERT INTO lecturas (sensor_id, valor, medido_en)
SELECT s.id, ROUND((s.umbral_max * (0.80 + (random() - 0.5) * 0.08))::numeric, 2), t
FROM sensores s
CROSS JOIN generate_series(NOW() - INTERVAL '6 hours', NOW() - INTERVAL '1 minute',
                           INTERVAL '30 seconds') AS t;
ANALYZE;
