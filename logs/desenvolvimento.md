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
- (bloqueado até a responsável rodar as consultas SQL e responder sobre o histórico de exposição do arquivo)
