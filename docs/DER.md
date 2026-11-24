# Diagramas do banco de dados

| Diagrama | Imagem | PDF |
|---|---|---|
| MER — Modelo Entidade-Relacionamento (conceitual) | [mer-conceitual.png](mer-conceitual.png) | [mer-conceitual.pdf](mer-conceitual.pdf) |
| Modelo Lógico Relacional (3FN) | [modelo-logico.png](modelo-logico.png) | [modelo-logico.pdf](modelo-logico.pdf) |

## MER (conceitual)

![MER conceitual](mer-conceitual.png)

## Modelo lógico (tabelas, PK e FK)

![Modelo lógico](modelo-logico.png)

## Versão em Mermaid (renderizada pelo GitHub)

```mermaid
erDiagram
    ESPECIALIDADES ||--o{ MEDICOS : "classifica"
    PACIENTES      ||--o{ CONSULTAS : "agenda"
    MEDICOS        ||--o{ CONSULTAS : "realiza"
    CONSULTAS      ||--o| PRONTUARIOS : "gera"
    PRONTUARIOS    ||--o{ PRESCRICOES : "contém"
    MEDICAMENTOS   ||--o{ PRESCRICOES : "aparece em"

    ESPECIALIDADES {
        int id PK
        varchar nome UK
    }
    PACIENTES {
        int id PK
        varchar nome
        char cpf UK
        date data_nascimento
        char sexo
        varchar telefone
        varchar email
        timestamp criado_em
    }
    MEDICOS {
        int id PK
        varchar nome
        varchar crm UK
        int especialidade_id FK
        numeric valor_consulta "CHECK >= 0"
        boolean ativo
    }
    CONSULTAS {
        int id PK
        int paciente_id FK
        int medico_id FK
        timestamp data_hora
        int duracao_min
        varchar status
        numeric valor "CHECK >= 0"
        timestamp criado_em
    }
    PRONTUARIOS {
        int id PK
        int consulta_id FK, UK
        text queixa
        text diagnostico
        text observacoes
        timestamp registrado_em
    }
    MEDICAMENTOS {
        int id PK
        varchar nome
        varchar principio_ativo
        varchar apresentacao
    }
    PRESCRICOES {
        int prontuario_id PK, FK
        int medicamento_id PK, FK
        varchar dosagem
        varchar posologia
        int duracao_dias "CHECK > 0"
    }
```

## Cardinalidades

| Relacionamento | Tipo | Cardinalidade (mín, máx) | Leitura |
|---|---|---|---|
| Especialidade — *pertence* — Médico | 1:N | (1,1) — (0,N) | Todo médico tem exatamente uma especialidade; uma especialidade pode ter vários médicos (ou nenhum). |
| Paciente — *agenda* — Consulta | 1:N | (1,1) — (0,N) | Toda consulta é de um paciente; um paciente pode ter várias consultas. |
| Médico — *realiza* — Consulta | 1:N | (1,1) — (0,N) | Toda consulta tem um médico; um médico atende várias consultas. |
| Consulta — *gera* — Prontuário | 1:1 | (1,1) — (0,1) | Uma consulta gera no máximo um prontuário (só quando é realizada). |
| Prontuário — *prescreve* — Medicamento | N:N | (0,N) — (0,N) | Uma receita pode ter vários remédios; um remédio aparece em várias receitas. Vira a tabela `prescricoes`. |
