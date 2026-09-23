---
title: Sistema de Trilha de Disciplinas (Curriculum Advisor)
date: 2026-09-21
---

# Sistema de Trilha de Disciplinas (Curriculum Advisor)

PjBL 1 — Programação Lógica e Funcional (PUC).

Base de conhecimento em Prolog que representa a grade curricular do curso e o
histórico de alunos fictícios, capaz de responder consultas como *"quais
disciplinas eu já posso cursar?"*, *"quanto crédito eu já tenho?"* e *"existe um
caminho válido daqui até a formatura?"*.

O projeto é organizado em três camadas:

| Camada | Arquivo | Responsabilidade |
|---|---|---|
| 1 — Fatos | `src/curriculum.pl` | O que existe: disciplinas, pré-requisitos, histórico dos alunos |
| 2 — Elegibilidade | `src/elegibilidade.pl` | O que é permitido agora: regras diretas sobre o histórico |
| 3 — Trilhas | `src/trilhas.pl` | O que é possível ao longo do tempo: fecho transitivo + backtracking |

## Requisitos

- [SWI-Prolog](https://www.swi-prolog.org/) (versão 8 ou superior).
- Nenhuma biblioteca externa. Apenas predicados nativos e `library(lists)`,
  autocarregada pelo SWI (`findall/3`, `forall/2`, `include/3`, `subtract/3`,
  `member/2`, `append/3`).

## Estrutura do projeto

```
PjBL---PROLOG/
├── src/
│   ├── curriculum.pl      (Camada 1: fatos)
│   ├── elegibilidade.pl   (Camada 2: regras)
│   ├── trilhas.pl         (Camada 3: recursão + backtracking)
│   └── main.pl            (consultas de demonstração, demo/0)
├── tests/
│   └── consultas_teste.pl (roteiro de consultas com resultado esperado)
├── docs/
│   └── decisoes.md        (decisões de modelagem + limitações conhecidas)
└── README.md
```

## Como carregar

`src/main.pl` é o ponto de entrada. As camadas se carregam em cascata, cada uma
consultando a anterior:

```
main.pl → trilhas.pl → elegibilidade.pl → curriculum.pl
```

Basta consultar `main.pl` para ter o projeto inteiro na base.

A partir da raiz do repositório:

```bash
swipl src/main.pl
```

Ou, de dentro de uma sessão SWI-Prolog já aberta:

```prolog
?- consult('src/main.pl').
```

Os `:- consult(...)` usam caminhos relativos ao arquivo que os contém, então
carregar de qualquer diretório funciona.

Para rodar a demonstração das três camadas:

```prolog
?- demo.
```

## Alunos de teste

Três perfis diferentes, todos definidos por fatos `cursou/2` em
`src/curriculum.pl`:

| Aluno | Perfil | Situação |
|---|---|---|
| `julia` | Atrasada / com DP | Cursou 12 disciplinas, mas ficou com pendências de semestres anteriores (`raciocinio_algoritmo`, `arquitetura_de_banco_de_dados`) |
| `eduardo` | No ritmo da grade | Cursou 13 disciplinas, seguindo a ordem sugerida |
| `caio` | Adiantado | Cursou as 20 disciplinas da base, incluindo todas as eletivas |

## Consultas por camada

### Camada 1 — Base de fatos

Listar todas as disciplinas de um semestre sugerido específico:

```prolog
?- findall(D, disciplina(D, _, _, 2), L).
```

Ver os dados completos de uma disciplina:

```prolog
?- disciplina(resolucao_de_problemas_com_grafos, Tipo, Creditos, Semestre).
```

Listar só as eletivas:

```prolog
?- findall(D, disciplina(D, eletiva, _, _), L).
```

### Camada 2 — Regras de elegibilidade

```prolog
?- alunos(L).
?- prerequisitos_ok(eduardo, resolucao_de_problemas_com_grafos).
?- pode_cursar(julia, resolucao_de_problemas_de_natureza_discreta).
?- disciplinas_liberadas(eduardo, L).
?- disciplinas_pendentes(julia, L).
?- creditos_cursados(caio, Total).
```

Consulta com aluno inexistente falha limpo, sem exceção:

```prolog
?- disciplinas_liberadas(fulano, L).
false.
```

`pode_cursar/2` é o predicado onde a negação por falha é decisiva: ele exige
`\+ cursou(Aluno, Disciplina)`. Mudar o histórico do aluno muda o resultado —
uma disciplina elegível deixa de ser listada assim que passa a constar como
cursada.

### Camada 3 — Fecho transitivo e trilhas

Pré-requisitos diretos **e** indiretos (a cadeia de profundidade 3 da base é
`resolucao_de_problemas_com_grafos` → `modelagem_de_fenomenos_fisicos` →
`resolucao_de_problemas_de_natureza_discreta` →
`resolucao_de_problemas_com_logica_matematica`):

```prolog
?- prerequisito_transitivo(resolucao_de_problemas_com_grafos, A).
```

Todos os ancestrais de uma vez:

```prolog
?- setof(A, prerequisito_transitivo(resolucao_de_problemas_com_grafos, A), L).
```

Detecção de ciclo na base de pré-requisitos:

```prolog
?- existe_ciclo(resolucao_de_problemas_com_grafos).
```

Uma trilha válida (sequência de semestres, respeitando pré-requisitos e o teto
de créditos por semestre):

```prolog
?- trilha_valida(julia, 20, Trilha).
```

Múltiplas trilhas válidas para o mesmo aluno:

```prolog
?- findall(T, trilha_valida(julia, 20, T), Trilhas), length(Trilhas, N).
```

A busca de `trilha_valida/3` tem um limite de semestres simulados como rede de
segurança contra explosão combinatória. O limite fica no fato `max_semestres/1`,
no topo de `src/trilhas.pl`:

```prolog
?- max_semestres(N).
N = 12.
```

## Testes

`tests/consultas_teste.pl` é o **roteiro** de consultas de teste: lista, camada
por camada, as consultas a digitar e o resultado esperado de cada uma. As
consultas são executadas manualmente no terminal, depois de carregar o projeto:

```bash
swipl src/main.pl
```

O roteiro cobre:

| Camada | Consultas |
|---|---|
| 1 | `disciplinas_por_semestre/2` para um semestre sugerido |
| 2 | `disciplinas_liberadas/2` e `disciplinas_pendentes/2` para `eduardo` e `caio`, que dão resultados opostos, e o caso em que `\+ cursou/2` decide o resultado de `pode_cursar/2` |
| 3 | `prerequisito_transitivo/2` na cadeia de profundidade 3, `trilha_valida/3` para `eduardo` e `julia`, e a detecção de ciclo |

As consultas estão comentadas no arquivo: copie a que interessa e cole no
prompt. Dois blocos do roteiro pedem que fatos sejam acrescentados à base antes
da consulta — o `cursou/2` que torna a negação decisiva, na Camada 2, e os três
`prerequisito/2` circulares da detecção de ciclo. O próprio roteiro indica onde
inseri-los.

> Os `prerequisito/2` circulares deixam a base malformada de propósito. Depois
> de usá-los, reinicie o interpretador antes de rodar as outras consultas.

## Documentação

As decisões de modelagem (por que `prerequisito/2` em vez de lista, `findall`
vs `setof`, por que não usamos `assert/retract` na simulação de trilha) e as
limitações conhecidas do sistema estão em
[docs/decisoes.md](docs/decisoes.md).

## Enunciado

[PjBL 1.pdf](https://github.com/user-attachments/files/32293574/PjBL.1.pdf)
