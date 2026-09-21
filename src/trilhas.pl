% ============================================================
% CAMADA 3 - FECHO TRANSITIVO E GERACAO DE TRILHAS
%
% Olha para o historico completo de pre-requisitos (nao so os
% diretos) e para o futuro (o caminho ate a formatura),
% respeitando pre-requisitos e teto de creditos por semestre.
% ============================================================


% max_semestres(-N)
%
% Rede de seguranca contra explosao combinatoria: numero maximo de
% semestres simulados por trilha_valida/3. A busca termina porque a
% profundidade acabou, nao porque os dados sao bem-comportados.
max_semestres(12).


% ------------------------------------------------------------
% Fecho transitivo
% ------------------------------------------------------------

% prerequisito_transitivo(?Disciplina, ?Ancestral)
%
% Todo pre-requisito direto ou indireto de Disciplina.
% Delega para o auxiliar de aridade 3, que carrega a lista de nos
% ja visitados no caminho atual. Sem essa lista, uma base com ciclo
% faria a recursao nao terminar - e e justamente numa base com
% ciclo que existe_ciclo/1 precisa conseguir responder.
prerequisito_transitivo(Disciplina, Ancestral) :-
    prerequisito_transitivo(Disciplina, Ancestral, [Disciplina]).

% Caso base: pre-requisito direto.
prerequisito_transitivo(Disciplina, Ancestral, _) :-
    prerequisito(Disciplina, Ancestral).

% Passo recursivo: desce um nivel pela relacao ANTES de chamar a si
% mesmo. A formulacao inversa (recursao primeiro) seria recursao a
% esquerda e entraria em loop antes de tocar qualquer fato.
% So avanca para nos ainda nao visitados neste caminho.
prerequisito_transitivo(Disciplina, Ancestral, Visitados) :-
    prerequisito(Disciplina, Intermediaria),
    \+ memberchk(Intermediaria, Visitados),
    prerequisito_transitivo(Intermediaria, Ancestral, [Intermediaria|Visitados]).


% existe_ciclo(+Disciplina)
%
% Verdadeiro se Disciplina e seu proprio ancestral transitivo, ou
% seja, se a base de pre-requisitos esta malformada. Termina sempre,
% inclusive sobre uma base ciclica.
existe_ciclo(Disciplina) :-
    prerequisito_transitivo(Disciplina, Disciplina).


% ------------------------------------------------------------
% Geracao de trilhas
% ------------------------------------------------------------

% trilha_valida(+Aluno, +MaxCreditosPorSemestre, -Trilha)
%
% Gera, por backtracking, uma sequencia de semestres (cada um uma
% lista de disciplinas) em que toda disciplina so aparece depois de
% seus pre-requisitos diretos e indiretos, e a soma de creditos de
% cada semestre nao ultrapassa MaxCreditosPorSemestre.
% Falha limpo para aluno inexistente, via disciplinas_pendentes/2.
trilha_valida(Aluno, MaxCreditosPorSemestre, Trilha) :-
    findall(D, cursou(Aluno, D), Cursadas),
    disciplinas_pendentes(Aluno, Pendentes),
    max_semestres(MaxSemestres),
    gerar_trilha(Pendentes, Cursadas, MaxCreditosPorSemestre, MaxSemestres, Trilha).


% gerar_trilha(+Pendentes, +Cursadas, +MaxCreditos, +SemestresRestantes, -Trilha)
%
% O estado da simulacao (Cursadas e Pendentes) viaja por PARAMETRO,
% nunca por assert/retract: o backtracking desfaz unificacao de
% variaveis automaticamente, mas NAO desfaz alteracao na base de
% fatos. Com assert/retract, ao retroceder para tentar outra
% composicao de semestre os fatos assertados continuariam la e a
% trilha seguinte sairia errada.

% Caso base: nao ha mais pendencias, a trilha esta fechada.
gerar_trilha([], _, _, _, []).

gerar_trilha(Pendentes, Cursadas, MaxCreditos, SemestresRestantes, [Semestre|Resto]) :-
    SemestresRestantes > 0,
    include(elegivel_agora(Cursadas), Pendentes, Liberadas),
    Liberadas \= [],
    subconjunto_com_credito(Liberadas, MaxCreditos, Semestre),
    Semestre \= [],
    subtract(Pendentes, Semestre, NovoPendentes),
    append(Cursadas, Semestre, NovasCursadas),
    Restantes is SemestresRestantes - 1,
    gerar_trilha(NovoPendentes, NovasCursadas, MaxCreditos, Restantes, Resto).


% elegivel_agora(+Cursadas, +Disciplina)
%
% Usa o fecho transitivo, nao prerequisito/2 direto: o enunciado
% exige que uma disciplina so apareca depois de seus pre-requisitos
% diretos E indiretos.
elegivel_agora(Cursadas, Disciplina) :-
    forall(
        prerequisito_transitivo(Disciplina, Prerequisito),
        memberchk(Prerequisito, Cursadas)
    ).


% subconjunto_com_credito(+Liberadas, +CreditosDisponiveis, -Semestre)
%
% Para cada disciplina liberada, duas alternativas por backtracking:
% incluir (descontando os creditos do orcamento restante) ou pular.
% O teto e imposto DURANTE a construcao, entao todo semestre gerado
% ja nasce valido - nao e gerar-e-testar.
% E daqui que sai a enumeracao de multiplas trilhas: cada composicao
% diferente de semestre e um ponto de escolha.
subconjunto_com_credito([], _, []).

subconjunto_com_credito([D|Ds], Disponivel, [D|Resto]) :-
    disciplina(D, _, Creditos, _),
    Creditos =< Disponivel,
    Restante is Disponivel - Creditos,
    subconjunto_com_credito(Ds, Restante, Resto).

subconjunto_com_credito([_|Ds], Disponivel, Resto) :-
    subconjunto_com_credito(Ds, Disponivel, Resto).
