% ============================================================
% BATERIA DE CONSULTAS DE TESTE
%
% Cobre os casos obrigatorios da Secao 8 do enunciado nas tres
% camadas. Cada teste declara o resultado esperado e o compara com
% o obtido.
%
% O teste de ciclo fica em tests/ciclo_teste.pl, arquivo separado,
% porque ele suja a base de pre-requisitos de proposito.
%
% Uso:  swipl tests/consultas_teste.pl
%       ?- testes.
% ============================================================

% cursou/2 precisa ser dinamico ANTES do consult: um dos testes da
% Camada 2 insere e remove um fato do historico para mostrar que
% \+ cursou/2 e decisivo. O retract devolve a base ao estado
% original - diferente do que fariamos dentro de uma busca, onde
% assert/retract quebraria o backtracking (ver docs/decisoes.md 3.3).
:- dynamic cursou/2.

:- consult('../src/main.pl').


% ------------------------------------------------------------
% Infraestrutura de teste
% ------------------------------------------------------------

:- dynamic falhas/1.

falhas(0).

ok(Descricao) :-
    format('  ok    ~w~n', [Descricao]).

falhou(Descricao) :-
    format('  FALHA ~w~n', [Descricao]),
    retract(falhas(N)),
    N1 is N + 1,
    assertz(falhas(N1)).


% verifica(+Descricao, :Objetivo)
% Passa se Objetivo tem sucesso.
verifica(Descricao, Objetivo) :-
    (   catch(Objetivo, E,
              ( format('  ERRO  ~w (excecao: ~w)~n', [Descricao, E]), fail ))
    ->  ok(Descricao)
    ;   falhou(Descricao)
    ).


% verifica_falha(+Descricao, :Objetivo)
% Passa se Objetivo falha LIMPO, sem lancar excecao.
verifica_falha(Descricao, Objetivo) :-
    (   catch(Objetivo, E,
              ( format('  ERRO  ~w (excecao em vez de false: ~w)~n', [Descricao, E]),
                fail ))
    ->  falhou(Descricao)
    ;   ok(Descricao)
    ).


% verifica_igual(+Descricao, :Objetivo, ?Obtido, +Esperado)
% Obtido e a variavel que Objetivo instancia.
verifica_igual(Descricao, Objetivo, Obtido, Esperado) :-
    (   catch(Objetivo, E,
              ( format('  ERRO  ~w (excecao: ~w)~n', [Descricao, E]), fail ))
    ->  (   Obtido == Esperado
        ->  ok(Descricao)
        ;   falhou(Descricao),
            format('        esperado: ~w~n', [Esperado]),
            format('        obtido:   ~w~n', [Obtido])
        )
    ;   falhou(Descricao),
        writeln('        o objetivo falhou')
    ).


% verifica_conjunto(+Descricao, :Objetivo, ?Obtida, +Esperada)
% Como verifica_igual/4, mas compara listas como conjuntos: a ordem
% das solucoes de findall/3 depende da ordem dos fatos, e o que
% importa nestes testes e o conteudo.
verifica_conjunto(Descricao, Objetivo, Obtida, Esperada) :-
    (   catch(Objetivo, E,
              ( format('  ERRO  ~w (excecao: ~w)~n', [Descricao, E]), fail ))
    ->  msort(Obtida, O),
        msort(Esperada, X),
        (   O == X
        ->  ok(Descricao)
        ;   falhou(Descricao),
            format('        esperado: ~w~n', [X]),
            format('        obtido:   ~w~n', [O])
        )
    ;   falhou(Descricao),
        writeln('        o objetivo falhou')
    ).


% ------------------------------------------------------------
% CAMADA 1 - Base de fatos
% ------------------------------------------------------------
teste_camada1 :-
    writeln('--- CAMADA 1: BASE DE FATOS ---'),

    % Consulta: disciplinas_por_semestre(1, Lista).
    verifica_conjunto('disciplinas do semestre 1',
        disciplinas_por_semestre(1, L1), L1,
        [ fundamentos_de_sistemas_ciberfisicos,
          resolucao_de_problemas_com_logica_matematica,
          filosofia,
          experiencia_criativa,
          raciocinio_algoritmo ]),

    % Consulta: disciplinas_por_semestre(6, Lista).
    verifica_conjunto('disciplinas do semestre 6',
        disciplinas_por_semestre(6, L6), L6,
        [ criacao_de_trilhas_sonoras_para_jogos,
          astrologia_para_todos ]),

    % Semestre sem disciplina devolve [], nao falha.
    verifica_igual('semestre inexistente devolve lista vazia',
        disciplinas_por_semestre(99, L99), L99, []),

    % Minimos exigidos pelo enunciado.
    verifica_igual('a base tem 20 disciplinas',
        ( findall(D, disciplina(D, _, _, _), Ds), length(Ds, N) ), N, 20),

    verifica_igual('a base cobre 6 semestres sugeridos',
        ( setof(S, D2^T2^C2^disciplina(D2, T2, C2, S), Ss), length(Ss, NS) ),
        NS, 6),

    verifica_conjunto('a base tem 5 eletivas',
        findall(E, disciplina(E, eletiva, _, _), Es), Es,
        [ game_design,
          introducao_a_criptografia,
          ciencias_forenses,
          criacao_de_trilhas_sonoras_para_jogos,
          astrologia_para_todos ]),

    verifica_igual('todo tipo esta no dominio {obrigatoria, eletiva}',
        ( findall(T, ( disciplina(_, T, _, _),
                       T \== obrigatoria,
                       T \== eletiva ), Fora ),
          length(Fora, NF) ),
        NF, 0),

    verifica_igual('ha 3 alunos de teste',
        ( alunos(As), length(As, NA) ), NA, 3),
    nl.


% ------------------------------------------------------------
% CAMADA 2 - Regras de elegibilidade
% ------------------------------------------------------------
teste_camada2 :-
    writeln('--- CAMADA 2: REGRAS DE ELEGIBILIDADE ---'),

    % Consulta: disciplinas_liberadas(eduardo, Liberadas).
    verifica_conjunto('liberadas de eduardo',
        disciplinas_liberadas(eduardo, LE), LE,
        [ seguranca_da_informacao,
          resolucao_de_problemas_com_grafos,
          game_design,
          introducao_a_criptografia,
          ciencias_forenses,
          criacao_de_trilhas_sonoras_para_jogos,
          astrologia_para_todos ]),

    % Consulta: disciplinas_pendentes(eduardo, Pendentes).
    verifica_conjunto('pendentes de eduardo',
        disciplinas_pendentes(eduardo, PE), PE,
        [ seguranca_da_informacao,
          resolucao_de_problemas_com_grafos ]),

    % Consulta: disciplinas_liberadas(caio, Liberadas).
    % caio esta adiantado: cursou tudo, entao as duas listas sao
    % vazias. E por isso que usamos findall/3 e nao setof/3, que
    % falharia em vez de devolver [].
    verifica_igual('liberadas de caio (adiantado) sao vazias',
        disciplinas_liberadas(caio, LC), LC, []),

    % Consulta: disciplinas_pendentes(caio, Pendentes).
    verifica_igual('pendentes de caio (adiantado) sao vazias',
        disciplinas_pendentes(caio, PC), PC, []),

    % Terceiro perfil: julia, atrasada.
    verifica_conjunto('pendentes de julia (atrasada)',
        disciplinas_pendentes(julia, PJ), PJ,
        [ raciocinio_algoritmo,
          resolucao_de_problemas_de_natureza_discreta,
          arquitetura_de_banco_de_dados ]),

    % Os tres alunos dao resultados diferentes entre si.
    verifica('os 3 alunos tem pendencias diferentes entre si',
        ( disciplinas_pendentes(eduardo, A), disciplinas_pendentes(caio, B),
          disciplinas_pendentes(julia, C),
          A \== B, B \== C, A \== C )),

    % Creditos cursados.
    verifica_igual('creditos de caio', creditos_cursados(caio, CC), CC, 73),
    verifica_igual('creditos de eduardo', creditos_cursados(eduardo, CE), CE, 54),
    verifica_igual('creditos de julia', creditos_cursados(julia, CJ), CJ, 46),

    % prerequisitos_ok/2 com pre-requisito satisfeito e insatisfeito.
    verifica('prerequisitos_ok: eduardo cursou modelagem, entao grafos libera',
        prerequisitos_ok(eduardo, resolucao_de_problemas_com_grafos)),
    verifica('prerequisitos_ok: disciplina sem pre-requisito passa vacuamente',
        prerequisitos_ok(julia, arquitetura_de_banco_de_dados)),

    teste_negacao_decisiva,
    teste_robustez_camada2,
    nl.


% O caso em que \+ cursou/2 e decisivo: mudar o historico do aluno
% muda o resultado de pode_cursar/2.
teste_negacao_decisiva :-
    verifica('antes: eduardo pode cursar grafos',
        pode_cursar(eduardo, resolucao_de_problemas_com_grafos)),

    assertz(cursou(eduardo, resolucao_de_problemas_com_grafos)),

    verifica_falha('depois de cursar: grafos deixa de estar liberada',
        pode_cursar(eduardo, resolucao_de_problemas_com_grafos)),
    verifica_falha('e sai de disciplinas_pendentes/2',
        ( disciplinas_pendentes(eduardo, P),
          memberchk(resolucao_de_problemas_com_grafos, P) )),

    retract(cursou(eduardo, resolucao_de_problemas_com_grafos)),

    verifica('base restaurada: grafos volta a estar liberada',
        pode_cursar(eduardo, resolucao_de_problemas_com_grafos)).


% Consultas mal formadas devem falhar limpo, nunca lancar excecao.
teste_robustez_camada2 :-
    verifica_falha('aluno inexistente: disciplinas_liberadas/2 falha limpo',
        disciplinas_liberadas(fulano, _)),
    verifica_falha('aluno inexistente: disciplinas_pendentes/2 falha limpo',
        disciplinas_pendentes(fulano, _)),
    verifica_falha('aluno inexistente: creditos_cursados/2 falha limpo',
        creditos_cursados(fulano, _)),
    verifica_falha('disciplina inexistente: pode_cursar/2 falha limpo',
        pode_cursar(julia, disciplina_que_nao_existe)).


% ------------------------------------------------------------
% CAMADA 3 - Fecho transitivo e trilhas
% ------------------------------------------------------------
teste_camada3 :-
    writeln('--- CAMADA 3: FECHO TRANSITIVO E TRILHAS ---'),

    % Consulta: prerequisito_transitivo(resolucao_de_problemas_com_grafos, A).
    % A cadeia de profundidade 3 da base:
    %   grafos -> modelagem -> discreta -> logica_matematica
    verifica_conjunto('ancestrais transitivos de grafos',
        setof(A, prerequisito_transitivo(resolucao_de_problemas_com_grafos, A), As),
        As,
        [ modelagem_de_fenomenos_fisicos,
          resolucao_de_problemas_de_natureza_discreta,
          resolucao_de_problemas_com_logica_matematica ]),

    verifica('pre-requisito direto (profundidade 1)',
        prerequisito_transitivo(resolucao_de_problemas_com_grafos,
                                modelagem_de_fenomenos_fisicos)),
    verifica('pre-requisito indireto (profundidade 3)',
        prerequisito_transitivo(resolucao_de_problemas_com_grafos,
                                resolucao_de_problemas_com_logica_matematica)),
    verifica_falha('disciplina sem pre-requisito nao tem ancestral',
        prerequisito_transitivo(filosofia, _)),

    % Base limpa: nenhum ciclo.
    verifica_falha('base sem ciclo: existe_ciclo/1 responde false',
        existe_ciclo(resolucao_de_problemas_com_grafos)),

    % Consulta: trilha_valida(eduardo, 20, Trilha).
    verifica_igual('trilha de eduardo com teto 20 cabe em 1 semestre',
        trilha_valida(eduardo, 20, TE), TE,
        [[ seguranca_da_informacao, resolucao_de_problemas_com_grafos ]]),

    % Consulta: trilha_valida(julia, 20, Trilha).
    verifica_igual('trilha de julia com teto 20 cabe em 1 semestre',
        trilha_valida(julia, 20, TJ), TJ,
        [[ raciocinio_algoritmo,
           resolucao_de_problemas_de_natureza_discreta,
           arquitetura_de_banco_de_dados ]]),

    % Multiplas trilhas para o mesmo aluno, via findall/3.
    verifica_igual('eduardo tem 3 trilhas validas',
        ( findall(T1, trilha_valida(eduardo, 20, T1), Ts1), length(Ts1, N1) ),
        N1, 3),
    verifica_igual('julia tem 13 trilhas validas',
        ( findall(T2, trilha_valida(julia, 20, T2), Ts2), length(Ts2, N2) ),
        N2, 13),

    teste_trilha_completa,
    teste_robustez_camada3,
    nl.


% Trilha completa ate a formatura, com teto apertado para forcar
% varios semestres, validando as tres restricoes ao mesmo tempo.
teste_trilha_completa :-
    verifica_igual('com teto 6, a trilha de julia usa 3 semestres',
        ( trilha_valida(julia, 6, T), length(T, N) ), N, 3),

    verifica('nenhum semestre da trilha estoura o teto de creditos',
        ( trilha_valida(julia, 6, T1),
          forall( member(S, T1),
                  ( creditos_do_semestre(S, C), C =< 6 ) ) )),

    verifica('toda disciplina vem depois de seus pre-requisitos transitivos',
        ( trilha_valida(julia, 6, T2),
          findall(D, cursou(julia, D), Iniciais),
          ordem_valida(T2, Iniciais) )),

    verifica('a trilha cobre exatamente as pendencias, sem sobra nem repeticao',
        ( trilha_valida(julia, 6, T3),
          append(T3, Todas),
          msort(Todas, TodasOrd),
          disciplinas_pendentes(julia, Pend),
          msort(Pend, PendOrd),
          TodasOrd == PendOrd )),

    verifica('aluno sem pendencias produz trilha vazia',
        trilha_valida(caio, 20, [])).


teste_robustez_camada3 :-
    verifica_falha('aluno inexistente: trilha_valida/3 falha limpo',
        trilha_valida(fulano, 20, _)),

    % Rede de seguranca: com teto de 2 creditos nenhuma pendencia de
    % julia cabe num semestre, entao a busca falha em vez de travar.
    verifica_falha('teto de creditos impossivel falha sem travar',
        trilha_valida(julia, 2, _)),

    verifica('o limite de semestres esta declarado',
        max_semestres(_)).


% ------------------------------------------------------------
% Auxiliares de validacao
% ------------------------------------------------------------

creditos_do_semestre(Semestre, Total) :-
    findall(C, ( member(D, Semestre), disciplina(D, _, C, _) ), Cs),
    sum_list(Cs, Total).


% ordem_valida(+Trilha, +JaCursadas)
% Confere que, para cada disciplina de cada semestre, todos os seus
% pre-requisitos transitivos ja estavam disponiveis antes dele.
ordem_valida([], _).
ordem_valida([Semestre|Resto], Acumulado) :-
    forall(
        ( member(D, Semestre), prerequisito_transitivo(D, P) ),
        memberchk(P, Acumulado)
    ),
    append(Acumulado, Semestre, Novo),
    ordem_valida(Resto, Novo).


% ------------------------------------------------------------
% Execucao
% ------------------------------------------------------------
testes :-
    retractall(falhas(_)),
    assertz(falhas(0)),
    writeln('=== BATERIA DE CONSULTAS DE TESTE ==='),
    nl,
    teste_camada1,
    teste_camada2,
    teste_camada3,
    falhas(N),
    (   N =:= 0
    ->  writeln('=== TODOS OS TESTES PASSARAM ===')
    ;   format('=== ~w TESTE(S) FALHARAM ===~n', [N])
    ).
