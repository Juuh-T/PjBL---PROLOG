:- consult('../src/trilhas.pl').

% Camada 1

% Exemplo de Consulta no Terminal:
% disciplinas_por_semestre(1, Lista).
% Adicionar essa parte ao código:
disciplinas_por_semestre(Semestre, Lista) :-
    findall(Disciplina, disciplina(Disciplina, _, _, Semestre), Lista).

% Camada 2

% Exemplo de Consulta no Terminal:
% disciplinas_liberadas(eduardo, Liberadas).
% Exemplo de Consulta no Terminal:
% disciplinas_pendentes(eduardo, Pendentes).

% Exemplo de Consulta no Terminal:
% disciplinas_liberadas(caio, Liberadas).
% Exemplo de Consulta no Terminal:
% disciplinas_pendentes(caio, Pendentes).

% Ao usar a consulta:
% pode_cursar(eduardo, resolucao_de_problemas_com_grafos).
% O resultado obtido será "True"
% Se adicionarmos essa informação:
% cursou(eduardo, resolucao_de_problemas_com_grafos).
% Agora ao usar a consulta:
% pode_cursar(eduardo, resolucao_de_problemas_com_grafos). % O resultado obtido será "False"

% Camada 3

% Exemplo de Consulta no Terminal:
% prerequisito_transitivo(resolucao_de_problemas_com_grafos, Ancestral).

% Exemplo de Consulta no Terminal:
% trilha_valida(eduardo, 20, Trilha).
% Exemplo de Consulta no Terminal:
% trilha_valida(julia, 20, Trilha).

% Adicione essas informações de teste logo após os "prerequisitos"
% prerequisito(teste_a, teste_b).
% prerequisito(teste_b, teste_c).
% prerequisito(teste_c, teste_a).

% Exemplo de Consulta no Terminal:
% existe_ciclo(teste_a).
