---
title: Decisões de Modelagem e Limitações Conhecidas
date: 2026-09-21
---

# Decisões de Modelagem e Limitações Conhecidas

Documento exigido pela Seção 7 do enunciado. Registra **por que** a base foi
modelada do jeito que foi e **o que o sistema ainda não faz**.

---

## 1. Camada 1 — Base de fatos

### 1.1 Um fato `prerequisito/2` por par, nunca uma lista

Modelamos pré-requisitos como fatos binários:

```prolog
prerequisito(resolucao_de_problemas_com_grafos, modelagem_de_fenomenos_fisicos).
prerequisito(modelagem_de_fenomenos_fisicos, resolucao_de_problemas_de_natureza_discreta).
```

e **não** como `prerequisito(disciplina, [a, b, c])`.

**Por quê:** com um fato por par, a relação fica diretamente consultável pelo
motor de unificação do Prolog. `prerequisito(D, P)` enumera por backtracking
todos os pares, `forall/2` verifica todos de uma vez e a recursão do fecho
transitivo (Camada 3) encadeia `prerequisito(D, I), prerequisito_transitivo(I, A)`
sem precisar percorrer lista manualmente. Com a versão em lista, toda regra da
Camada 2 e 3 precisaria de um `member/2` a mais e a recursão do fecho ficaria
bem mais confusa. É o caso clássico de "muitos fatos pequenos" ganhar de "um
fato com estrutura complexa dentro".

### 1.2 Átomos em `snake_case`, sem aspas duplas

Todo nome de disciplina e de aluno é um átomo (`programacao_web`, `julia`),
nunca `"programacao_web"`.

**Por quê:** em Prolog clássico, texto entre aspas duplas é uma lista de códigos
de caractere, não um átomo — `disciplina("x", ...)` e `disciplina(x, ...)` não
unificam. Usar átomos garante que unificação, indexação e comparação funcionem
como esperado em todas as camadas.

### 1.3 Aridade de `disciplina/4`

`disciplina(Nome, Tipo, Creditos, SemestreSugerido)`, com `Tipo` em
`{obrigatoria, eletiva}`, créditos inteiros e semestre sugerido inteiro.

Optamos por um único fato de aridade 4 em vez de fatos separados
(`creditos/2`, `tipo/2`, `semestre/2`) porque os quatro atributos sempre
existem juntos e nunca são consultados isoladamente sem o nome da disciplina.
Quando só um campo interessa, o padrão `disciplina(D, _, C, _)` resolve.

### 1.4 Grade: 20 disciplinas, 6 semestres, 5 eletivas

A base reproduz a grade real do curso nos semestres 1 a 4 (obrigatórias) e
acrescenta eletivas nos semestres 4 a 6. As eletivas de semestres mais altos
(`introducao_a_criptografia`, `ciencias_forenses`,
`criacao_de_trilhas_sonoras_para_jogos`, `astrologia_para_todos`) existem
principalmente para dar volume à Camada 3 — são disciplinas sem pré-requisito,
o que amplia o espaço de busca de `trilha_valida/3` sem introduzir dependências
artificiais.

### 1.5 Cadeia de pré-requisitos de profundidade 3

A única cadeia profunda da base é intencional:

```
resolucao_de_problemas_com_grafos
  -> modelagem_de_fenomenos_fisicos
    -> resolucao_de_problemas_de_natureza_discreta
      -> resolucao_de_problemas_com_logica_matematica
```

É ela que exercita a recursão de `prerequisito_transitivo/2`: consultar os
ancestrais de `resolucao_de_problemas_com_grafos` exige três níveis de
encadeamento, não apenas o caso base.

### 1.6 Três perfis de aluno

- **`julia`** — atrasada / com DP: cursou disciplinas do 3º e 4º semestre mas
  deixou pendências do 1º e 2º (`raciocinio_algoritmo`,
  `arquitetura_de_banco_de_dados`). Serve para testar que
  `disciplinas_pendentes/2` não assume ordem cronológica do histórico.
- **`eduardo`** — no ritmo: histórico contíguo até o 3º semestre. É o caso
  "normal" de `disciplinas_liberadas/2`.
- **`caio`** — adiantado: cursou tudo. Serve como caso de borda oposto —
  `disciplinas_liberadas/2` e `disciplinas_pendentes/2` devem devolver `[]`, e
  `trilha_valida/3` precisa lidar com "não há nada a cursar".

O histórico é um fato `cursou/2` por par aluno/disciplina, pelo mesmo motivo do
item 1.1.

---

## 2. Camada 2 — Regras de elegibilidade

### 2.1 `forall/2` para verificar, nunca para coletar

`prerequisitos_ok/2` usa:

```prolog
forall(prerequisito(Disciplina, Prerequisito), cursou(Aluno, Prerequisito))
```

**Por quê:** a pergunta é "todos os pré-requisitos foram cursados?", que é uma
verificação de propriedade sobre um conjunto, exatamente o que `forall/2` faz.
Um efeito colateral desejado: disciplinas **sem** nenhum pré-requisito passam
vacuamente (`forall` sobre conjunto vazio é verdadeiro), que é o comportamento
correto — uma disciplina de 1º semestre é elegível para qualquer aluno.

`forall/2` não deixa nada instanciado ao terminar; para coletar valores usamos
`findall/3`, nunca `forall/2`.

### 2.2 Negação por falha (`\+`) sempre com a variável já instanciada

`pode_cursar/2` chama `disciplina(Disciplina, _, _, _)` **antes** de
`\+ cursou(Aluno, Disciplina)`.

**Por quê:** `\+` é negação por falha, não negação lógica. Com `Disciplina`
ainda livre, `\+ cursou(Aluno, Disciplina)` pergunta "não existe *nenhuma*
disciplina cursada por esse aluno", que é uma pergunta completamente diferente
da pretendida e falha para qualquer aluno com histórico. Gerando a disciplina
primeiro, a negação opera sobre um termo fechado e significa o que queremos:
"esta disciplina específica não foi cursada".

Essa é também a consulta em que a negação é decisiva: acrescentar um
`cursou(Aluno, D)` à base remove `D` de `disciplinas_liberadas/2`.

### 2.3 `findall/3` em vez de `setof/3`

Escolhemos `findall/3` em `disciplinas_liberadas/2` e `disciplinas_pendentes/2`.

**Por quê:**

| | `findall/3` | `setof/3` | `bagof/3` |
|---|---|---|---|
| Ordem | ordem de solução | ordenada por termo | ordem de solução |
| Duplicatas | mantém | remove | mantém |
| Sem soluções | devolve `[]` | **falha** | **falha** |
| Variáveis livres | ignora (existencial) | agrupa (`^` para suprimir) | agrupa |

Dois motivos pesaram:

1. **Sem soluções deve dar `[]`, não falhar.** Para `caio` (adiantado),
   `disciplinas_liberadas(caio, L)` tem que devolver `L = []`. Com `setof/3` o
   predicado falharia, e o chamador não conseguiria distinguir "aluno não
   existe" de "aluno não tem nada liberado".
2. **Não há duplicatas a remover.** `pode_cursar/2` gera cada disciplina uma
   única vez, porque `disciplina/4` tem um fato por disciplina. `setof/3` só
   acrescentaria custo de ordenação.

Onde ordenação e deduplicação importam — enumerar ancestrais no fecho
transitivo, que *pode* repetir quando há múltiplos caminhos até o mesmo
ancestral — usamos `setof/3` na consulta, como documentado no README.

### 2.4 `aluno_existe/1` como guarda de falha limpa

Consultas com aluno inexistente devem falhar limpo (`false`), não lançar
exceção. Por isso as regras da Camada 2 começam checando se o aluno tem ao
menos um fato `cursou/2`. O corte no corpo evita que a guarda gere soluções
redundantes por backtracking sobre cada disciplina cursada.

**Limitação conhecida dessa escolha:** um aluno real recém-matriculado, sem
nenhum `cursou/2`, é indistinguível de um aluno inexistente. Para o escopo
deste trabalho isso é aceitável; a alternativa seria um fato `aluno/1`
explícito na Camada 1 (ver Seção 5).

---

## 3. Camada 3 — Fecho transitivo e trilhas

### 3.1 Fecho transitivo com caso base = pré-requisito direto

```prolog
prerequisito_transitivo(D, A) :- prerequisito(D, A).
prerequisito_transitivo(D, A) :- prerequisito(D, I), prerequisito_transitivo(I, A).
```

O caso base é o pré-requisito direto, e a recursão **avança sempre um passo
pela relação** antes de chamar a si mesma. A recursão é bem fundada sobre uma
base acíclica: cada chamada recursiva encurta o caminho restante até a raiz da
cadeia.

Colocamos a chamada recursiva **depois** do `prerequisito/2` de propósito. A
formulação `prerequisito_transitivo(D, I), prerequisito(I, A)` (recursão à
esquerda) entraria em recursão infinita antes de tocar qualquer fato.

### 3.2 `existe_ciclo/1` por consulta reflexiva

```prolog
existe_ciclo(D) :- prerequisito_transitivo(D, D).
```

Uma disciplina que é seu próprio ancestral transitivo caracteriza ciclo na base
— dado malformado. A checagem é declarativa e reaproveita o fecho, sem código
novo.

**Ver a limitação 4.8: com a implementação atual, esse predicado detecta o
ciclo apenas se a busca terminar.**

### 3.3 Sem `assert/retract` na simulação da trilha

Esta foi a decisão de projeto mais importante da Camada 3.

A tentação é marcar disciplinas como cursadas com `assert/1` durante a
simulação, e desmarcar com `retract/1`. **Não fizemos isso.** O estado da
simulação (`Cursadas`, `Pendentes`) viaja como **argumento** das chamadas
recursivas de `gerar_trilha/5`:

```prolog
gerar_trilha(Pendentes, Cursadas, MaxCreditos, SemestresRestantes, [Semestre|Resto]) :-
    ...
    subtract(Pendentes, Semestre, NovoPendentes),
    append(Cursadas, Semestre, NovasCursadas),
    gerar_trilha(NovoPendentes, NovasCursadas, MaxCreditos, N1, Resto).
```

**Por quê:** o backtracking do Prolog desfaz **unificação de variáveis**
automaticamente, mas **não desfaz alterações na base de fatos**. Com
`assert/retract`, ao retroceder para tentar outra composição de semestre, os
fatos assertados continuariam lá, e a segunda trilha seria gerada sobre um
estado sujo da primeira — as trilhas enumeradas por `findall/3` sairiam
simplesmente erradas. Passando o estado por parâmetro, retroceder restaura o
estado anterior de graça, e a enumeração de múltiplas trilhas é correta por
construção.

Consequência aceita: cópia de listas a cada semestre simulado. Para uma grade
de 20 disciplinas o custo é irrelevante perto da correção que se ganha.

### 3.4 Limite de semestres simulados como rede de segurança

`gerar_trilha/5` carrega um contador `SemestresRestantes` que decresce a cada
semestre e exige `SemestresRestantes > 0`.

**Por quê:** mesmo com base acíclica e correta, o número de trilhas possíveis
cresce combinatoriamente (cada semestre é um subconjunto das disciplinas
liberadas que cabe no teto de créditos). O limite é uma garantia **estrutural**
de terminação, independente da qualidade dos dados: a busca para porque a
profundidade acabou, não porque os dados são bem-comportados.

### 3.5 Semestre gerado como subconjunto sob orçamento de créditos

`subconjunto_com_credito/3` percorre as disciplinas liberadas e, para cada uma,
oferece duas alternativas por backtracking: **incluir** (descontando os
créditos do orçamento restante) ou **pular**. O teto de créditos é imposto
durante a construção (`Creditos =< Max`), não depois — cada semestre já nasce
válido, sem gerar-e-testar.

É daqui que sai a enumeração de múltiplas trilhas: cada composição diferente de
semestre é um ponto de escolha.

---

## 4. Limitações conhecidas

Esta seção é deliberadamente literal sobre o estado atual do código.

### 4.1 `aluno_existe/1` usa átomo no lugar de variável

`src/elegibilidade.pl:2` — a cabeça é `aluno_existe(aluno)` e o corpo é
`cursou(aluno, _)`, com `aluno` em minúscula. Em Prolog isso é o **átomo**
`aluno`, não a variável `Aluno`. Como não existe nenhum fato
`cursou(aluno, _)`, o predicado falha para qualquer entrada. Efeito em cascata:
`prerequisitos_ok/2`, `pode_cursar/2` e `disciplinas_liberadas/2` falham para
todos os três alunos de teste. A forma correta é
`aluno_existe(Aluno) :- cursou(Aluno, _), !.`

### 4.2 `disciplinas_pendentes/2` chama predicado inexistente

`src/elegibilidade.pl:33-41` — o corpo do `findall/3` chama `obrigatorio/1`,
que não está definido em nenhuma camada, e usa o átomo `disciplina` como
template em vez de uma variável. A consulta levanta
`existence_error(procedure, obrigatorio/1)`. O predicado deveria filtrar por
`disciplina(D, obrigatoria, _, _)` e negar `cursou(Aluno, D)`.

### 4.3 `creditos_cursados/2` chama predicados inexistentes

`src/elegibilidade.pl:44-53` — chama `creditos/2` (não definido; os créditos
estão no 3º argumento de `disciplina/4`) e `sum_lista/2` (o predicado nativo do
SWI é `sum_list/2`). Também usa o átomo `disciplina` no lugar de variável.

### 4.4 `demo/0` itera sobre `aluno/1`, que não existe

`src/main.pl:10` — o `forall/2` da demonstração percorre `aluno(Aluno)`, mas a
Camada 1 não define `aluno/1`. A alternativa sem mudar a Camada 1 é
`setof(A, D^cursou(A, D), Alunos)`.

### 4.5 O caso base de `gerar_trilha/5` falha sempre

`src/trilhas.pl:16` — `gerar_trilha([], _, _, _, []) :- false.` O `false` no
corpo torna o caso base impossível de satisfazer, então nenhuma recursão chega
a fechar e `trilha_valida/3` nunca produz uma trilha completa. O caso base
correto é o fato puro `gerar_trilha([], _, _, _, []).` — lista de pendentes
vazia significa trilha concluída.

### 4.6 Limite de semestres fixo em 6 e não parametrizado

`src/trilhas.pl:14` — `trilha_valida/3` passa `6` literal como limite. O
enunciado sugere 12. Além de ser baixo demais para um aluno atrasado com teto
de créditos apertado (podendo fazer a busca falhar por exaustão de profundidade
em vez de por impossibilidade real), o valor deveria ser uma constante nomeada
ou um argumento de `trilha_valida/4`.

### 4.7 `subconjunto_com_credito/3` sem poda

`src/trilhas.pl:31-38` — a enumeração incluir/pular gera, no pior caso, `2^n`
subconjuntos para `n` disciplinas liberadas. Não há poda por créditos mínimos
nem preferência por semestres "cheios", e semestres vazios só são descartados
depois de gerados (`Semestre \= []` em `gerar_trilha/5`). Com a base atual isso
é tolerável; com uma grade completa de 8 semestres, não seria.

### 4.8 `prerequisito_transitivo/2` não tem conjunto de visitados

`src/trilhas.pl:1-6` — a recursão é bem fundada **apenas** sobre base acíclica.
Se a base contiver um ciclo, `prerequisito_transitivo/2` entra em recursão
infinita, e `existe_ciclo/1` trava em vez de responder `true`. Ou seja: na base
atual (acíclica, 3 fatos `prerequisito/2`) o predicado funciona, mas ele não
cumpre o papel de **detectar** dado malformado, que é justamente o cenário para
o qual foi escrito. A correção é carregar uma lista de visitados e falhar (ou
sinalizar) ao reencontrar um nó, com um predicado auxiliar de aridade 3.

### 4.9 Divergências na base de fatos

- `src/curriculum.pl:19` — `criacao_de_trilhas_sonoras_para_jogos` está
  cadastrada com tipo `eletivas` (plural), fora do domínio
  `{obrigatoria, eletiva}`. Qualquer consulta que filtre por `eletiva` ignora
  essa disciplina.
- `src/curriculum.pl:16` — `game_desing` (grafia de `game_design`). Não quebra
  nada, mas o átomo está escrito errado em todas as referências.

### 4.10 `tests/consultas_teste.pl` ainda está vazio

Os casos de teste obrigatórios da Seção 8 do enunciado — incluindo o arquivo
separado com `prerequisito/2` circular proposital para exercitar
`existe_ciclo/1` — não foram escritos.

### 4.11 Só existe uma cadeia de pré-requisitos

A base tem 3 fatos `prerequisito/2`, todos na mesma cadeia linear. Nenhuma
disciplina tem **múltiplos** pré-requisitos diretos, então o `forall/2` de
`prerequisitos_ok/2` nunca é testado com mais de um item, e o fecho transitivo
nunca precisa lidar com caminhos convergentes (onde `setof/3` faria diferença
real sobre `findall/3`).

### 4.12 Sem modelagem de equivalência entre currículos

O enunciado cita equivalência de disciplinas entre grades antiga e nova como
exemplo de decisão em aberto. Não modelamos isso: `cursou/2` é comparado por
identidade de átomo. Uma extensão natural seria um fato
`equivale(DisciplinaAntiga, DisciplinaNova)` e uma regra `cursou_equivalente/2`
que fecha por essa relação — deliberadamente fora do escopo desta entrega.

### 4.13 Sem nota, reprovação, co-requisito ou piso de créditos

O sistema conhece apenas "cursou" ou "não cursou". Não há nota, não há
reprovação (uma disciplina cursada é sempre aprovada), não há co-requisito
(disciplinas que devem ser feitas no mesmo semestre) nem piso de créditos por
semestre.

---

## 5. Decisões em aberto

- **Fato `aluno/1` explícito na Camada 1.** Resolveria a limitação 2.4 (aluno
  novo sem histórico) e a 4.4 (`demo/0`), ao custo de um dado redundante que
  precisa ser mantido em sincronia com `cursou/2`.
- **Constante nomeada para o limite de semestres.** Um fato
  `max_semestres(12).` na Camada 1 deixaria a rede de segurança da Seção 3.4
  explícita e ajustável sem editar a Camada 3.
- **`trilha_valida/4` com o limite como argumento.** Permitiria demonstrar, em
  teste, que a busca de fato para quando o limite se esgota.
