prerequisito_transitivo(Disciplina, Ancestral) :-
    prerequisito(Disciplina, Ancestral).         

prerequisito_transitivo(Disciplina, Ancestral) :-
    prerequisito(Disciplina, Intermediaria),
    prerequisito_transitivo(Intermediaria, Ancestral). 

existe_ciclo(Disciplina) :-
    prerequisito_transitivo(Disciplina,Disciplina).

trilha_valida(Aluno, MaxCreditosPorSemestre, Trilha) :-
    findall(D, cursou(Aluno, D), Cursadas0),
    disciplinas_pendentes(Aluno, Pendentes0),
    gerar_trilha(Pendentes0, Cursadas0, MaxCreditosPorSemestre, 6, Trilha).

gerar_trilha([], _, _, _, []) :- false.
gerar_trilha(Pendentes, Cursadas, MaxCreditos, SemestresRestantes, [Semestre|Resto]) :-
    SemestresRestantes > 0,
    include(elegivel_agora(Cursadas), Pendentes, Liberadas),
    Liberadas \= [],
    subconjunto_com_credito(Liberadas, MaxCreditos, Semestre),
    Semestre \= [],
    subtract(Pendentes, Semestre, NovoPendentes),
    append(Cursadas, Semestre, NovasCursadas),
    N1 is SemestresRestantes - 1,
    gerar_trilha(NovoPendentes, NovasCursadas, MaxCreditos, N1, Resto).

elegivel_agora(Cursadas, D) :-
    forall(prerequisito(D, P), member(P, Cursadas)).

subconjunto_com_credito([], _, []).
subconjunto_com_credito([D|Ds], Max, [D|Resto]) :-
    disciplina(D, _, Creditos, _),
    Creditos =< Max,
    Max1 is Max - Creditos,
    subconjunto_com_credito(Ds, Max1, Resto).
subconjunto_com_credito([_|Ds], Max, Resto) :-
    subconjunto_com_credito(Ds, Max, Resto).
    
