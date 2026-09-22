:- consult('curriculum.pl').

aluno_existe(Aluno) :-
    cursou(Aluno, _),
    !.

prerequisitos_ok(Aluno, Disciplina) :-
    aluno_existe(Aluno),
    disciplina(Disciplina, _, _, _),
    forall(
        prerequisito(Disciplina, Prerequisito),
        cursou(Aluno, Prerequisito)
    ).

pode_cursar(Aluno, Disciplina) :-
    aluno_existe(Aluno),
    disciplina(Disciplina, _, _, _),
    prerequisitos_ok(Aluno, Disciplina),
    \+ cursou(Aluno, Disciplina).

disciplinas_liberadas(Aluno, Lista) :-
    aluno_existe(Aluno),
    findall(
        Disciplina,
        pode_cursar(Aluno, Disciplina),
        Lista
    ).

disciplinas_pendentes(Aluno, Lista) :-
    aluno_existe(Aluno),
    findall(
        Disciplina,
        (   disciplina(Disciplina, obrigatoria, _, _),
            \+ cursou(Aluno, Disciplina)
        ),
        Lista
    ).

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
