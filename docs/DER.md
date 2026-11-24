# Diagrama Entidade-Relacionamento (DER)

O diagrama abaixo está em [Mermaid](https://mermaid.js.org/) e é renderizado automaticamente pelo GitHub.

```mermaid
erDiagram
    ESPECIALIDADES ||--o{ MEDICOS : "classifica"
    PACIENTES     ||--o{ CONSULTAS : "agenda"
    MEDICOS       ||--o{ CONSULTAS : "realiza"
    CONSULTAS     ||--o| PRONTUARIOS : "gera"

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
        varchar status "agendada|confirmada|realizada|cancelada|faltou"
        numeric valor "CHECK >= 0"
        timestamp criado_em
    }
    PRONTUARIOS {
        int id PK
        int consulta_id FK, UK
        text queixa
        text diagnostico
        text prescricao
        timestamp registrado_em
    }
```

## Cardinalidades

| Relacionamento | Cardinalidade | Leitura |
|---|---|---|
| Especialidade → Médico | 1 : N | Uma especialidade tem vários médicos; cada médico tem uma especialidade principal. |
| Paciente → Consulta | 1 : N | Um paciente pode ter várias consultas; cada consulta é de um paciente. |
| Médico → Consulta | 1 : N | Um médico atende várias consultas; cada consulta tem um médico. |
| Consulta → Prontuário | 1 : 0..1 | Uma consulta gera no máximo um registro de prontuário (só quando é realizada). |

> Paciente e Médico têm um relacionamento **N:N** entre si, resolvido pela tabela associativa `consultas`.
