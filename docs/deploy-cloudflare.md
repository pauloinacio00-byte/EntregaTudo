# Deploy do Entrega Tudo no Cloudflare

## Por que trocar o Netlify pelo Cloudflare

Decidido em 2026-08-03. O site sempre foi publicado no Netlify por upload manual, sem ligação com este repositório — nenhum commit ou Pull Request mudava o que estava no ar, e não havia como testar uma branch antes de decidir publicá-la. Ao investigar como resolver isso, veio à tona um segundo motivo pra trocar de provedor, e não só ligar o Netlify ao Git:

- O plano do Netlify grátis tem limite de **minutos de build** e de **banda/tráfego por mês** — ao estourar, trava ou passa a cobrar.
- No Cloudflare, arquivo estático (que é o caso do Entrega Tudo — um `index.html` só, sem servidor próprio) é servido **sem contar tráfego, em qualquer plano**; o limite é só de builds por mês, bem folgado pra um app sem build pesado.
- O HaX (outro projeto da mesma responsável) já usa Cloudflare — unifica o processo de trabalho entre os dois projetos.

## O que isso muda

Assim como o Netlify, ligar o Cloudflare ao GitHub é feito **no painel do Cloudflare**, não neste repositório — os arquivos deste commit (`wrangler.jsonc`) só dizem ao Cloudflare *o quê* publicar (a pasta `public/`) depois que o projeto já estiver ligado ao repositório.

### Passo a passo (no painel do Cloudflare, feito pela responsável)

1. Acessar [dash.cloudflare.com](https://dash.cloudflare.com) → **Workers & Pages** → **Create application**.
2. Em **Import a repository**, selecionar **Get started**, escolher a conta GitHub e autorizar acesso ao repositório `pauloinacio00-byte/EntregaTudo`, se ainda não estiver autorizado.
3. Selecionar o repositório na lista.
4. Ao configurar o projeto:
   - **Nome do Worker:** `entregatudo` (precisa ser exatamente esse nome — tem que bater com o `name` do arquivo `wrangler.jsonc` deste repositório, senão o build falha).
   - **Build command:** deixar em branco (sem build step).
   - Não é necessário apontar diretório de publicação manualmente — o `wrangler.jsonc` já define `public/` como pasta de assets.
5. Selecionar **Save and Deploy**. O Cloudflare publica o site e mostra uma URL de prévia em `entregatudo.<subdomínio>.workers.dev`.
6. Para habilitar prévia automática por Pull Request (equivalente ao "Deploy Preview" do Netlify): em **Settings → Build → Branch control**, ativar **"non-production branch builds"**. A partir daí, cada PR aberto neste repositório ganha uma build própria com URL de prévia e um comentário automático no próprio PR.

### Depois de ligado

- Todo `git push` no `main` publica sozinho — sem upload manual.
- Cada Pull Request ganha sua própria URL de teste, sem afetar o site publicado.

## Atenção — isso afeta o login Google

O domínio do site muda (de `entregatudo.netlify.app` para o domínio do Cloudflare). Antes de considerar essa migração concluída, é preciso atualizar o **novo domínio** em dois lugares, senão o login Google para de funcionar:

1. **Google Cloud Console** — nas credenciais OAuth do projeto, em "Authorized JavaScript origins" / "Authorized redirect URIs".
2. **Supabase** — em Authentication → URL Configuration (Site URL e Redirect URLs).

Enquanto isso não for atualizado, manter o domínio antigo do Netlify também autorizado nos dois lugares, para não quebrar o app em produção durante a transição.

## Pendência

A chave da TomTom (etapa separada do plano) ainda não tem restrição de domínio configurada. Quando isso for feito, usar o domínio final do Cloudflare, não o do Netlify.

Registrar em `logs/desenvolvimento.md` quando a responsável confirmar o projeto criado e testado no Cloudflare.
