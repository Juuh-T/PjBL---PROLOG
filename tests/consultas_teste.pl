:- dynamic cursou/2.
:- dynamic prerequisito/2.

:- consult('../src/main.pl').

:- dynamic falhas/1.

falhas(0).

registrar_falha :-
    retract(falhas(N)),
    N1 is N + 1,
    assertz(falhas(N1)).

mesmo_resultado(Obtido, Esperado) :-
    (   lista_plana(Obtido),
        lista_plana(Esperado)
    ->  msort(Obtido, O),
        msort(Esperado, X),
        O == X
    ;   Obtido == Esperado
    ).

lista_plana(L) :-
    is_list(L),
    forall(member(X, L), \+ is_list(X)).

consulta(Texto, Objetivo, Obtido, Esperado) :-
    format('~w~n', [Texto]),
    (   catch(Objetivo, E,
              ( format('  ERRO: excecao ~w~n~n', [E]), registrar_falha, fail ))
    ->  format('  = ~w~n', [Obtido]),
        (   mesmo_resultado(Obtido, Esperado)
        ->  writeln('  ok')
        ;   writeln('  FALHA'),
            format('  esperado: ~w~n', [Esperado]),
            registrar_falha
        ),
        nl
    ;   writeln('  FALHA: a consulta falhou'),
        format('  esperado: ~w~n~n', [Esperado]),
        registrar_falha
    ).

consulta_bool(Texto, Objetivo, Esperado) :-
    format('~w~n', [Texto]),
    (   catch(Objetivo, E,
              ( format('  ERRO: excecao ~w em vez de ~w~n~n', [E, Esperado]),
                registrar_falha, fail ))
    ->  Obtido = true
    ;   Obtido = false
    ),
    (   Obtido == Esperado
    ->  format('  = ~w~n  ok~n~n', [Obtido])
    ;   format('  = ~w~n  FALHA: esperado ~w~n~n', [Obtido, Esperado]),
        registrar_falha
    ).

teste_camada1 :-
    writeln('========== CAMADA 1 =========='),
    nl,

    consulta('?- disciplinas_por_semestre(1, Lista).',
        disciplinas_por_semestre(1, L1), L1,
        [ fundamentos_de_sistemas_ciberfisicos,
          resolucao_de_problemas_com_logica_matematica,
          filosofia,
          experiencia_criativa,
          raciocinio_algoritmo ]),

    consulta('?- disciplinas_por_semestre(4, Lista).',
        disciplinas_por_semestre(4, L4), L4,
        [ resolucao_de_problemas_com_grafos,
          game_design ]),

    consulta('?- disciplinas_por_semestre(99, Lista).',
        disciplinas_por_semestre(99, L99), L99, []).

teste_camada2 :-
    writeln('========== CAMADA 2 =========='),
    nl,

    consulta('?- disciplinas_liberadas(eduardo, Liberadas).',
        disciplinas_liberadas(eduardo, LE), LE,
        [ seguranca_da_informacao,
          resolucao_de_problemas_com_grafos,
          game_design,
          introducao_a_criptografia,
          ciencias_forenses,
          criacao_de_trilhas_sonoras_para_jogos,
          astrologia_para_todos ]),

    consulta('?- disciplinas_pendentes(eduardo, Pendentes).',
        disciplinas_pendentes(eduardo, PE), PE,
        [ seguranca_da_informacao,
          resolucao_de_problemas_com_grafos ]),

    consulta('?- disciplinas_liberadas(caio, Liberadas).',
        disciplinas_liberadas(caio, LC), LC, []),

    consulta('?- disciplinas_pendentes(caio, Pendentes).',
        disciplinas_pendentes(caio, PC), PC, []),

    consulta('?- creditos_cursados(eduardo, Total).',
        creditos_cursados(eduardo, CE), CE, 54),

    teste_negacao_por_falha.

teste_negacao_por_falha :-
    writeln('---------- \\+ cursou/2 e decisivo ----------'),
    nl,

    consulta_bool('?- pode_cursar(eduardo, resolucao_de_problemas_com_grafos).',
        pode_cursar(eduardo, resolucao_de_problemas_com_grafos), true),

    writeln('% acrescentando cursou(eduardo, resolucao_de_problemas_com_grafos)'),
    nl,
    assertz(cursou(eduardo, resolucao_de_problemas_com_grafos)),

    consulta_bool('?- pode_cursar(eduardo, resolucao_de_problemas_com_grafos).',
        pode_cursar(eduardo, resolucao_de_problemas_com_grafos), false),

    writeln('% removendo o fato para restaurar a base'),
    nl,
    retract(cursou(eduardo, resolucao_de_problemas_com_grafos)),

    consulta_bool('?- pode_cursar(eduardo, resolucao_de_problemas_com_grafos).',
        pode_cursar(eduardo, resolucao_de_problemas_com_grafos), true).

teste_camada3 :-
    writeln('========== CAMADA 3 =========='),
    nl,

    consulta('?- setof(A, prerequisito_transitivo(resolucao_de_problemas_com_grafos, A), Ancestrais).',
        setof(A, prerequisito_transitivo(resolucao_de_problemas_com_grafos, A), As),
        As,
        [ modelagem_de_fenomenos_fisicos,
          resolucao_de_problemas_de_natureza_discreta,
          resolucao_de_problemas_com_logica_matematica ]),

    consulta_bool('?- prerequisito_transitivo(resolucao_de_problemas_com_grafos, resolucao_de_problemas_com_logica_matematica).',
        prerequisito_transitivo(resolucao_de_problemas_com_grafos,
                                resolucao_de_problemas_com_logica_matematica), true),

    consulta('?- trilha_valida(eduardo, 20, Trilha).',
        trilha_valida(eduardo, 20, TE), TE,
        [[ seguranca_da_informacao, resolucao_de_problemas_com_grafos ]]),

    consulta('?- trilha_valida(julia, 20, Trilha).',
        trilha_valida(julia, 20, TJ), TJ,
        [[ raciocinio_algoritmo,
           resolucao_de_problemas_de_natureza_discreta,
           arquitetura_de_banco_de_dados ]]),

    consulta('?- findall(T, trilha_valida(julia, 20, T), Trilhas), length(Trilhas, N).',
        ( findall(T, trilha_valida(julia, 20, T), Ts), length(Ts, N) ), N, 13),

    teste_trilha_completa.

teste_trilha_completa :-
    writeln('---------- trilha completa, teto de 6 creditos ----------'),
    nl,

    consulta('?- trilha_valida(julia, 6, Trilha).',
        trilha_valida(julia, 6, T), T,
        [ [raciocinio_algoritmo],
          [resolucao_de_problemas_de_natureza_discreta],
          [arquitetura_de_banco_de_dados] ]),

    consulta_bool('% nenhum semestre estoura o teto de 6 creditos',
        ( trilha_valida(julia, 6, T1),
          forall( member(S, T1),
                  ( creditos_do_semestre(S, C), C =< 6 ) ) ), true),

    consulta_bool('% toda disciplina vem depois de seus pre-requisitos transitivos',
        ( trilha_valida(julia, 6, T2),
          findall(D, cursou(julia, D), Iniciais),
          ordem_valida(T2, Iniciais) ), true),

    consulta_bool('% a trilha cobre exatamente as pendencias, sem sobra nem repeticao',
        ( trilha_valida(julia, 6, T3),
          append(T3, Todas), msort(Todas, TodasOrd),
          disciplinas_pendentes(julia, Pend), msort(Pend, PendOrd),
          TodasOrd == PendOrd ), true),

    consulta_bool('?- trilha_valida(caio, 20, []).   % aluno sem pendencias',
        trilha_valida(caio, 20, []), true).

teste_ciclo :-
    writeln('========== DETECCAO DE CICLO =========='),
    nl,
    writeln('% inserindo um ciclo de proposito:'),
    writeln('%   prerequisito(teste_a, teste_b).'),
    writeln('%   prerequisito(teste_b, teste_c).'),
    writeln('%   prerequisito(teste_c, teste_a).'),
    writeln('%   prerequisito(teste_d, teste_d).   % ciclo de comprimento 1'),
    writeln('%   prerequisito(teste_e, teste_a).   % entra no ciclo, mas nao pertence a ele'),
    nl,
    assertz(prerequisito(teste_a, teste_b)),
    assertz(prerequisito(teste_b, teste_c)),
    assertz(prerequisito(teste_c, teste_a)),
    assertz(prerequisito(teste_d, teste_d)),
    assertz(prerequisito(teste_e, teste_a)),

    consulta_bool('?- existe_ciclo(teste_a).',
        existe_ciclo(teste_a), true),
    consulta_bool('?- existe_ciclo(teste_d).   % ciclo de comprimento 1',
        existe_ciclo(teste_d), true),
    consulta_bool('?- existe_ciclo(teste_e).   % depende do ciclo, mas esta fora dele',
        existe_ciclo(teste_e), false),
    consulta_bool('?- existe_ciclo(resolucao_de_problemas_com_grafos).   % grade real intacta',
        existe_ciclo(resolucao_de_problemas_com_grafos), false),

    consulta('?- setof(A, prerequisito_transitivo(teste_a, A), Ancestrais).',
        setof(A, prerequisito_transitivo(teste_a, A), As), As,
        [teste_a, teste_b, teste_c]),

    writeln('% removendo os fatos circulares e restaurando a base'),
    nl,
    retract(prerequisito(teste_a, teste_b)),
    retract(prerequisito(teste_b, teste_c)),
    retract(prerequisito(teste_c, teste_a)),
    retract(prerequisito(teste_d, teste_d)),
    retract(prerequisito(teste_e, teste_a)),

    consulta_bool('?- existe_ciclo(teste_a).   % base restaurada',
        existe_ciclo(teste_a), false).

teste_casos_de_borda :-
    writeln('========== CASOS DE BORDA =========='),
    nl,
    consulta_bool('?- disciplinas_liberadas(fulano, L).   % aluno inexistente',
        disciplinas_liberadas(fulano, _), false),
    consulta_bool('?- creditos_cursados(fulano, T).   % aluno inexistente',
        creditos_cursados(fulano, _), false),
    consulta_bool('?- pode_cursar(julia, disciplina_que_nao_existe).',
        pode_cursar(julia, disciplina_que_nao_existe), false),
    consulta_bool('?- trilha_valida(fulano, 20, T).   % aluno inexistente',
        trilha_valida(fulano, 20, _), false),

    consulta_bool('?- trilha_valida(julia, 2, T).   % teto impossivel',
        trilha_valida(julia, 2, _), false).

creditos_do_semestre(Semestre, Total) :-
    findall(C, ( member(D, Semestre), disciplina(D, _, C, _) ), Cs),
    sum_list(Cs, Total).

ordem_valida([], _).
ordem_valida([Semestre|Resto], Acumulado) :-
    forall(
        ( member(D, Semestre), prerequisito_transitivo(D, P) ),
        memberchk(P, Acumulado)
    ),
    append(Acumulado, Semestre, Novo),
    ordem_valida(Resto, Novo).

testes :-
    retractall(falhas(_)),
    assertz(falhas(0)),
    writeln('=== CONSULTAS DE TESTE ==='),
    nl,
    teste_camada1,
    teste_camada2,
    teste_camada3,
    teste_ciclo,
    teste_casos_de_borda,
    falhas(N),
    (   N =:= 0
    ->  writeln('=== TODAS AS CONSULTAS DERAM O RESULTADO ESPERADO ===')
    ;   format('=== ~w CONSULTA(S) FORA DO ESPERADO ===~n', [N])
    ).
