disciplina(fundamentos_de_sistemas_ciberfisicos, obrigatoria, 4, 1). %1
disciplina(resolucao_de_problemas_com_logica_matematica, obrigatoria, 4, 1). %2
disciplina(filosofia, obrigatoria, 4, 1). %3
disciplina(experiencia_criativa, obrigatoria, 6, 1). %4
disciplina(raciocinio_algoritmo, obrigatoria, 6, 1). %5
disciplina(resolucao_de_problemas_de_natureza_discreta, obrigatoria, 4, 2). %6
disciplina(arquitetura_de_banco_de_dados, obrigatoria, 6, 2). %7
disciplina(programacao_imperativa, obrigatoria, 4, 2). %8
disciplina(programacao_web, obrigatoria, 4, 2). %9
disciplina(conectividade_em_sistemas_ciberfisicos, obrigatoria, 4, 2). %10
disciplina(etica, obrigatoria, 2, 2). %11
disciplina(modelagem_de_fenomenos_fisicos, obrigatoria, 4, 3). %12
disciplina(clinica_de_tic, obrigatoria, 2, 3). %13
disciplina(seguranca_da_informacao, obrigatoria, 4, 3). %14
disciplina(resolucao_de_problemas_com_grafos, obrigatoria, 4, 4). %15
disciplina(game_design, eletiva, 2, 4). %16
disciplina(introducao_a_criptografia, eletiva, 2, 5). %17
disciplina(ciencias_forenses, eletiva, 2, 5). %18
disciplina(criacao_de_trilhas_sonoras_para_jogos, eletiva, 2, 6). %19
disciplina(astrologia_para_todos, eletiva, 3, 6). %20


prerequisito(resolucao_de_problemas_com_grafos,
              modelagem_de_fenomenos_fisicos).

prerequisito(modelagem_de_fenomenos_fisicos,
              resolucao_de_problemas_de_natureza_discreta).

prerequisito(resolucao_de_problemas_de_natureza_discreta,
              resolucao_de_problemas_com_logica_matematica).


% Julia, possui "DP" em múltiplas máterias.
cursou(julia, fundamentos_de_sistemas_ciberfisicos).
cursou(julia, resolucao_de_problemas_com_logica_matematica).
cursou(julia, filosofia).
cursou(julia, experiencia_criativa).
cursou(julia, programacao_imperativa).
cursou(julia, programacao_web).
cursou(julia, conectividade_em_sistemas_ciberfisicos).
cursou(julia, etica).
cursou(julia, modelagem_de_fenomenos_fisicos).
cursou(julia, clinica_de_tic).
cursou(julia, seguranca_da_informacao).
cursou(julia, resolucao_de_problemas_com_grafos).


% Eduardo, está com a grade normal.
cursou(eduardo, fundamentos_de_sistemas_ciberfisicos).
cursou(eduardo, resolucao_de_problemas_com_logica_matematica).
cursou(eduardo, filosofia).
cursou(eduardo, experiencia_criativa).
cursou(eduardo, raciocinio_algoritmo).
cursou(eduardo, resolucao_de_problemas_de_natureza_discreta).
cursou(eduardo, arquitetura_de_banco_de_dados).
cursou(eduardo, programacao_imperativa).
cursou(eduardo, programacao_web).
cursou(eduardo, conectividade_em_sistemas_ciberfisicos).
cursou(eduardo, etica).
cursou(eduardo, modelagem_de_fenomenos_fisicos).
cursou(eduardo, clinica_de_tic).


% Caio, está "Adiantado" com suas máterias.
cursou(caio, fundamentos_de_sistemas_ciberfisicos).
cursou(caio, resolucao_de_problemas_com_logica_matematica).
cursou(caio, filosofia).
cursou(caio, experiencia_criativa).
cursou(caio, raciocinio_algoritmo).
cursou(caio, resolucao_de_problemas_de_natureza_discreta).
cursou(caio, arquitetura_de_banco_de_dados).
cursou(caio, programacao_imperativa).
cursou(caio, programacao_web).
cursou(caio, conectividade_em_sistemas_ciberfisicos).
cursou(caio, etica).
cursou(caio, modelagem_de_fenomenos_fisicos).
cursou(caio, clinica_de_tic).
cursou(caio, seguranca_da_informacao).
cursou(caio, resolucao_de_problemas_com_grafos).
cursou(caio, game_design).
cursou(caio, introducao_a_criptografia).
cursou(caio, ciencias_forenses).
cursou(caio, criacao_de_trilhas_sonoras_para_jogos).
cursou(caio, astrologia_para_todos).
