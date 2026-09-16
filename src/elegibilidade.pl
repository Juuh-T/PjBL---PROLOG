% Para verificar se o aluno já existe:
aluno_existe(aluno):-
    norvar(aluno),
    cursou(aluno, _),
    !.

% Verdadeiro se todos os pré-requisitos diretos já foram cursados:
prerequisitos_ok(Aluno, Disciplina) :-
    aluno_existe(Aluno),
    disciplina(Disciplina, _, _, _),
    forall(
        prerequisito(Disciplina, Prerequisito),
        cursou(Aluno, Prerequisito)
    ).
    
% Acha todas as disciplinas que o aluno pode cursar agora.
pode_cursar(Aluno, Disciplina) :-
    aluno_existe(Aluno),
    disciplina(Disciplina, _, _, _),
    prerequisitos_ok(Aluno, Disciplina),
    \+ cursou(Aluno, Disciplina).


% Produz uma lista com todas as disciplinas que o aluno pode cursar.
disciplinas_liberadas(Aluno, Lista) :-
    aluno_existe(Aluno),
    findall(
        Disciplina,
        pode_cursar(Aluno, Disciplina),
        Lista
    ).

%vai retornar as disciplinas que são obrigatórias q o aluno ainda ñ cursou
disciplinas_pendentes(Nome, Lista):-
    findall(
        disciplina,
        (
        	obrigatorio(disciplina),
        	\+ cursou(Nome, disciplina) 
        ),
        Lista
    ).

%vai somar os créditos das disciplinas que já faz 
creditos_cursados(Nome, Total):-
    findall(
        Creditos,
        (
            cursou(Nome, disciplina),
            creditos(disciplina, Creditos)
        ),
        ListaCreditos
    ),
    sum_lista(ListaCreditos, Total).
