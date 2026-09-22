% ============================================================
% TESTE DE DETECCAO DE CICLO - ARQUIVO SEPARADO
%
% A Secao 8 do enunciado pede "um arquivo de teste separado com um
% prerequisito/2 circular inserido de proposito, demonstrando que
% existe_ciclo/1 identifica o problema".
%
% Este arquivo suja a base de pre-requisitos de proposito e por isso
% NAO deve ser carregado junto com tests/consultas_teste.pl.
%
% Uso:  swipl tests/ciclo_teste.pl
%       ?- teste_ciclo.
% ============================================================

% Precisa ser dinamico antes do consult para que os fatos circulares
% possam ser inseridos depois que a grade real ja foi carregada.
:- dynamic prerequisito/2.

:- consult('../src/main.pl').


% Ciclo proposital de comprimento 3:
%   teste_a -> teste_b -> teste_c -> teste_a
% Usamos atomos fora da grade real para que a base legitima continue
% valida e os dois casos possam ser comparados no mesmo processo.
:- assertz(prerequisito(teste_a, teste_b)).
:- assertz(prerequisito(teste_b, teste_c)).
:- assertz(prerequisito(teste_c, teste_a)).

% Ciclo degenerado de comprimento 1: disciplina pre-requisito de si
% mesma. Pega o caso base de prerequisito_transitivo/2.
:- assertz(prerequisito(teste_d, teste_d)).

% Cadeia que ENTRA no ciclo sem fazer parte dele: teste_e depende de
% teste_a, mas nenhum caminho volta para teste_e.
:- assertz(prerequisito(teste_e, teste_a)).


relatar(Descricao, true, true)  :- !, format('  ok    ~w~n', [Descricao]).
relatar(Descricao, false, false) :- !, format('  ok    ~w~n', [Descricao]).
relatar(Descricao, Obtido, Esperado) :-
    format('  FALHA ~w (esperado ~w, obtido ~w)~n', [Descricao, Esperado, Obtido]).


% checa(+Descricao, :Objetivo, +Esperado)
checa(Descricao, Objetivo, Esperado) :-
    (   catch(Objetivo, E,
              ( format('  ERRO  ~w (excecao: ~w)~n', [Descricao, E]), fail ))
    ->  Obtido = true
    ;   Obtido = false
    ),
    relatar(Descricao, Obtido, Esperado).


teste_ciclo :-
    writeln('=== TESTE DE DETECCAO DE CICLO ==='),
    nl,

    writeln('--- base malformada: o ciclo deve ser detectado ---'),
    % Se estas consultas respondem alguma coisa, ja esta provado que
    % prerequisito_transitivo/2 termina sobre base ciclica: sem a
    % lista de visitados, o interpretador travaria aqui.
    checa('existe_ciclo(teste_a)', existe_ciclo(teste_a), true),
    checa('existe_ciclo(teste_b)', existe_ciclo(teste_b), true),
    checa('existe_ciclo(teste_c)', existe_ciclo(teste_c), true),
    checa('existe_ciclo(teste_d) - ciclo de comprimento 1',
          existe_ciclo(teste_d), true),
    nl,

    writeln('--- fora do ciclo: nao pode haver falso positivo ---'),
    checa('existe_ciclo(teste_e) - depende do ciclo mas nao pertence a ele',
          existe_ciclo(teste_e), false),
    checa('existe_ciclo(filosofia)', existe_ciclo(filosofia), false),
    checa('existe_ciclo(resolucao_de_problemas_com_grafos) - grade real intacta',
          existe_ciclo(resolucao_de_problemas_com_grafos), false),
    nl,

    writeln('--- terminacao do fecho transitivo sobre base ciclica ---'),
    findall(A, prerequisito_transitivo(teste_a, A), Ancestrais),
    sort(Ancestrais, Distintos),
    length(Distintos, N),
    format('  ok    prerequisito_transitivo(teste_a, A) terminou: ~w ancestrais distintos ~w~n',
           [N, Distintos]),

    findall(B, prerequisito_transitivo(teste_e, B), DeE),
    sort(DeE, DistintosE),
    length(DistintosE, NE),
    format('  ok    prerequisito_transitivo(teste_e, A) terminou: ~w ancestrais distintos~n',
           [NE]),
    nl,

    writeln('--- a grade real continua consultavel ---'),
    setof(P, prerequisito_transitivo(resolucao_de_problemas_com_grafos, P), Reais),
    format('  ok    ancestrais de grafos: ~w~n', [Reais]),
    nl,

    writeln('=== FIM DO TESTE DE CICLO ===').
