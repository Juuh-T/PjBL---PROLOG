% ============================================================
% PONTO DE ENTRADA
%
% Carrega as tres camadas na ordem (fatos -> regras -> trilhas)
% e define a demonstracao demo/0.
%
% Uso:  swipl src/main.pl
%       ?- demo.
% ============================================================

:- consult('trilhas.pl').


% alunos(-Alunos)
%
% A Camada 1 nao tem um fato aluno/1: a lista de alunos e derivada
% dos fatos cursou/2. Aqui setof/3 e a escolha certa (e nao
% findall/3) porque queremos o conjunto ordenado e sem repeticao.
% O "Disciplina^" marca Disciplina como existencial - sem isso,
% setof/3 agruparia um resultado por disciplina em vez de devolver
% um unico conjunto de alunos.
alunos(Alunos) :-
    setof(Aluno, Disciplina^cursou(Aluno, Disciplina), Alunos).


% demo/0
% Exercita, em sequencia, as tres camadas.
demo :-
    writeln('=== DEMONSTRACAO: CURRICULUM ADVISOR ==='),
    nl,
    demo_camada1,
    demo_camada2,
    demo_camada3.


% ------------------------------------------------------------
% Camada 1: base de fatos
% ------------------------------------------------------------
demo_camada1 :-
    writeln('--- CAMADA 1: BASE DE FATOS ---'),
    forall(
        between(1, 6, Semestre),
        (   findall(D, disciplina(D, _, _, Semestre), Disciplinas),
            format('Semestre ~w: ~w~n', [Semestre, Disciplinas])
        )
    ),
    findall(E, disciplina(E, eletiva, _, _), Eletivas),
    format('Eletivas: ~w~n', [Eletivas]),
    nl.


% ------------------------------------------------------------
% Camada 2: regras de elegibilidade
% ------------------------------------------------------------
demo_camada2 :-
    writeln('--- CAMADA 2: REGRAS DE ELEGIBILIDADE ---'),
    alunos(Alunos),
    forall(
        member(Aluno, Alunos),
        (   format('Aluno: ~w~n', [Aluno]),
            disciplinas_liberadas(Aluno, Liberadas),
            format('  Liberadas: ~w~n', [Liberadas]),
            disciplinas_pendentes(Aluno, Pendentes),
            format('  Pendentes: ~w~n', [Pendentes]),
            creditos_cursados(Aluno, Creditos),
            format('  Creditos cursados: ~w~n', [Creditos])
        )
    ),
    nl.


% ------------------------------------------------------------
% Camada 3: fecho transitivo e trilhas
% ------------------------------------------------------------
demo_camada3 :-
    writeln('--- CAMADA 3: FECHO TRANSITIVO E TRILHAS ---'),
    Alvo = resolucao_de_problemas_com_grafos,
    setof(A, prerequisito_transitivo(Alvo, A), Ancestrais),
    format('Pre-requisitos diretos e indiretos de ~w:~n  ~w~n', [Alvo, Ancestrais]),
    (   existe_ciclo(Alvo)
    ->  format('ATENCAO: ciclo detectado em ~w.~n', [Alvo])
    ;   format('Nenhum ciclo em ~w.~n', [Alvo])
    ),
    nl,
    demo_trilha(julia, 20),
    demo_trilha(eduardo, 20).


% demo_trilha(+Aluno, +MaxCreditos)
%
% Mostra a primeira trilha valida e quantas existem no total, dentro
% do limite de max_semestres/1.
demo_trilha(Aluno, MaxCreditos) :-
    format('Trilha para ~w (teto de ~w creditos por semestre):~n', [Aluno, MaxCreditos]),
    (   trilha_valida(Aluno, MaxCreditos, Trilha)
    ->  imprimir_semestres(Trilha, 1)
    ;   writeln('  nenhuma trilha valida encontrada')
    ),
    findall(T, trilha_valida(Aluno, MaxCreditos, T), Trilhas),
    length(Trilhas, Total),
    format('  Total de trilhas validas: ~w~n', [Total]),
    nl.


imprimir_semestres([], _).
imprimir_semestres([Semestre|Resto], N) :-
    format('  Semestre ~w: ~w~n', [N, Semestre]),
    Proximo is N + 1,
    imprimir_semestres(Resto, Proximo).
