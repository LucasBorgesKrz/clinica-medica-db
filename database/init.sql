-- =============================================================
-- Projeto: Sistema de Clínica Médica
-- Script inicial de criação do banco (PostgreSQL 14+)
--
-- Como executar:
--   psql -U postgres -f database/init.sql
-- =============================================================

-- 1) Criação do banco ------------------------------------------
DROP DATABASE IF EXISTS clinica_medica;
CREATE DATABASE clinica_medica
    ENCODING 'UTF8'
    TEMPLATE template0;

-- Conecta no banco recém-criado (comando do psql)
\c clinica_medica

-- 2) Tabela principal: pacientes -------------------------------
CREATE TABLE pacientes (
    id               SERIAL       PRIMARY KEY,
    nome             VARCHAR(120) NOT NULL,
    cpf              CHAR(11)     NOT NULL UNIQUE,
    data_nascimento  DATE         NOT NULL,
    sexo             CHAR(1),
    telefone         VARCHAR(20)  NOT NULL,
    email            VARCHAR(120),
    criado_em        TIMESTAMP    NOT NULL DEFAULT NOW(),

    -- Regras de negócio (bônus)
    CONSTRAINT ck_pacientes_cpf_numerico   CHECK (cpf ~ '^[0-9]{11}$'),
    CONSTRAINT ck_pacientes_sexo           CHECK (sexo IN ('M', 'F', 'O')),
    CONSTRAINT ck_pacientes_nascimento     CHECK (data_nascimento >= DATE '1900-01-01'),
    CONSTRAINT ck_pacientes_email          CHECK (email IS NULL OR email LIKE '%_@_%._%')
);

-- 3) Demais entidades do escopo --------------------------------
CREATE TABLE especialidades (
    id    SERIAL      PRIMARY KEY,
    nome  VARCHAR(80) NOT NULL UNIQUE
);

CREATE TABLE medicos (
    id               SERIAL        PRIMARY KEY,
    nome             VARCHAR(120)  NOT NULL,
    crm              VARCHAR(15)   NOT NULL UNIQUE,   -- ex: 123456-SP
    especialidade_id INT           NOT NULL REFERENCES especialidades(id),
    valor_consulta   NUMERIC(10,2) NOT NULL,
    ativo            BOOLEAN       NOT NULL DEFAULT TRUE,

    -- Regra de negócio: valor da consulta não pode ser negativo
    CONSTRAINT ck_medicos_valor_consulta CHECK (valor_consulta >= 0)
);

CREATE TABLE consultas (
    id           SERIAL        PRIMARY KEY,
    paciente_id  INT           NOT NULL REFERENCES pacientes(id),
    medico_id    INT           NOT NULL REFERENCES medicos(id),
    data_hora    TIMESTAMP     NOT NULL,
    duracao_min  INT           NOT NULL DEFAULT 30,
    status       VARCHAR(15)   NOT NULL DEFAULT 'agendada',
    valor        NUMERIC(10,2) NOT NULL,
    criado_em    TIMESTAMP     NOT NULL DEFAULT NOW(),

    CONSTRAINT ck_consultas_status  CHECK (status IN ('agendada', 'confirmada', 'realizada', 'cancelada', 'faltou')),
    CONSTRAINT ck_consultas_duracao CHECK (duracao_min BETWEEN 10 AND 240),
    CONSTRAINT ck_consultas_valor   CHECK (valor >= 0)
);

-- Regra de negócio: um médico não pode ter duas consultas ativas no mesmo horário
CREATE UNIQUE INDEX ux_consultas_medico_horario
    ON consultas (medico_id, data_hora)
    WHERE status <> 'cancelada';

CREATE TABLE prontuarios (
    id           SERIAL    PRIMARY KEY,
    consulta_id  INT       NOT NULL UNIQUE REFERENCES consultas(id),  -- 1:1 com consulta
    queixa       TEXT      NOT NULL,
    diagnostico  TEXT,
    prescricao   TEXT,
    registrado_em TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Índices para as consultas mais frequentes
CREATE INDEX ix_consultas_paciente ON consultas (paciente_id);
CREATE INDEX ix_consultas_data     ON consultas (data_hora);

-- 4) Dados de exemplo (opcional) -------------------------------
INSERT INTO especialidades (nome) VALUES
    ('Clínica Geral'), ('Cardiologia'), ('Pediatria');

INSERT INTO medicos (nome, crm, especialidade_id, valor_consulta) VALUES
    ('Dra. Ana Souza',   '123456-SP', 1, 200.00),
    ('Dr. Bruno Lima',   '654321-SP', 2, 350.00);

INSERT INTO pacientes (nome, cpf, data_nascimento, sexo, telefone, email) VALUES
    ('Carlos Pereira', '12345678901', '1985-04-12', 'M', '11999990000', 'carlos@email.com');

INSERT INTO consultas (paciente_id, medico_id, data_hora, valor) VALUES
    (1, 1, '2026-12-01 09:00', 200.00);

-- Exemplo de teste da regra (deve FALHAR com erro de CHECK):
-- INSERT INTO medicos (nome, crm, especialidade_id, valor_consulta)
--     VALUES ('Teste', '000000-SP', 1, -50);
