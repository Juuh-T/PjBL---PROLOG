% ARQUIVOS DO PROJETO

:- consult('curriculum.pl').
:- consult('elegibilidade.pl').
:- consult('trilhas.pl').

demo :-
    writeln('--- DEMONSTRAÇÃO ---'),
    forall(
        aluno(Aluno),
        (
        	write('Aluno: '),
        	writeln(Aluno),

         	disciplinas_liberadas(Aluno, Liberadas),
            write('Disciplinas liberadas: '),
            writeln(Liberadas),
            
        	disciplinas_pendentes(Aluno, Pendente),
            write('Disciplinas pendentes: '),
            writeln(Pendentes),
            
        	creditos cursados(Aluno, Creditos),
            write('Creditos cursdos: '),
            writeln(Creditos)
        
        	writeln('--------------------------------'),
            nl
        )
     ).
