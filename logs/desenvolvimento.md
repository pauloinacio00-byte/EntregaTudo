# Log de desenvolvimento

Este arquivo é a memória operacional do projeto. Cada demanda deve ter um item iniciado antes de uma ação material e atualizado até o encerramento. Não apague registros antigos; acrescente correções ou decisões novas abaixo do item original.

## Modelo de registro

```md
## [AAAA-MM-DD] — Título curto da demanda

- Status: entender | planejar | aguardando aprovação | executar | verificar | entregue | bloqueado
- Responsável: nome ou papel
- Objetivo em linguagem simples:
- Impacto para quem usa:

### 1. Entender
- Problema ou oportunidade:
- Resultado esperado:
- Dúvidas em aberto:
- Pessoas, áreas ou dados afetados:

### 2. Planejar
- Solução proposta:
- Fora do escopo:
- Riscos e como reduzir:
- Dependências:
- Critérios de aceitação:
- Como testar:

### 3. Aprovar
- Decisão/aprovação:
- Data e responsável:
- Se não exigiu aprovação humana, justificativa:

### 4. Executar
- Ações realizadas:
- Arquivos, configurações ou serviços alterados:
- Como desfazer, se necessário:

### 5. Verificar
- Testes e resultados:
- O que não foi possível testar:
- Evidências (links, telas, comandos ou registros):

### 6. Entregar e acompanhar
- Explicação simples da mudança:
- Como conferir o resultado:
- Próximo controle (ação, responsável e condição/data):
- Pendências, bloqueios ou decisões futuras:
- Encerramento: data e responsável
```

---

## [2026-08-02] — Reestruturação profissional do Entrega Tudo (separado do HaX)

- Status: executar (etapa 1 de 8 concluída; próximas etapas dependem de decisões abaixo)
- Responsável: assistente (Claude), com aprovação da responsável pelo projeto a cada etapa
- Objetivo em linguagem simples: hoje o Entrega Tudo é um único arquivo HTML de ~5.200 linhas com tudo junto (interface, lógica, chaves de API), sem histórico de banco versionado, sem testes e sem documentação. Vamos organizar o projeto do mesmo jeito disciplinado que já usamos no HaX (regras de trabalho registradas, log de cada mudança, segredos fora do código, banco versionado), mas mantendo os dois projetos completamente separados — nenhum arquivo ou histórico cruza entre HaX e Entrega Tudo.
- Impacto para quem usa: nenhum ainda. Nesta etapa só organizamos documentação, configuração e histórico em volta do app. O HTML que os motoristas usam não mudou de comportamento.

### 1. Entender
- Problema ou oportunidade: o Entrega Tudo cresceu rápido e hoje mistura tudo em um arquivo só (`EntregaTudo-BETA-78.html`, guardado em `OneDrive\Imagens`, fora de qualquer controle de versão até agora); duas chaves sensíveis (API da TomTom e o PIN do painel administrativo) ficam visíveis a qualquer pessoa que abra "ver código-fonte" no navegador; o schema do banco no Supabase não tem nenhum registro de como foi construído; não há como saber se uma mudança futura quebrou algo (zero testes); não há onde consultar decisões passadas (zero log, zero docs). O repositório `EntregaTudo` no GitHub existia, mas vazio (só um README de uma linha).
- Resultado esperado: Entrega Tudo com a mesma estrutura de governança do HaX — `AGENTS.md`, `logs/desenvolvimento.md`, `docs/`, segredos fora do código-fonte, schema do banco versionado em `supabase/migrations/`, testes básicos nas funções mais críticas — como projeto próprio, com seu próprio repositório Git.
- Dúvidas em aberto (resolvidas em 2026-08-02): onde o arquivo `EntregaTudo-BETA-78.html` deveria passar a viver dentro deste repositório → decidido `public/index.html`, mesma convenção do HaX. Versionamento manual por número (`-BETA-78`) → decidido abandonar; a partir de agora o Git versiona, sem mais cópias `-BETA-79`, `-80` etc. na OneDrive. Envio dos primeiros commits ao GitHub → autorizado.
- Pessoas, áreas ou dados afetados: só o projeto Entrega Tudo (app dos motoristas + painel admin embutido). Nenhum arquivo, configuração ou credencial do HaX é tocado.

### 2. Planejar
- Solução proposta (ordem de execução, um item aprovado por vez):
  1. ~~Clonar o repositório numa pasta própria e inspecionar o que já existe lá.~~ ✅ feito — pasta `EntregaTudo/`, irmã de `HaX/`.
  2. ~~Criar `AGENTS.md` e `logs/desenvolvimento.md`.~~ ✅ feito (este arquivo).
  2.1 ~~Trazer o app atual para `public/index.html`, sem numeração manual.~~ ✅ feito — cópia idêntica (diff vazio) do arquivo que estava em `OneDrive\Imagens\EntregaTudo-BETA-78.html`; nenhuma linha de código alterada.
  3. `README.md` com visão geral do app e onde encontrar cada coisa.
  4. Segredos: mover a chave da TomTom e as chaves do Supabase para `.env`/config fora do código; `.env.example` versionado; **tratar a chave da TomTom atual como exposta e recomendar rotação** no painel da TomTom; revisar o PIN hardcoded do painel admin (`"2309"`) — proposta é substituir a checagem client-side por uma trava real no Supabase (RLS/Edge Function), não apenas esconder o PIN.
  5. `docs/` — um arquivo por tema (ex.: fluxo de Frete, geocodificação, painel admin, precificação).
  6. `supabase/migrations/` — versionar o schema atual (`drivers`, `places`, `reviews`, `mrevs`, `rrevs`, `flags`, `fretes`, `announcements`, `configuracoes`) e revisar as RLS policies de cada tabela.
  7. `tests/` — começar pelas funções puras testáveis sem navegador: `fretePreco`, `hav`, `twoOpt`/`nnOrder`, `checkPrecision`, os normalizadores (`normLoc`, `normFrete`, etc.).
  8. Deploy — decisão separada (manter Netlify vs. migrar para Cloudflare, unificando com o HaX); só entra depois do resto estar organizado.
- Fora do escopo por decisão explícita (2026-08-02): quebrar o HTML único em componentes com build step (Vite ou similar). Fica como etapa futura própria, só depois de termos testes no lugar, para reduzir risco de regressão em produção. Qualquer mudança no repositório/sistema HaX.
- Riscos e como reduzir: (a) segredos podem já estar expostos publicamente (o arquivo `.html` circula fora do Git, em `OneDrive\Imagens`) — antes de qualquer rotação, confirmar com a responsável onde mais esse arquivo foi compartilhado; (b) mexer nas RLS do Supabase em produção pode quebrar o app pros motoristas — cada mudança de policy será testada antes de aplicar, com o mesmo cuidado usado no HaX (dry-run/checagem antes de aplicar); (c) nenhum `git push` sem confirmação explícita, mesmo sendo repositório privado.
- Dependências: decisão sobre onde o `.html` atual vai morar no repo (pendente, pergunta feita à responsável); acesso ao painel do Supabase do Entrega Tudo para migrations e revisão de RLS.
- Critérios de aceitação: definidos item a item, no registro de cada etapa (3 a 8 acima) quando for aprovada individualmente.
- Como testar: por etapa — ex. testes automatizados rodando (`node --test`), `supabase db push --dry-run` antes de aplicar migration real, conferência visual de que o app continua funcionando igual no navegador após cada mudança de organização.

### 3. Aprovar
- Decisão/aprovação: aprovado manter o código do app como está por enquanto (sem build step) e organizar governança/docs/segredos/migrations/testes em volta — 2026-08-02, responsável pelo projeto. URL do repositório confirmada e clonagem autorizada na mesma data. Em seguida, aprovado: (a) app vai para `public/index.html` sem numeração manual; (b) commit + push dos documentos de governança e do app autorizados imediatamente — 2026-08-02, responsável pelo projeto.
- Pendente: nada nesta etapa; próxima aprovação necessária será para a etapa 4 (segredos).

### 4. Executar
- Ações realizadas: `git clone` de `https://github.com/pauloinacio00-byte/EntregaTudo.git` para `C:\Users\julia\OneDrive\Área de Trabalho\EntregaTudo` (autenticação via credencial já salva da mesma conta usada no HaX, sem passo extra); inspecionado o repositório — só continha `README.md` de uma linha e um commit inicial, nenhum código, nenhum segredo no histórico; criados `AGENTS.md` e `logs/desenvolvimento.md`; copiado `OneDrive\Imagens\EntregaTudo-BETA-78.html` para `public/index.html` (arquivo original não foi apagado, só copiado); commits organizados por marco e enviados ao GitHub (`git push`).
- Arquivos, configurações ou serviços alterados: `AGENTS.md` (novo), `logs/desenvolvimento.md` (novo), `public/index.html` (novo, cópia idêntica do app). Nenhum arquivo do HaX tocado. Arquivo original em `OneDrive\Imagens\EntregaTudo-BETA-78.html` mantido intacto por enquanto (ver próximo controle).
- Como desfazer, se necessário: `git revert` dos commits no GitHub, ou apagar os arquivos localmente antes de um novo commit — histórico do Git preserva o estado anterior (só o README).

### 5. Verificar
- Testes e resultados: `git log --oneline --all` confirmou 1 commit (`f795592 Initial commit`) antes desta mudança; `git branch -a` confirmou só a branch `main`; nenhum segredo encontrado no histórico existente (histórico muito curto, fácil de conferir); `diff` entre o `.html` original e a cópia em `public/index.html` veio vazio (arquivos idênticos, nenhuma linha de código alterada); commits confirmados no repositório remoto após o push.
- O que não foi possível testar: o app não foi aberto no navegador nesta etapa (é uma cópia 1:1 do que já rodava em produção, sem alteração de código — não há regressão possível só de mover o arquivo).
- Evidências: saída dos comandos `git clone`, `git log`, `git branch`, `git remote -v`, `diff -q`, `wc -l` no terminal, conferida nesta sessão.

### 6. Entregar e acompanhar
- Explicação simples da mudança: o Entrega Tudo agora tem uma pasta própria no computador (separada do HaX), com as mesmas regras de trabalho e o mesmo formato de log usados no HaX, e o app (o arquivo que os motoristas usam) já está dentro do repositório em `public/index.html`, salvo no GitHub. A partir de agora, novas versões do app devem ser commitadas aqui — não mais salvas como `EntregaTudo-BETA-79.html` etc. na OneDrive.
- Como conferir o resultado: abrir a pasta `EntregaTudo` (irmã de `HaX`) e ver `AGENTS.md`, `logs/desenvolvimento.md` e `public/index.html`; conferir no GitHub (github.com/pauloinacio00-byte/EntregaTudo) que os commits chegaram lá.
- Próximo controle: decidir o que fazer com o arquivo original em `OneDrive\Imagens\EntregaTudo-BETA-78.html` (arquivar/apagar depois de confirmar que o repositório é a nova fonte da verdade); seguir para a etapa 4 do plano (segredos — chave da TomTom exposta e PIN do admin), que é a de maior prioridade de segurança.
- Pendências, bloqueios ou decisões futuras: etapas 3 (README), 4 (segredos), 5 (docs), 6 (migrations), 7 (testes), 8 (deploy) do plano acima, cada uma com seu próprio registro quando começar.
- Encerramento: item continua aberto (reestruturação em andamento, várias etapas pela frente).

---

## [2026-08-02] — Etapa 4: segredos no código-fonte (chave TomTom + PIN do admin)

- Status: entender (parte bloqueada — depende de consulta que só a responsável pode rodar)
- Responsável: assistente (Claude), com decisão final da responsável pelo projeto
- Objetivo em linguagem simples: hoje qualquer pessoa que abrir "ver código-fonte" do app enxerga a chave da API de mapas (TomTom) e o PIN de 4 dígitos que libera o painel administrativo (apagar avaliações, motoristas, locais; editar preço do combustível). Precisamos entender o risco real de cada um e corrigir.
- Impacto para quem usa: nenhuma mudança ainda — esta etapa é só investigação e planejamento.

### 1. Entender
- Problema ou oportunidade — são dois problemas de natureza diferente, não um só:
  1. **Chave da TomTom** (`TOMTOM_KEY` em `public/index.html`): é usada direto do navegador pra falar com a API de mapas/trânsito. Chaves desse tipo (mapas, geocodificação) **sempre** ficam visíveis no código do cliente — isso é esperado até em apps grandes (Google Maps, Mapbox funcionam assim). O problema não é "esconder" (é impossível sem criar um servidor no meio, o que está fora do escopo combinado agora) — o problema é que essa chave **não tem nenhuma restrição de domínio configurada no painel da TomTom**, então qualquer pessoa pode copiá-la e usar em outro site, consumindo a cota/gerando custo. Também não sabemos há quanto tempo ou onde o arquivo `.html` com essa chave circulou fora do controle de versão.
  2. **PIN do admin** (`"2309"`, comparado direto no navegador em `AdminPanel`): esse sim é uma falha real de segurança — não é sobre "chave visível", é sobre uma trava de autorização que só existe na tela, não no banco. Se as políticas de RLS (Row Level Security) do Postgres não bloquearem essas mesmas operações (apagar review, apagar motorista, apagar local, editar `configuracoes`) para quem não é admin de verdade, qualquer pessoa pode chamar a API do Supabase direto (sem nem abrir o app) e fazer a mesma coisa, PIN nenhum protege isso. **Não sei ainda se o RLS já cobre isso** — preciso que a responsável rode duas consultas de leitura no SQL Editor do Supabase (não mexo em senha de banco, mesma regra do HaX) e me devolva o resultado.
- Resultado esperado: chave da TomTom restrita por domínio + rotacionada por precaução; PIN do admin substituído por uma trava real no banco (RLS ligada a um usuário autenticado marcado como admin), não mais uma comparação de string no navegador.
- Dúvidas em aberto: (a) resultado das consultas de RLS abaixo. (b) resolvida — o arquivo `.html` só ficou no OneDrive privado da responsável, nunca foi compartilhado ou publicado; risco de vazamento da chave é baixo, então restringir domínio + rotacionar segue como precaução, não como urgência.
- Pessoas, áreas ou dados afetados: tabelas `drivers`, `places`, `reviews`, `mrevs`, `rrevs`, `flags`, `announcements`, `configuracoes` no Supabase do Entrega Tudo; conta da TomTom.

### 2. Planejar
- Solução proposta: (1) TomTom — configurar restrição de domínio no painel da TomTom (só aceitar chamadas vindas de `entregatudo.netlify.app` e, se usado, `localhost` em desenvolvimento) e gerar uma chave nova depois da restrição estar ativa; (2) PIN do admin — depois de ver o resultado do RLS, desenhar a trava correta (provavelmente uma coluna/tabela de admins + policies checando `auth.uid()`), como parte da etapa 6 (migrations) ou adiantada aqui se o RLS hoje estiver aberto.
- Fora do escopo: criar um servidor/proxy para "esconder" a chave da TomTom (não é necessário — restrição de domínio resolve o problema real).
- Riscos e como reduzir: se o RLS estiver aberto hoje, os dados da comunidade (reviews, locais) já estão vulneráveis a apagamento por qualquer pessoa há algum tempo — se for o caso, viramos prioridade máxima antes de qualquer outra etapa do plano.
- Dependências: resultado das consultas SQL (responsável); acesso da responsável ao painel da TomTom para restringir/rotacionar a chave.
- Critérios de aceitação: consulta confirma RLS cobrindo as tabelas sensíveis (ou plano corretivo definido); chave nova da TomTom só funciona a partir do domínio do app (testável tentando usá-la de outro lugar).
- Como testar: chamar a API da TomTom com a chave nova a partir de um domínio não autorizado e confirmar que é rejeitada; tentar um `DELETE`/`PATCH` nas tabelas sensíveis sem estar autenticado como admin e confirmar que o Postgres recusa.

### 3. Aprovar
- Decisão/aprovação: aprovado seguir para investigação (2026-08-02, "prossiga"). Ainda pendente: decisão final sobre correção do PIN até termos o resultado do RLS.

### 4. Executar
- Ações realizadas: responsável rodou as 2 consultas de leitura no SQL Editor do Supabase (projeto Entrega Tudo) e enviou os resultados em prints.
- Resultado da consulta 1 (RLS ligado?): `true` nas 8 tabelas encontradas (`announcements`, `configuracoes`, `drivers`, `flags`, `fretes`, `mrevs`, `places`, `rrevs`). A tabela `reviews` não apareceu — não existe com esse nome exato no schema `public` (a apurar na etapa 6, quando os nomes reais forem confirmados).
- Resultado da consulta 2 (regras existentes): RLS ligado não quer dizer protegido — depende da condição de cada regra, que essa consulta não trouxe (só nome/operação/papel). Leitura preliminar, só pelos nomes e papéis (todos `{public}` = vale pra qualquer um, logado ou não):
  - **Suspeita alta:** `flags`, `mrevs`, `rrevs` têm uma única regra `public_all` cobrindo `ALL` (select/insert/update/delete) — nome sugere liberação total, sem condição.
  - **Suspeita média:** `drivers` tem `drivers_delete` *além* de `drivers_delete_own` — duas regras pra apagar; no Postgres RLS, basta uma permitir. `places_delete` não tem nenhuma versão "own" — mesma suspeita.
  - **A confirmar:** `configuracoes.config_update_authenticated` — o nome sugere restrição a usuário autenticado, mas isso só é garantido pela condição real (`with_check`), não pelo nome da regra.
- Como desfazer, se necessário: não aplicável (só leitura até aqui).

### 5. Verificar
- Testes e resultados: responsável rodou a consulta trazendo `qual`/`with_check` de cada regra. **Confirmado — não era achismo:**
  - 🔴 Crítico (condição literalmente `true`, vale pra qualquer um, sem login): `drivers_delete` (apagar qualquer motorista), `drivers_insert` (criar motorista falso sem checagem), `ann_insert`/`ann_delete` (forjar ou apagar avisos "oficiais" do admin — vetor de golpe/phishing pros motoristas), `flags`/`mrevs`/`rrevs` (`public_all` ALL/true/true — ler, criar, editar, apagar qualquer avaliação ou denúncia), `fretes_select_all` (ler nome, telefone e endereços de todos os chamados de frete — vazamento de dado pessoal de cliente), `fretes_update_own_or_claim` (segunda condição `status='aguardando'` permite editar frete pendente sem login).
  - 🟠 Alto: `drivers_read`/`drivers_select_all` (`true`) expõem o e-mail de todos os motoristas — contradiz a promessa feita na tela de cadastro ("seu e-mail não é exibido publicamente"); `config_update_authenticated` só checa `auth.uid() IS NOT NULL` (logado), não checa se é admin — qualquer motorista logado pode mudar `configuracoes` (ex.: preço do combustível usado na precificação de frete pra todo mundo).
  - ✅ Sem problema: `places_delete` (`created_by = auth.uid()`, corretamente restrito ao autor); leitura aberta de `places`/`configuracoes` parece intencional (diretório comunitário, dado não-sensível).
- Conclusão: o PIN nunca foi a proteção real — e o banco também não está protegendo quase nada hoje. Isso deixou de ser só "etapa 4" e virou prioridade máxima: o app está com essas brechas abertas em produção agora.
- Evidências: 2 prints com o resultado completo da consulta de `qual`/`with_check`, conferidos nesta sessão.

### 6. Entregar e acompanhar (parcial — segue pra correção)
- Explicação simples: descobrimos que o banco de dados do Entrega Tudo, hoje, deixa qualquer pessoa na internet (sem precisar login nem PIN) apagar motoristas, forjar avisos falsos do "administrador", mexer em avaliações e ler dados de clientes que pediram frete (nome, telefone, endereço). O app em si não fica visivelmente diferente — é uma porta aberta que não aparece na tela, só em quem souber chamar a API direto.
- Decisões tomadas para a correção (2026-08-02): (1) só a responsável será admin por enquanto (dá pra adicionar mais gente depois); vou criar uma tabela `admins` + função `is_admin()` no banco, ligada ao UUID real da conta Google dela, substituindo o PIN por uma trava de verdade; (2) qualquer correção será revisada em SQL, testada com `--dry-run`, e só aplicada em produção com aprovação explícita depois disso — mesmo cuidado usado no HaX.
- Próximo controle: obter o UUID (`auth.users.id`) da conta admin pra popular a tabela `admins`; depois disso, escrever e revisar a migration de correção antes de aplicar.
- Pendências: migration de correção ainda não escrita; nada foi alterado em produção até aqui — este item é só diagnóstico.

### 7. Correção — migration escrita, aguardando aplicação
- UUID do admin recebido (2026-08-02): `9af58470-79b0-4b7f-93da-f81a98390001`.
- Migration escrita: `supabase/migrations/20260802235900_corrige_rls_permissiva.sql` — cria tabela `admins` + função `is_admin()`, popula com o UUID acima, e corrige `drivers`, `places`, `flags`, `mrevs`, `rrevs`, `announcements`, `configuracoes`, `fretes` (detalhe de cada mudança nos comentários do próprio arquivo). Nenhuma leitura pública que já era intencional foi removida; criação sem login Google (avaliações, denúncias) continua permitida, como hoje.
- Script de reversão de emergência escrito: `docs/rollback_20260802_rls.sql` — recria as regras exatamente como estavam antes, caso algo quebre depois de aplicar.
- Status: **aguardando aprovação** — arquivos existem só no repositório (Git), nada foi executado no banco de produção ainda.
- Como aplicar quando aprovado: colar o conteúdo do arquivo da migration no SQL Editor do Supabase (projeto Entrega Tudo) e rodar — o script inteiro é uma transação (`begin`/`commit`), então se qualquer linha der erro, nada é aplicado (reverte sozinho). Depois, rodar de novo a consulta de `pg_policies` usada nesta investigação pra confirmar que as regras novas estão lá.

---

## [2026-08-03] — Análise geral e plano de ação para a reestruturação

- Status: entregue (análise e planejamento); execução das etapas listadas segue pendente, item por item
- Responsável: assistente (Claude), a pedido da responsável pelo projeto
- Objetivo em linguagem simples: a responsável pediu uma análise de tudo que já existe no repositório e um plano organizado das próximas medidas, para o projeto não se perder e continuar bem documentado.
- Impacto para quem usa: nenhum — este item é só análise e documentação, nenhum código do app foi alterado.

### 1. Entender
- Problema ou oportunidade: o repositório já tem `AGENTS.md` e este log, mas faltava um documento único de visão geral (o que já foi feito, o que falta, em que ordem) — sem isso, é fácil perder o fio da meada entre uma sessão e outra.
- Resultado esperado: documento de plano de ação, com diagnóstico atual e prioridades claras.

### 2. Planejar
- Solução proposta: revisar o estado real do repositório (arquivos, `public/index.html`, migration pendente) e escrever `docs/plano-de-acao-reestruturacao.md` com diagnóstico, matriz de prioridade e as etapas 3–8 já previstas no item de 2026-08-02, detalhadas.
- Fora do escopo: executar qualquer etapa do plano nesta sessão (aplicar migration, trocar PIN, mexer na chave TomTom) — cada uma exige aprovação própria, como já registrado no item anterior.
- Critérios de aceitação: documento cobre o estado atual verificado no código (não só o que constava no log anterior) e lista prioridades em ordem de risco.
- Como testar: conferência manual do documento pela responsável.

### 3. Aprovar
- Decisão/aprovação: não exigiu aprovação prévia — é documentação/análise, sem mudança de comportamento do app ou do banco.

### 4. Executar
- Ações realizadas: inspeção do repositório (`git log`, `git status`, estrutura de pastas); leitura de `AGENTS.md`, `README.md` e `logs/desenvolvimento.md`; conferência direta no código de `public/index.html` que confirmou que a chave `TOMTOM_KEY` (linha 371) e o PIN `"2309"` (linha 3771) **ainda estão no código**, e que a migration de correção de RLS (etapa 4) **ainda não foi aplicada** — ou seja, a falha crítica registrada em 2026-08-02 continua ativa em produção; criado `docs/plano-de-acao-reestruturacao.md`.
- Arquivos alterados: `docs/plano-de-acao-reestruturacao.md` (novo), este item no `logs/desenvolvimento.md`.
- Como desfazer: apagar o arquivo novo ou reverter o commit — nenhuma mudança de comportamento do app ou do banco.

### 5. Verificar
- Testes e resultados: conferido por leitura direta do arquivo `public/index.html` (grep pelas linhas citadas) que os dois segredos seguem expostos e que a correção de RLS segue não aplicada — condição relatada corretamente no plano.
- O que não foi possível testar: não há como confirmar do lado do código se a migration foi ou não aplicada no banco real (isso só a responsável consegue verificar no painel do Supabase); o plano assume "não aplicada" com base no status registrado no item anterior ("aguardando aprovação"), a confirmar.

### 6. Entregar e acompanhar
- Explicação simples da mudança: foi criado um documento (`docs/plano-de-acao-reestruturacao.md`) que resume o que já foi feito no projeto, o que ainda falta, e em que ordem fazer — com destaque para o fato de que a falha de segurança encontrada em 2026-08-02 (banco aberto para qualquer pessoa apagar dados) **continua sem correção aplicada** até esta data.
- Como conferir o resultado: abrir `docs/plano-de-acao-reestruturacao.md` no repositório.
- Próximo controle: decisão da responsável para retomar e concluir a etapa 4 (aplicar a migration + trocar o PIN no código), que é o item crítico pendente; depois seguir a ordem descrita no plano.
- Pendências: todas as etapas listadas no plano (4 em diante) seguem em aberto, cada uma com aprovação própria quando for iniciada.
- Encerramento: este item (análise/plano) está encerrado; os itens de execução de cada etapa serão registrados separadamente.

---

## [2026-08-03] — Etapa 4 (continuação): substitui o PIN client-side pela checagem real de admin

- Status: executar (código pronto nesta branch; aplicação da migration em produção e teste com login real seguem pendentes — ver "Verificar" e "Próximo controle")
- Responsável: assistente (Claude), com decisão final da responsável pelo projeto
- Objetivo em linguagem simples: o PIN `"2309"` do painel administrativo nunca foi uma proteção de verdade (só escondia um botão na tela). A correção de verdade já tinha sido escrita no banco (migration `20260802235900`, tabela `admins` + função `is_admin()`), mas o app ainda checava o PIN fixo no navegador em vez de perguntar ao banco quem é admin de verdade. Esta etapa troca essa checagem no código do app.
- Impacto para quem usa: hoje, ninguém (o app publicado em produção não muda até esta branch ser aprovada e for ao ar). Quando for ao ar: o painel administrativo deixa de pedir PIN e passa a abrir sozinho só para quem estiver logado com a conta Google cadastrada como admin no banco; qualquer outra pessoa (logada ou não) vê uma tela de "Acesso restrito", sem campo de senha.

### 1. Entender
- Problema ou oportunidade: `pin==="2309"` comparado direto no navegador (linha ~3771 do `public/index.html`) é visível a qualquer um que abra "ver código-fonte"; mesmo com a migration de RLS aplicada, o app continuaria pedindo esse PIN em vez de usar a trava real do banco.
- Resultado esperado: o app consulta `public.is_admin(auth.uid())` via RPC do Supabase (mesma função criada na migration) e só libera o painel para quem o banco reconhece como admin — nenhuma senha fixa no cliente.
- Pessoas, áreas ou dados afetados: componente `AdminPanel` e fluxo de autenticação (`App`) em `public/index.html`. Nenhuma tabela nova; usa a função `is_admin()` já escrita na migration pendente.

### 2. Planejar
- Solução proposta: (a) em `App()`, depois de obter a sessão do Supabase Auth (login Google), chamar `sb.rpc("is_admin",{uid:session.user.id})` e guardar o resultado em um estado `isAdmin`; recalcular a cada login/logout; (b) passar `isAdmin` como prop para `AdminPanel`; (c) dentro de `AdminPanel`, remover os estados `pin`/`unlocked` e usar `isAdmin` no lugar de `unlocked` em todos os pontos (carregamento de dados do painel, aba de fretes, tela de bloqueio); (d) trocar a tela de PIN por uma tela de "Acesso restrito" sem campo de senha, com um botão para fechar.
- Fora do escopo nesta etapa: aplicar a migration em produção (sem acesso direto ao banco nesta sessão — precisa ser feito pela responsável no SQL Editor do Supabase, como já documentado no item de 2026-08-02); mexer na chave TomTom (ação separada, pendente).
- Riscos e como reduzir: (a) se a migration ainda não estiver aplicada quando este código for ao ar, `is_admin()` não existe no banco — a chamada RPC falha, cai no `catch`, e `isAdmin` fica `false` (fail-closed: painel fica bloqueado para todo mundo, inclusive a admin real, em vez de abrir para qualquer um — comportamento seguro, mas exige aplicar a migration **antes** de publicar este código); (b) o login de teste/local (`enter()`, sem sessão Supabase real) nunca deve virar admin — conferido no código: só sessões com `session.user.id` real disparam a checagem.
- Dependências: aplicar a migration `20260802235900_corrige_rls_permissiva.sql` em produção **antes** desta mudança de código ir ao ar (senão ninguém consegue entrar no painel, nem a admin real).
- Critérios de aceitação: com a migration aplicada, a conta Google cadastrada como admin (UUID `9af58470-79b0-4b7f-93da-f81a98390001`) abre o painel sem PIN; qualquer outra conta (ou ninguém logado) vê "Acesso restrito".
- Como testar: login com a conta admin → painel abre direto; login com outra conta Google → "Acesso restrito"; sem login → "Acesso restrito".

### 3. Aprovar
- Decisão/aprovação: seguir com a implementação do código autorizado ("pode continuar", 2026-08-03). Trabalho feito em branch separada (`claude/etapa4-seguranca-rls-pin`, a partir do `main` atualizado) por pedido explícito da responsável, para nada ser publicado direto no `main`/deploy sem revisão. Aplicação da migration em produção e publicação deste código **continuam pendentes de aprovação própria**.

### 4. Executar
- Ações realizadas: criada a branch `claude/etapa4-seguranca-rls-pin` a partir do `main` (já com o plano de ação mergeado). Em `public/index.html`: adicionado estado `isAdmin` e função `checarAdmin(session)` em `App()`, chamada ao logar/deslogar e ao recuperar sessão salva; `isAdmin` passado como prop para `AdminPanel`; removidos os estados `pin`/`unlocked` do `AdminPanel` (12 ocorrências de `unlocked` trocadas por `isAdmin`); tela de PIN substituída por tela de "Acesso restrito" sem campo de senha.
- Arquivos alterados: `public/index.html` (único arquivo de código do app).
- Como desfazer: `git checkout` do commit anterior nesta branch, ou não dar merge/publicar esta branch — o `main` e a produção não são afetados até isso ser decidido.

### 5. Verificar
- Testes e resultados: verificação estática — o arquivo inteiro (JS/JSX dentro do `<script type="text/babel">`) foi passado pelo parser oficial do Babel (`@babel/core` + `@babel/preset-react`, mesmas ferramentas que o navegador usa em produção) e não acusou nenhum erro de sintaxe; `grep` confirmou que não sobrou nenhuma referência solta a `pin`, `setPin`, `setUnlocked` ou `unlocked` no arquivo.
- O que não foi possível testar: teste funcional real no navegador (login Google de verdade, abrir o painel, confirmar que RLS + `is_admin()` funcionam juntos) — o app carrega React/Babel/Supabase via CDN e faz chamadas de login/API para o Supabase real, e a rede desta sessão de trabalho não tem acesso a esses domínios externos (ambiente isolado). **Este teste ainda precisa ser feito** — pela responsável, no navegador normal, depois que a migration estiver aplicada — antes de considerar esta etapa concluída.
- Evidências: saída do `node` rodando o Babel (log desta sessão); `git diff` mostrando as 35 linhas alteradas em `public/index.html`.

### 6. Entregar e acompanhar
- Explicação simples da mudança: o código do painel administrativo foi reescrito para não depender mais de um PIN fixo — agora ele pergunta ao banco de dados "esta pessoa é admin de verdade?" antes de abrir. Isso só funciona depois que a migration do banco (que cria essa checagem) for aplicada. Por enquanto está tudo numa branch separada (`claude/etapa4-seguranca-rls-pin`), nada mudou no app publicado.
- Como conferir o resultado: revisar o `diff` desta branch no GitHub (após o push); depois de aplicar a migration em produção, testar no navegador: logar com a conta admin e confirmar que o painel abre sem pedir PIN; logar com outra conta e confirmar que aparece "Acesso restrito".
- Próximo controle: (1) responsável aplica a migration `20260802235900_corrige_rls_permissiva.sql` em produção (SQL Editor do Supabase) — pré-requisito obrigatório; (2) só depois disso, testar esta branch de verdade (login real) antes de qualquer merge no `main`/deploy; (3) seguir para a etapa TomTom (restringir domínio + rotacionar chave) do plano.
- Pendências: migration não aplicada em produção; teste funcional com login real não feito; merge para `main` não deve acontecer antes dos dois itens acima.
- Encerramento: item continua aberto — código pronto para revisão, execução completa depende da responsável.
