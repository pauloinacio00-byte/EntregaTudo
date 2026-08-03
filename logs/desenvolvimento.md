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

## [2026-08-03] — Deploy: troca de rumo, Netlify manual → Cloudflare Workers ligado ao GitHub

- Status: aguardando aprovação (arquivos prontos nesta branch; criar o projeto no Cloudflare e ligá-lo ao GitHub só a responsável consegue fazer, no painel do Cloudflare)
- Responsável: assistente (Claude) para o código/documentação; responsável pelo projeto para a ação no painel do Cloudflare
- Objetivo em linguagem simples: ao investigar por que a branch da etapa 4 (PIN) parecia não ter feito efeito, veio à tona que o site é publicado manualmente no Netlify, sem ligação com o GitHub — daí a confusão. A primeira ideia foi só ligar o Netlify existente ao GitHub (já preparado numa branch anterior). A responsável então perguntou se dava pra ir direto para Cloudflare, apontando que o Netlify grátis tem teto de banda/build que pode virar problema, e que o HaX já usa Cloudflare. Pesquisei os limites reais dos dois provedores e a resposta foi sim — a decisão mudou de "ligar Netlify ao GitHub" para "migrar para Cloudflare Workers ligado ao GitHub".
- Impacto para quem usa: nenhum imediato. O site publicado no Netlify continua no ar até a migração ser concluída e testada.

### 1. Entender
- Problema ou oportunidade: (a) falta de deploy observável/testável antes de publicar (mesmo problema já registrado no item anterior, "Ligação do Netlify ao GitHub"); (b) o plano gratuito do Netlify tem limite de minutos de build e de banda/tráfego mensal — em algum momento de crescimento do app isso pode gerar cobrança ou travamento; (c) unificar o processo de deploy com o HaX, que já usa Cloudflare.
- Resultado esperado: Entrega Tudo publicado via Cloudflare Workers (assets estáticos, sem servidor), ligado a este repositório GitHub, com deploy automático no `main` e prévia por Pull Request — mesmo benefício que se buscava com o Netlify, sem o teto de banda.
- Dúvidas em aberto: nenhuma sobre a decisão em si (aprovada). Em aberto: quando o domínio final trocar, é preciso atualizar a lista de domínios autorizados no Google Cloud Console e no Supabase Auth (login Google quebra sem isso) — feito pela responsável, fora desta sessão.
- Pessoas, áreas ou dados afetados: só o processo de publicação. Nenhum dado do app muda. O login Google fica temporariamente sensível durante a troca de domínio (ver "Planejar").

### 2. Planejar
- Solução proposta: (a) descartar a branch anterior (`claude/netlify-github-integration`, nunca enviada ao GitHub, sem efeito nenhum até agora); (b) criar `wrangler.jsonc` (configuração do Cloudflare Workers — assets em `public/`, sem script de servidor); (c) escrever `docs/deploy-cloudflare.md` com o passo a passo de como criar o projeto no painel do Cloudflare e ligá-lo ao GitHub (ação que só a responsável pode fazer — nenhuma ferramenta desta sessão cria projetos Workers ou liga contas GitHub/Cloudflare); (d) atualizar `docs/plano-de-acao-reestruturacao.md` (prioridades, etapa 8, etapa TomTom, dependências) para refletir a troca de provedor.
- Fora do escopo: mudar qualquer coisa no comportamento do app; migrar o HaX (não é tocado); trocar já a chave TomTom por uma restrita ao novo domínio (fica para depois do domínio final estar definido).
- Riscos e como reduzir: (a) mudança de domínio quebra o login Google se as URLs autorizadas não forem atualizadas no Google Cloud Console e no Supabase — documentado em `docs/deploy-cloudflare.md`, com recomendação de manter o domínio antigo do Netlify autorizado também durante a transição; (b) nome do Worker no painel do Cloudflare precisa bater exatamente com o campo `name` do `wrangler.jsonc` (`entregatudo`), senão o build falha — documentado no passo a passo.
- Dependências: acesso da responsável ao painel do Cloudflare (Workers & Pages) e, para o ajuste do login, ao Google Cloud Console e ao painel de Authentication do Supabase.
- Critérios de aceitação: projeto criado no Cloudflare, ligado a este repositório; um push no `main` publica sozinho; um Pull Request gera uma URL de prévia com comentário automático (depois de habilitado "non-production branch builds"); login Google funcionando no domínio novo.
- Como testar: abrir a URL de prévia gerada num PR e navegar no app; depois da troca de domínio, testar o login Google de ponta a ponta.

### 3. Aprovar
- Decisão/aprovação: aprovado migrar para Cloudflare em vez de só ligar o Netlify — 2026-08-03, responsável pelo projeto, após pergunta direta sobre viabilidade e comparação de limites entre os dois provedores.

### 4. Executar
- Ações realizadas: branch `claude/netlify-github-integration` apagada localmente (nunca tinha sido enviada ao GitHub — sem efeito em nada); criada a branch `claude/cloudflare-integration` a partir do `main`; criado `wrangler.jsonc`; criado `docs/deploy-cloudflare.md`; atualizado `docs/plano-de-acao-reestruturacao.md` (seções 1, 2, 3 e 4).
- Arquivos alterados: `wrangler.jsonc` (novo), `docs/deploy-cloudflare.md` (novo), `docs/plano-de-acao-reestruturacao.md` (atualizado).
- Como desfazer: apagar `wrangler.jsonc` e `docs/deploy-cloudflare.md`, ou não mergear esta branch — nenhum efeito em produção até isso. O item anterior sobre Netlify (`docs/deploy-netlify.md`) nunca chegou a ser mergeado no `main`, então não precisa de reversão — só não será mais seguido.

### 5. Verificar
- Testes e resultados: consultada a documentação oficial do Cloudflare (via ferramenta de busca desta sessão) para confirmar os limites reais do plano grátis (build, banda, requisições) e o formato correto do `wrangler.jsonc` para um Worker só de assets, sem script — nenhum teste prático (criação do projeto) foi feito, pois depende de acesso ao painel do Cloudflare.
- O que não foi possível testar: a ligação de fato entre Cloudflare e GitHub, e o funcionamento do login Google no domínio novo — ambos dependem de ações da responsável fora desta sessão.

### 6. Entregar e acompanhar
- Explicação simples da mudança: em vez de só ligar o Netlify (que já era publicado manualmente) ao GitHub, decidimos trocar de provedor para o Cloudflare — mesmo que o HaX já usa —, porque ele não cobra/trava por tráfego de arquivo estático como o Netlify grátis cobra. Preparamos os arquivos de configuração e o passo a passo; falta a responsável criar o projeto no painel do Cloudflare e, depois, atualizar o login Google para o domínio novo.
- Como conferir o resultado: revisar o `diff` desta branch no GitHub; depois de seguir `docs/deploy-cloudflare.md`, abrir um Pull Request de teste e conferir se aparece a URL de prévia.
- Próximo controle: responsável cria o projeto no Cloudflare Workers e liga ao GitHub; em seguida atualiza as URLs autorizadas no Google Cloud Console e no Supabase Auth; só depois disso a branch `claude/etapa4-seguranca-rls-pin` deve ser testada de verdade (login real) via URL de prévia, antes de qualquer merge no `main`.
- Pendências: projeto Cloudflare ainda não criado; login Google ainda não reconfigurado para o novo domínio; teste da etapa 4 (PIN/admin) segue bloqueado até isso.
- Encerramento: item continua aberto até a responsável confirmar o projeto criado e testado.

### 7. Confirmação — projeto Cloudflare criado
- Responsável seguiu o passo a passo de `docs/deploy-cloudflare.md` e confirmou ("tudo feito", 2026-08-03).
- Verificado nesta sessão (leitura direta da conta Cloudflare): Worker `entregatudo` existe, criado e publicado em 2026-08-03 14:00–14:08 (mesmo horário do trabalho desta sessão), ao lado do Worker `hax` já existente.
- Status: **executar** — projeto criado e publicado. Ainda pendentes antes de considerar esta etapa encerrada: (a) confirmar que "non-production branch builds" está ativado (prévia por Pull Request); (b) atualizar as URLs autorizadas no Google Cloud Console e no Supabase Auth para o domínio novo do Cloudflare; (c) só então testar login real na branch `claude/etapa4-seguranca-rls-pin` antes de qualquer merge no `main`.
- Como desfazer, se necessário: o site antigo no Netlify não foi desligado nem alterado — continua no ar como fallback até a transição ser confirmada de ponta a ponta.
