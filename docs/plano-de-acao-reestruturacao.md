# Plano de ação — reestruturação do Entrega Tudo

> Este documento existe para não perdermos o fio da meada. Ele complementa (não substitui) o `logs/desenvolvimento.md` — aqui fica a visão geral e a ordem das etapas; no log fica o registro passo a passo de cada uma, com data e evidência. Sempre que uma etapa daqui mudar de status, atualizar também o log.

## 1. Onde estamos hoje (diagnóstico)

O Entrega Tudo saiu de um arquivo `.html` solto na OneDrive (`EntregaTudo-BETA-78.html`) para um repositório Git com regras de trabalho (`AGENTS.md`) e log de decisões (`logs/desenvolvimento.md`). Isso já é a base de governança. Mas o **código do app em si ainda não mudou nada** — ele foi só copiado para `public/index.html`. Hoje o projeto tem:

- **1 arquivo de aplicação**: `public/index.html`, 5.218 linhas — HTML, CSS (27 linhas) e JavaScript/JSX (5.113 linhas) misturados no mesmo arquivo, sem build step (React e Babel carregados via CDN, JSX transpilado no navegador).
- **0 arquivos de configuração de projeto**: sem `package.json`, sem `netlify.toml`, sem `.env`/`.env.example`, sem CI (nenhum `.yml` de GitHub Actions).
- **1 migration de banco versionada** (`supabase/migrations/20260802235900_corrige_rls_permissiva.sql`) e seu script de reversão (`docs/rollback_20260802_rls.sql`) — **escritos, mas ainda não aplicados em produção** (status "aguardando aprovação" no log).
- **0 testes automatizados.**
- **README com uma linha.**
- **Dois segredos ainda expostos no código-fonte**, confirmados nesta análise:
  - `TOMTOM_KEY` hardcoded na linha 371 de `public/index.html` — sem restrição de domínio, sem rotação ainda feita.
  - PIN do admin (`"2309"`) ainda comparado direto no navegador na linha 3771 — a trava real (tabela `admins` + `is_admin()`) já foi escrita na migration, mas **o código do app ainda não foi trocado para usar essa trava**, e a migration ainda não foi aplicada. Ou seja: hoje, a porta aberta no banco (RLS permissivo) descrita no log de 2026-08-02 **continua aberta em produção**.

Em resumo: o diagnóstico já foi feito (e foi feito bem — está tudo registrado no log). O que falta é executar a correção mais urgente e depois seguir organizando o resto.

## 2. Prioridades — o que é urgente vs. o que pode esperar

| Prioridade | Item | Por quê |
|---|---|---|
| 🔴 Crítica | Aplicar a migration de RLS já escrita (etapa 4) | Hoje qualquer pessoa sem login pode apagar motoristas, forjar avisos falsos e ler dados de clientes (nome/telefone/endereço). Isso já está diagnosticado e a correção já está escrita — só falta aprovar e aplicar. |
| 🔴 Crítica | Trocar o PIN client-side pela checagem real (`is_admin()`) no código do app | A migration cria a trava no banco, mas o app continua confiando no PIN na tela. As duas pontas precisam mudar juntas. |
| 🟠 Alta | Restringir domínio da chave TomTom e rotacionar | Reduz o risco de uso indevido da cota/custo por terceiros. Já planejado, falta executar. |
| 🟠 Alta | `README.md` completo | Hoje quem abre o repositório não sabe o que é o projeto, como rodar, nem onde estão as coisas. Baixo esforço, alto ganho de continuidade. |
| 🟡 Média | `supabase/migrations/` com o schema completo versionado (baseline) | Só existe a migration de correção; o schema original (`drivers`, `places`, `flags`, `fretes`, `mrevs`, `rrevs`, `announcements`, `configuracoes`) não tem uma migration de criação registrada. Se o banco precisar ser recriado hoje, não há como reconstruir só com o Git. |
| 🟡 Média | `docs/` por tema (fluxo de frete, geocodificação, painel admin, precificação) | Facilita retomar decisões sem depender de memória. |
| 🟡 Média | Testes das funções puras (`fretePreco`, `hav`, `twoOpt`, `nnOrder`, `checkPrecision`, normalizadores) | São funções sem dependência de navegador — testáveis com `node --test` sem precisar de build step. Maior retorno por esforço entre os testes possíveis hoje. |
| 🟢 Baixa | CI básico (GitHub Actions rodando os testes a cada push) | Só faz sentido depois de existir pelo menos um teste. |
| 🟢 Baixa | Decisão de deploy (Netlify vs. Cloudflare) | Já foi explicitamente adiada no log; não é bloqueio para nada das etapas acima. |
| ⚪ Futuro, fora de escopo por decisão já tomada | Quebrar o HTML único em componentes com build step (Vite etc.) | Decisão registrada em 2026-08-02: só depois de haver testes, para não arriscar regressão em produção sem rede de segurança. |

## 3. Plano de ação — etapas, em ordem

Cada etapa abaixo deve virar (ou continuar) um item próprio em `logs/desenvolvimento.md`, seguindo o modelo do arquivo (Entender → Planejar → Aprovar → Executar → Verificar → Entregar). Não pular a ordem: a etapa 4 é bloqueante para as demais por ser a única com risco ativo em produção.

### Etapa 4 (continuação) — aplicar a correção de segurança
1. Revisar mais uma vez a migration `20260802235900_corrige_rls_permissiva.sql` e o rollback com a responsável.
2. Aplicar a migration em produção (SQL Editor do Supabase), guardando a saída como evidência.
3. Rodar de novo a consulta de `pg_policies` para confirmar que as regras novas estão ativas.
4. Alterar `public/index.html`: remover a comparação `pin==="2309"` e trocar por checagem de sessão autenticada + `is_admin()` real (chamada ao Supabase, não string fixa no cliente).
5. Testar manualmente: usuário comum não deve conseguir apagar/editar nada sensível; a responsável (UUID já cadastrado) deve continuar conseguindo usar o painel normalmente.
6. Registrar em `logs/desenvolvimento.md` como "verificar" → "entregue", com evidência de antes/depois.

### Etapa TomTom — reduzir exposição da chave
1. No painel da TomTom, restringir a chave por domínio (`entregatudo.netlify.app` + domínio de desenvolvimento, se houver).
2. Gerar uma chave nova só depois da restrição estar ativa.
3. Substituir `TOMTOM_KEY` no `public/index.html` pela nova chave.
4. Testar: chamar a API a partir de um domínio não autorizado e confirmar rejeição.
5. Registrar no log.

### Etapa 3 — `README.md`
Conteúdo mínimo: o que é o app, quem usa (motoristas + painel admin), como rodar localmente (é só abrir o `index.html`? precisa de servidor local por causa de CORS/Supabase?), onde ficam as coisas (`public/`, `supabase/migrations/`, `docs/`, `logs/`), link para `AGENTS.md` como regra de trabalho do projeto.

### Etapa 5 — `docs/` por tema
Um arquivo por assunto, curto e objetivo: fluxo de frete (ciclo de vida de um `frete`, estados), geocodificação/roteirização (TomTom + Leaflet + `twoOpt`/`nnOrder`), painel admin (o que cada ação faz e qual tabela afeta), precificação (`fretePreco`, variáveis de cálculo, `configuracoes`).

### Etapa 6 — schema completo do banco
Criar uma migration "baseline" que documenta a estrutura **atual** de todas as tabelas (colunas, tipos, chaves, índices), não só o que a correção de RLS tocou. Isso é diferente de "criar do zero" — é registrar em SQL o que já existe em produção hoje, extraído do próprio Supabase (`supabase db pull` ou consulta ao `information_schema`), para que o Git passe a ser a fonte confiável do schema.

### Etapa 7 — testes das funções puras
Começar por `fretePreco`, `hav`, `twoOpt`, `nnOrder`, `checkPrecision` e os normalizadores (`normLoc`, `normFrete`, `normRev`, etc.) — todas funções sem estado de navegador, extraíveis e testáveis com `node --test`, sem precisar de build step nem de mexer no `index.html` de produção ainda. Isso cria a "rede de segurança" que falta hoje antes de qualquer refatoração maior.

### Etapa 8 — deploy
Decisão adiada por escolha explícita da responsável. Só retomar depois das etapas acima.

## 4. O que ainda depende de decisão da responsável

- Aprovar a aplicação da migration de RLS em produção (bloqueia tudo o mais urgente).
- Confirmar que pode restringir/rotacionar a chave TomTom agora (precisa de acesso ao painel da TomTom).
- Confirmar se o app roda direto abrindo o `.html` no navegador ou se depende de algo do Netlify em dev (afeta o que vai no README).

## 5. Definição de "projeto bem estruturado" para o Entrega Tudo

Sem inventar processo além do que o projeto já usa — a régua é a mesma do `AGENTS.md`:
- Nenhum segredo real no código-fonte versionado.
- Todo item de trabalho tem um registro em `logs/desenvolvimento.md` antes da ação e completo ao final.
- Schema do banco versionado e igual ao que está em produção.
- Pelo menos as funções críticas (preço, rota, precisão de endereço) com teste automatizado.
- Documentação (`README.md` + `docs/`) suficiente para alguém retomar o projeto do zero sem depender da memória de quem escreveu.
