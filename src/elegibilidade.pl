% ============================================================
% CAMADA 2 - REGRAS DE ELEGIBILIDADE
%
% Deriva, a partir dos fatos da Camada 1, o que cada aluno pode
% fazer AGORA. Nao olha para o futuro (isso e a Camada 3).
% ============================================================


% aluno_existe(+Aluno)
%
% Guarda de robustez: verdadeiro se o aluno tem ao menos um fato
% cursou/2 na base. Consulta com aluno inexistente falha limpo
% (false), sem lancar excecao.
% O corte impede que a guarda produza uma solucao por disciplina
% cursada, o que duplicaria as respostas de quem a chama.
aluno_existe(Aluno) :-
    cursou(Aluno, _),
    !.


% prerequisitos_ok(+Aluno, ?Disciplina)
%
% Verdadeiro se TODOS os pre-requisitos diretos de Disciplina ja
% foram cursados por Aluno.
% forall/2 aqui verifica uma propriedade sobre todos os
% pre-requisitos; nao coleta nada (para coletar existe findall/3).
% Disciplina sem nenhum pre-requisito passa vacuamente, que e o
% comportamento desejado para as disciplinas de 1o semestre.
prerequisitos_ok(Aluno, Disciplina) :-
    aluno_existe(Aluno),
    disciplina(Disciplina, _, _, _),
    forall(
        prerequisito(Disciplina, Prerequisito),
        cursou(Aluno, Prerequisito)
    ).


% pode_cursar(+Aluno, ?Disciplina)
%
% Elegivel agora e ainda nao cursada.
% disciplina/4 vem ANTES da negacao de proposito: \+ e negacao por
% falha, nao negacao logica. Com Disciplina ainda livre,
% "\+ cursou(Aluno, Disciplina)" perguntaria "o aluno nao cursou
% NADA", que e outra pergunta e falha para qualquer aluno com
% historico. Gerando a disciplina primeiro, a negacao opera sobre
% um termo fechado.
pode_cursar(Aluno, Disciplina) :-
    aluno_existe(Aluno),
    disciplina(Disciplina, _, _, _),
    prerequisitos_ok(Aluno, Disciplina),
    \+ cursou(Aluno, Disciplina).


% disciplinas_liberadas(+Aluno, -Lista)
%
% Todas as disciplinas que o aluno pode cursar agora.
% findall/3 e nao setof/3: para um aluno adiantado o resultado
% correto e [], e setof/3 falharia em vez de devolver lista vazia.
% Nao ha duplicatas a remover, ja que disciplina/4 tem um fato por
% disciplina.
disciplinas_liberadas(Aluno, Lista) :-
    aluno_existe(Aluno),
    findall(
        Disciplina,
        pode_cursar(Aluno, Disciplina),
        Lista
    ).


% disciplinas_pendentes(+Aluno, -Lista)
%
% Todas as obrigatorias ainda nao cursadas, independentemente de
% elegibilidade (uma pendencia continua pendente mesmo que o aluno
% ainda nao possa cursa-la).
disciplinas_pendentes(Aluno, Lista) :-
    aluno_existe(Aluno),
    findall(
        Disciplina,
        (   disciplina(Disciplina, obrigatoria, _, _),
            \+ cursou(Aluno, Disciplina)
        ),
        Lista
    ).


% creditos_cursados(+Aluno, -Total)
%
% Soma dos creditos de tudo que o aluno ja cursou, obrigatorias e
% eletivas. Os creditos vem do 3o argumento de disciplina/4.
creditos_cursados(Aluno, Total) :-
    aluno_existe(Aluno),
    findall(
        Creditos,
        (   cursou(Aluno, Disciplina),
            disciplina(Disciplina, _, Creditos, _)
        ),
        ListaCreditos
    ),
    sum_list(ListaCreditos, Total).
