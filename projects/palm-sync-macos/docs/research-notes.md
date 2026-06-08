# Notas de pesquisa

## Fontes verificadas em 2026-06-07

- Google Calendar API documenta sincronizacao incremental por `nextSyncToken`, com sync completo inicial seguido de sincronizacoes incrementais.
- Google People API permite ler, gerenciar e sincronizar contatos, e recomenda usar `etag` para evitar conflitos em atualizacoes/delecoes.
- Apple Support documenta acesso de terceiros a iCloud Mail, Calendar e Contacts por autorizacao da Apple Account ou senha especifica de app.
- Apple informa que Contacts e Calendars do iCloud usam padroes CalDAV/CardDAV.

## Consequencias para o projeto

- Google deve ter adaptadores separados para calendario e contatos.
- iCloud deve ser validado cedo com CalDAV/CardDAV, pois a experiencia de autenticacao pode variar conforme o cliente.
- O core local precisa armazenar tokens/cursors/etags por origem.
- Keychain deve guardar credenciais e tokens.

