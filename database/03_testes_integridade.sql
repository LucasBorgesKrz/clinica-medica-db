-- =============================================================
-- Testes de integridade (BÔNUS) — executar DEPOIS do 02_dados_teste.sql
--   psql -U postgres -d clinica_medica -f database/03_testes_integridade.sql
--
-- Todos os comandos abaixo DEVEM FALHAR. Cada erro mostra o banco
-- protegendo a integridade dos dados.
-- =============================================================

\set ON_ERROR_STOP off

\echo '--- Teste 1: FK inexistente (médico com especialidade 99, que não existe)'
INSERT INTO medicos (nome, crm, especialidade_id, valor_consulta)
VALUES ('Dr. Fantasma', '999999-MA', 99, 300.00);

\echo '--- Teste 2: FK inexistente (consulta para paciente 500, que não existe)'
INSERT INTO consultas (paciente_id, medico_id, data_hora, valor)
VALUES (500, 1, '2026-12-10 09:00', 200.00);

\echo '--- Teste 3: PK duplicada (especialidade com id 1, que já existe)'
INSERT INTO especialidades (id, nome) VALUES (1, 'Dermatologia');

\echo '--- Teste 4: PK composta duplicada (mesmo medicamento 2x na mesma receita)'
INSERT INTO prescricoes (prontuario_id, medicamento_id, dosagem, posologia, duracao_dias)
VALUES (1, 2, '2 cápsulas', 'de 12 em 12 horas', 5);

\echo '--- Teste 5: excluir registro pai que possui filhos (deixaria consultas órfãs)'
DELETE FROM pacientes WHERE id = 1;

\echo '--- Teste 6: chave única duplicada (CPF já cadastrado)'
INSERT INTO pacientes (nome, cpf, data_nascimento, telefone)
VALUES ('Carlos Clone', '12345678901', '1990-01-01', '98999990009');

\echo '--- Teste 7: regra de negócio (médico com 2 consultas no mesmo horário)'
INSERT INTO consultas (paciente_id, medico_id, data_hora, valor)
VALUES (2, 1, '2026-12-01 09:00', 200.00);

\echo '--- Teste 8: CHECK (valor de consulta negativo)'
INSERT INTO medicos (nome, crm, especialidade_id, valor_consulta)
VALUES ('Dr. Desconto', '888888-MA', 1, -50.00);

\echo '--- Conferência: nenhuma linha inválida foi gravada'
SELECT 'especialidades' AS tabela, COUNT(*) FROM especialidades
UNION ALL SELECT 'pacientes',   COUNT(*) FROM pacientes
UNION ALL SELECT 'medicos',     COUNT(*) FROM medicos
UNION ALL SELECT 'consultas',   COUNT(*) FROM consultas
UNION ALL SELECT 'prescricoes', COUNT(*) FROM prescricoes;
