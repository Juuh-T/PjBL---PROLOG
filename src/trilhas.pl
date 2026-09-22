:- consult('elegibilidade.pl').

max_semestres(12).

prerequisito_transitivo(Disciplina, Ancestral) :-
    prerequisito_transitivo(Disciplina, Ancestral, [Disciplina]).

prerequisito_transitivo(Disciplina, Ancestral, _) :-
    prerequisito(Disciplina, Ancestral).

prerequisito_transitivo(Disciplina, Ancestral, Visitados) :-
    prerequisito(Disciplina, Intermediaria),
    \+ memberchk(Intermediaria, Visitados),
    prerequisito_transitivo(Intermediaria, Ancestral, [Intermediaria|Visitados]).

existe_ciclo(Disciplina) :-
    prerequisito_transitivo(Disciplina, Disciplina).

trilha_valida(Aluno, MaxCreditosPorSemestre, Trilha) :-
    findall(D, cursou(Aluno, D), Cursadas),
    disciplinas_pendentes(Aluno, Pendentes),
    max_semestres(MaxSemestres),
    gerar_trilha(Pendentes, Cursadas, MaxCreditosPorSemestre, MaxSemestres, Trilha).

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

elegivel_agora(Cursadas, Disciplina) :-
    forall(
        prerequisito_transitivo(Disciplina, Prerequisito),
        memberchk(Prerequisito, Cursadas)
    ).

subconjunto_com_credito([], _, []).

subconjunto_com_credito([D|Ds], Disponivel, [D|Resto]) :-
    disciplina(D, _, Creditos, _),
    Creditos =< Disponivel,
    Restante is Disponivel - Creditos,
    subconjunto_com_credito(Ds, Restante, Resto).

subconjunto_com_credito([_|Ds], Disponivel, Resto) :-
    subconjunto_com_credito(Ds, Disponivel, Resto).
