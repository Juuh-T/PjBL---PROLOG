---
title: Decisões de Modelagem e Limitações Conhecidas
date: 2026-09-21
---

# Decisões de Modelagem e Limitações Conhecidas

Documento exigido pela Seção 7 do enunciado. Registra **por que** a base foi
modelada do jeito que foi e **o que o sistema ainda não faz**.

> Os arquivos de `src/` não levam comentários: toda a justificativa de projeto
> está reunida aqui, e as seções abaixo citam os predicados pelo nome e aridade
> para que a leitura do código possa ser acompanhada em paralelo.

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

### 1.7 `disciplinas_por_semestre/2` fica em `main.pl`, não em `curriculum.pl`

O enunciado define a Camada 1 como "apenas fatos (sem regras)". A consulta que
lista as disciplinas de um semestre sugerido é uma regra, então não pode morar
em `curriculum.pl` sem violar essa separação — mesmo sendo, conceitualmente,
uma consulta sobre a Camada 1.

Colocamos em `main.pl`, que o enunciado descreve como o arquivo de consultas de
demonstração. Ela devolve `[]` para um semestre sem disciplinas em vez de
falhar, pelo mesmo motivo do `findall/3` da Seção 2.3.

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

### 3.1 Fecho transitivo com lista de visitados

```prolog
prerequisito_transitivo(D, A) :-
    prerequisito_transitivo(D, A, [D]).

prerequisito_transitivo(D, A, _) :-
    prerequisito(D, A).
prerequisito_transitivo(D, A, Visitados) :-
    prerequisito(D, I),
    \+ memberchk(I, Visitados),
    prerequisito_transitivo(I, A, [I|Visitados]).
```

O predicado público tem aridade 2, como o enunciado exige, e delega para um
auxiliar de aridade 3 que carrega a lista de nós já visitados **no caminho
atual**.

O caso base é o pré-requisito direto, e a recursão **avança sempre um passo
pela relação** antes de chamar a si mesma. Colocamos a chamada recursiva
**depois** do `prerequisito/2` de propósito: a formulação
`prerequisito_transitivo(D, I), prerequisito(I, A)` (recursão à esquerda)
entraria em recursão infinita antes de tocar qualquer fato.

**Por que a lista de visitados:** sem ela, a recursão só é bem fundada enquanto
a base for acíclica — exatamente a hipótese que não se pode assumir, já que o
próximo predicado existe justamente para detectar base cíclica. Com a lista, a
busca nunca reentra num nó do caminho corrente, o conjunto de disciplinas é
finito, e a terminação passa a ser garantida por construção, não por confiança
nos dados.

Nenhuma solução é perdida numa base acíclica: num DAG, um caminho nunca
reencontra um nó que já percorreu.

### 3.2 `existe_ciclo/1` por consulta reflexiva

```prolog
existe_ciclo(D) :- prerequisito_transitivo(D, D).
```

Uma disciplina que é seu próprio ancestral transitivo caracteriza ciclo na base
— dado malformado. A checagem é declarativa e reaproveita o fecho, sem código
novo.

A detecção funciona porque, em qualquer ciclo que contenha `D`, o nó
imediatamente anterior a `D` na cadeia satisfaz `prerequisito(Anterior, D)`
pelo caso base — e a lista de visitados garante que a busca chegue até esse nó
em vez de girar indefinidamente.

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

Nenhum predicado do projeto usa `assert/1` ou `retract/1`. Os dois pontos do
roteiro de testes que mexem na base — o `cursou/2` que torna a negação decisiva
e os `prerequisito/2` circulares — são fatos acrescentados à mão, fora de
qualquer busca, e não passam por `gerar_trilha/5`.

### 3.4 Limite de semestres simulados como rede de segurança

`gerar_trilha/5` carrega um contador `SemestresRestantes` que decresce a cada
semestre e exige `SemestresRestantes > 0`. O valor inicial vem do fato
`max_semestres(12).`, declarado no topo de `trilhas.pl`.

**Por quê:** mesmo com base acíclica e correta, o número de trilhas possíveis
cresce combinatoriamente (cada semestre é um subconjunto das disciplinas
liberadas que cabe no teto de créditos). O limite é uma garantia **estrutural**
de terminação, independente da qualidade dos dados: a busca para porque a
profundidade acabou, não porque os dados são bem-comportados.

O valor ficou num fato nomeado, e não literal no corpo da regra, para que a
rede de segurança seja visível e ajustável sem editar a lógica de busca.

### 3.5 Elegibilidade na trilha usa o fecho transitivo, não o pré-requisito direto

```prolog
elegivel_agora(Cursadas, Disciplina) :-
    forall(
        prerequisito_transitivo(Disciplina, Prerequisito),
        memberchk(Prerequisito, Cursadas)
    ).
```

O enunciado exige que, na trilha, toda disciplina apareça depois de seus
pré-requisitos **diretos e indiretos**. Checar só os diretos daria o mesmo
resultado enquanto o histórico de entrada fosse internamente consistente — mas
os históricos de teste não são (`julia` cursou `modelagem_de_fenomenos_fisicos`
sem ter cursado `resolucao_de_problemas_de_natureza_discreta`, que é
pré-requisito dela, o que é realista para quem tem DP e quebra a invariante).
Usar o fecho torna a checagem correta independentemente da consistência do
histórico.

### 3.6 Semestre gerado como subconjunto sob orçamento de créditos

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

### 4.1 `subconjunto_com_credito/3` não tem poda

`src/trilhas.pl` — a enumeração incluir/pular gera, no pior caso, `2^n`
subconjuntos para `n` disciplinas liberadas. Não há poda por créditos mínimos
nem preferência por semestres "cheios", e semestres vazios só são descartados
depois de gerados (`Semestre \= []` em `gerar_trilha/5`). Com 20 disciplinas e
o limite de `max_semestres(12)` isso é tolerável; com uma grade completa de 8
semestres e teto de créditos folgado, o custo de `findall/3` sobre
`trilha_valida/3` cresceria rápido.

### 4.2 Trilhas enumeradas incluem permutações equivalentes

`trilha_valida/3` trata a trilha como sequência **ordenada** de semestres, então
distribuir três disciplinas como `[[a],[b,c]]` e `[[b,c],[a]]` conta como duas
trilhas distintas — mesmo quando nenhuma restrição de pré-requisito distingue as
duas. Isso infla a contagem de `findall/3`. Não é incorreto (as duas sequências
são de fato válidas e distintas no tempo), mas o número total de trilhas é maior
do que a intuição de "formas realmente diferentes de se formar" sugere.

### 4.3 `aluno_existe/1` não distingue aluno novo de aluno inexistente

`src/elegibilidade.pl` — a guarda testa a presença de ao menos um fato
`cursou/2`. Um calouro real, matriculado e sem nenhuma disciplina cursada, é
indistinguível de um aluno que não existe: ambos fazem as consultas falharem.
Para o escopo deste trabalho é aceitável — os três alunos de teste têm
histórico — mas a modelagem correta exigiria um fato `aluno/1` explícito na
Camada 1.

### 4.4 Os testes são um roteiro manual, não uma bateria automatizada

`tests/consultas_teste.pl` documenta as consultas de cada camada e o resultado
esperado, mas as consultas são digitadas à mão no terminal: o arquivo não é
carregável com `consult/1`, porque em Prolog um termo no topo de um arquivo é
definição de cláusula e não pergunta. Rodá-lo tentaria acrescentar cláusulas a
`disciplinas_liberadas/2`, `cursou/2` e `prerequisito/2`, que já estão
definidos nas camadas.

Consequências: não há como rodar tudo de uma vez nem verificar automaticamente
que nada regrediu, e os dois blocos que alteram a base (o `cursou/2` da negação
decisiva e os `prerequisito/2` circulares) exigem reiniciar o interpretador
depois, já que nada os desfaz.

Uma versão executável exigiria envolver cada consulta num predicado que a
executa e compara com o esperado, declarar `cursou/2` e `prerequisito/2` como
dinâmicos, e desfazer com `retract/1` o que for inserido.

### 4.5 Só existe uma cadeia de pré-requisitos

A base tem 3 fatos `prerequisito/2`, todos na mesma cadeia linear:

```
grafos -> modelagem -> discreta -> logica_matematica
```

Nenhuma disciplina tem **múltiplos** pré-requisitos diretos, então o `forall/2`
de `prerequisitos_ok/2` nunca é exercitado com mais de um item, e o fecho
transitivo nunca precisa lidar com caminhos convergentes — que é o cenário em
que a deduplicação de `setof/3` faria diferença real sobre `findall/3`.

### 4.6 Históricos de teste não respeitam os próprios pré-requisitos

`julia` cursou `modelagem_de_fenomenos_fisicos` e
`resolucao_de_problemas_com_grafos` sem ter cursado
`resolucao_de_problemas_de_natureza_discreta`, que é pré-requisito transitivo
das duas. Isso é proposital para o perfil "com DP", e o sistema lida com a
inconsistência sem quebrar (ver Seção 3.5), mas significa que o histórico não é
uma base válida para inferir que os pré-requisitos foram respeitados no passado.
Não há predicado que valide a consistência de um `cursou/2` contra a grade.

### 4.7 Sem modelagem de equivalência entre currículos

O enunciado cita equivalência de disciplinas entre grades antiga e nova como
exemplo de decisão em aberto. Não modelamos isso: `cursou/2` é comparado por
identidade de átomo. Uma extensão natural seria um fato
`equivale(DisciplinaAntiga, DisciplinaNova)` e uma regra `cursou_equivalente/2`
que fecha por essa relação — deliberadamente fora do escopo desta entrega.

### 4.8 Sem nota, reprovação, co-requisito ou piso de créditos

O sistema conhece apenas "cursou" ou "não cursou". Não há nota, não há
reprovação (uma disciplina cursada é sempre aprovada), não há co-requisito
(disciplinas que devem ser feitas no mesmo semestre) nem piso de créditos por
semestre. `trilha_valida/3` também ignora o `SemestreSugerido` da grade — ele é
dado descritivo, não restrição.

### 4.9 Eletivas ficam fora da trilha

`trilha_valida/3` parte de `disciplinas_pendentes/2`, que só considera
obrigatórias. A trilha gerada é, portanto, o caminho mínimo até cumprir as
obrigatórias, não até a integralização real do curso (que normalmente exige um
número mínimo de créditos eletivos). Foi uma escolha consciente: o enunciado
define `disciplinas_pendentes/2` como "todas as obrigatórias ainda não
cursadas", e acoplar exigência de créditos eletivos exigiria um dado que a base
não tem.

---

## 5. Decisões em aberto

- **Fato `aluno/1` explícito na Camada 1.** Resolveria a limitação 4.3. Hoje a
  lista de alunos é derivada em `main.pl` por
  `setof(A, D^cursou(A, D), Alunos)`, o que evita dado redundante mas não
  representa aluno sem histórico. O custo do fato explícito é mantê-lo em
  sincronia com `cursou/2`.
- **Poda em `subconjunto_com_credito/3`.** Exigir que o semestre use pelo menos
  um piso de créditos cortaria a maior parte dos subconjuntos triviais
  (limitação 4.1) e reduziria a inflação de trilhas da limitação 4.2.
- **Trilha como conjunto de semestres, não sequência.** Normalizar a ordem dos
  semestres eliminaria as permutações equivalentes da limitação 4.2, ao custo de
  perder a noção de "qual semestre vem primeiro" quando ela de fato importa.
- **`trilha_valida/4` com o limite como argumento.** Hoje o limite vem sempre de
  `max_semestres/1`. Recebê-lo por argumento permitiria demonstrar, em teste,
  que a busca de fato para quando o limite se esgota.
