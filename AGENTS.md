# Regras de desenvolvimento do Entrega Tudo

Estas regras se aplicam a toda criação, alteração, correção, automação e decisão técnica do projeto. O sistema está sendo desenvolvido com *vibe coding* por uma pessoa leiga; portanto, clareza, rastreabilidade e segurança têm prioridade sobre velocidade.

Este projeto é **separado do HaX** (outro sistema da mesma responsável, repositório próprio). As regras abaixo são as mesmas usadas lá — mesma disciplina, mesmo formato de log — mas nenhum arquivo, histórico, credencial ou decisão deste repositório se mistura com o HaX.

## Regra central: processo contínuo e sem saltos

O trabalho deve sempre seguir as fases abaixo, na ordem indicada. Uma fase só pode começar depois que a anterior estiver registrada e tiver seus pontos de controle atendidos. Se faltar informação, a fase fica marcada como **bloqueada**; ela não deve ser pulada por suposição.

1. **Entender** — registrar o problema, objetivo, pessoas afetadas, resultado esperado e o que ainda não está claro.
2. **Planejar** — definir a solução proposta, limites, riscos, dependências, critérios de aceitação e forma de teste.
3. **Aprovar** — confirmar a decisão com a pessoa responsável quando a mudança envolver escopo, dinheiro, dados, integrações externas, segurança ou comportamento já utilizado. Aprovações automáticas da ferramenta não substituem esse registro.
4. **Executar** — realizar somente o que foi planejado, em partes pequenas e reversíveis quando possível.
5. **Verificar** — testar os critérios de aceitação e registrar o resultado, inclusive falhas ou testes que não puderam ser feitos.
6. **Entregar e acompanhar** — explicar a mudança em linguagem simples, indicar como conferir o resultado, próximos controles, pendências e a condição para encerrar o item.

## Registro obrigatório de cada ação

Antes de qualquer ação material, criar ou atualizar um item em `logs/desenvolvimento.md`, usando o modelo definido naquele arquivo. Ao concluir a ação, completar o mesmo item com:

- o que mudou e onde mudou;
- por que a mudança foi necessária;
- como uma pessoa não técnica pode perceber ou testar o resultado;
- riscos, limitações e como desfazer, quando aplicável;
- evidências da verificação;
- próximo passo de controle, responsável e condição de continuidade.

Pequenas consultas e leituras podem ser agrupadas no mesmo item quando fazem parte de uma única investigação. Nenhuma implementação, configuração, migração, integração ou publicação deve ficar sem registro.

## Comunicação para pessoa leiga

Em toda atualização, usar português simples e explicar siglas ou termos técnicos na primeira vez que forem usados. Priorizar este formato:

1. **Resultado:** o que foi feito ou encontrado.
2. **Impacto:** o que muda para quem usa o sistema.
3. **Como conferir:** passos curtos e concretos.
4. **Próximo controle:** o que será acompanhado, o que falta e quando é seguro avançar.

Nunca apresentar uma alteração como concluída sem informar como ela foi verificada. Nunca esconder incertezas: registrar o que não foi confirmado e o que é necessário para confirmar.

## Portões de controle entre fases

- **Entender → Planejar:** objetivo e dúvida principal registrados.
- **Planejar → Aprovar:** escopo, riscos, dependências e teste definidos.
- **Aprovar → Executar:** decisão registrada; se a aprovação não for necessária, justificar no log.
- **Executar → Verificar:** lista exata de mudanças registrada e sem pendências críticas ocultas.
- **Verificar → Entregar:** critérios de aceitação testados ou limitações explicitamente aceitas pela pessoa responsável.
- **Entregar → Encerrar:** próximo controle definido e nenhuma pendência sem dono ou data/condição de retorno.

## Segurança e continuidade

- Não alterar produção, dados reais, credenciais, integrações externas ou rotinas automáticas sem plano, registro e confirmação explícita quando houver impacto relevante.
- Não apagar, sobrescrever ou reverter materialmente arquivos ou dados sem confirmar o alvo e registrar uma alternativa de recuperação.
- Se uma descoberta mudar o plano, voltar à fase **Planejar**, atualizar o registro e só então continuar.
- Manter documentos, testes e instruções de operação atualizados junto com a mudança de código.
- Tratar uma fase bloqueada como informação útil: registrar o bloqueio, o motivo, quem pode resolvê-lo e a próxima ação necessária.
- Nenhum `git push` para o GitHub acontece sem confirmação explícita da responsável no momento — mesmo em repositório privado.

## Definição de pronto

Um item só está pronto quando a solução, a verificação, a explicação para pessoa leiga e o próximo controle constarem do log. Código alterado, sem esses elementos, é trabalho em andamento.
