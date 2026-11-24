-- =============================================================
-- Projeto: Sistema de Clínica Médica
-- Script DDL — criação do banco e das tabelas (PostgreSQL 14+)
-- Modelo lógico normalizado até a 3ª Forma Normal (3FN)
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

-- 2) Tabelas independentes (não possuem FK) --------------------

CREATE TABLE especialidades (
    id    SERIAL,
    nome  VARCHAR(80) NOT NULL,

    CONSTRAINT pk_especialidades      PRIMARY KEY (id),
    CONSTRAINT uq_especialidades_nome UNIQUE (nome)
);

CREATE TABLE pacientes (
    id               SERIAL,
    nome             VARCHAR(120) NOT NULL,
    cpf              CHAR(11)     NOT NULL,
    data_nascimento  DATE         NOT NULL,
    sexo             CHAR(1),
    telefone         VARCHAR(20)  NOT NULL,
    email            VARCHAR(120),
    criado_em        TIMESTAMP    NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_pacientes                PRIMARY KEY (id),
    CONSTRAINT uq_pacientes_cpf            UNIQUE (cpf),
    CONSTRAINT ck_pacientes_cpf_numerico   CHECK (cpf ~ '^[0-9]{11}$'),
    CONSTRAINT ck_pacientes_sexo           CHECK (sexo IN ('M', 'F', 'O')),
    CONSTRAINT ck_pacientes_nascimento     CHECK (data_nascimento >= DATE '1900-01-01'),
    CONSTRAINT ck_pacientes_email          CHECK (email IS NULL OR email LIKE '%_@_%._%')
);

CREATE TABLE medicamentos (
    id               SERIAL,
    nome             VARCHAR(100) NOT NULL,   -- nome comercial ou genérico
    principio_ativo  VARCHAR(100) NOT NULL,
    apresentacao     VARCHAR(60)  NOT NULL,   -- ex: comprimido 500 mg

    CONSTRAINT pk_medicamentos                  PRIMARY KEY (id),
    CONSTRAINT uq_medicamentos_nome_apresentacao UNIQUE (nome, apresentacao)
);

-- 3) Tabelas dependentes (possuem FK) --------------------------

CREATE TABLE medicos (
    id               SERIAL,
    nome             VARCHAR(120)  NOT NULL,
    crm              VARCHAR(15)   NOT NULL,   -- ex: 123456-MA
    especialidade_id INT           NOT NULL,
    valor_consulta   NUMERIC(10,2) NOT NULL,
    ativo            BOOLEAN       NOT NULL DEFAULT TRUE,

    CONSTRAINT pk_medicos                PRIMARY KEY (id),
    CONSTRAINT uq_medicos_crm            UNIQUE (crm),
    CONSTRAINT fk_medicos_especialidade  FOREIGN KEY (especialidade_id)
                                         REFERENCES especialidades (id),
    CONSTRAINT ck_medicos_valor_consulta CHECK (valor_consulta >= 0)
);

-- Consulta: entidade associativa entre Paciente e Médico.
-- Usa PK própria (id) porque o mesmo paciente pode consultar o mesmo
-- médico várias vezes; a identidade da consulta é o par (médico, data_hora).
CREATE TABLE consultas (
    id           SERIAL,
    paciente_id  INT           NOT NULL,
    medico_id    INT           NOT NULL,
    data_hora    TIMESTAMP     NOT NULL,
    duracao_min  INT           NOT NULL DEFAULT 30,
    status       VARCHAR(15)   NOT NULL DEFAULT 'agendada',
    valor        NUMERIC(10,2) NOT NULL,   -- valor cobrado na data (histórico de preço)
    criado_em    TIMESTAMP     NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_consultas          PRIMARY KEY (id),
    CONSTRAINT fk_consultas_paciente FOREIGN KEY (paciente_id) REFERENCES pacientes (id),
    CONSTRAINT fk_consultas_medico   FOREIGN KEY (medico_id)   REFERENCES medicos (id),
    CONSTRAINT ck_consultas_status   CHECK (status IN ('agendada', 'confirmada', 'realizada', 'cancelada', 'faltou')),
    CONSTRAINT ck_consultas_duracao  CHECK (duracao_min BETWEEN 10 AND 240),
    CONSTRAINT ck_consultas_valor    CHECK (valor >= 0)
);

-- Regra de negócio: um médico não pode ter duas consultas ativas no mesmo horário
CREATE UNIQUE INDEX ux_consultas_medico_horario
    ON consultas (medico_id, data_hora)
    WHERE status <> 'cancelada';

-- Prontuário: 1 por consulta (FK + UNIQUE = relacionamento 1:1).
-- Não guarda paciente_id nem medico_id: eles já são obtidos pela consulta
-- (guardar de novo seria dependência transitiva -> viola a 3FN).
CREATE TABLE prontuarios (
    id             SERIAL,
    consulta_id    INT       NOT NULL,
    queixa         TEXT      NOT NULL,
    diagnostico    TEXT,
    observacoes    TEXT,
    registrado_em  TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_prontuarios          PRIMARY KEY (id),
    CONSTRAINT uq_prontuarios_consulta UNIQUE (consulta_id),
    CONSTRAINT fk_prontuarios_consulta FOREIGN KEY (consulta_id) REFERENCES consultas (id)
);

-- Prescrição: tabela associativa do relacionamento N:N Prontuário x Medicamento.
-- PK composta pelas duas FKs (o mesmo remédio não aparece 2x na mesma receita).
CREATE TABLE prescricoes (
    prontuario_id   INT          NOT NULL,
    medicamento_id  INT          NOT NULL,
    dosagem         VARCHAR(40)  NOT NULL,   -- ex: 1 comprimido
    posologia       VARCHAR(80)  NOT NULL,   -- ex: de 8 em 8 horas
    duracao_dias    INT          NOT NULL,

    CONSTRAINT pk_prescricoes             PRIMARY KEY (prontuario_id, medicamento_id),
    CONSTRAINT fk_prescricoes_prontuario  FOREIGN KEY (prontuario_id)  REFERENCES prontuarios (id),
    CONSTRAINT fk_prescricoes_medicamento FOREIGN KEY (medicamento_id) REFERENCES medicamentos (id),
    CONSTRAINT ck_prescricoes_duracao     CHECK (duracao_dias > 0)
);

-- 4) Índices nas FKs mais consultadas -------------------------
CREATE INDEX ix_medicos_especialidade    ON medicos (especialidade_id);
CREATE INDEX ix_consultas_paciente       ON consultas (paciente_id);
CREATE INDEX ix_consultas_data           ON consultas (data_hora);
CREATE INDEX ix_prescricoes_medicamento  ON prescricoes (medicamento_id);
