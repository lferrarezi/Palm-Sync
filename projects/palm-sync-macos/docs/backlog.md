# Backlog inicial

## Fase 0: Descoberta

- [x] Listar modelos Palm que serao suportados no piloto: LifeDrive e Zire 22.
- [ ] Registrar tipo de conexao de cada dispositivo: USB direto, cradle USB, serial com adaptador, Bluetooth/IR se aplicavel.
- [ ] Testar LifeDrive conectado ao macOS e registrar alteracoes em `/dev/cu.*`, USB e logs.
- [ ] Testar Zire 22 conectado ao macOS e registrar alteracoes em `/dev/cu.*`, USB e logs.
- [ ] Confirmar deteccao no macOS com `system_profiler`, `ioreg` e portas `/dev/cu.*`.
- [ ] Avaliar `pilot-link`/`libpisock` em macOS atual.
- [ ] Definir se o helper de comunicacao sera Swift, C ou wrapper sobre biblioteca existente.

## Fase 1: Dados Palm

- [ ] Criar fixture com backup PDB real de teste.
- [ ] Parsear DatebookDB.
- [ ] Parsear AddressDB.
- [ ] Parsear ToDoDB.
- [ ] Parsear MemoDB.
- [ ] Criar normalizacao local para calendario, contato, tarefa e nota.
- [ ] Preservar campos desconhecidos para evitar perda em round-trip.

## Fase 2: App macOS

- [ ] Criar projeto SwiftUI.
- [ ] Implementar banco SQLite.
- [ ] Criar tela de dispositivos.
- [ ] Criar tela de historico de sincronizacao.
- [ ] Criar views de agenda, contatos, tarefas e notas.
- [ ] Criar importacao/exportacao local.

## Fase 3: Sync Palm-local

- [ ] Implementar snapshots pre-sync.
- [ ] Implementar fila de mudancas.
- [ ] Implementar estrategia de merge.
- [ ] Implementar resolucao manual de conflitos.
- [ ] Escrever testes com fixtures antigas.

## Fase 4: Google

- [ ] Configurar OAuth desktop.
- [ ] Integrar Google Calendar API.
- [ ] Integrar Google People API.
- [ ] Armazenar tokens de forma segura no Keychain.
- [ ] Criar mapeamento de campos Palm <-> Google.

## Fase 5: iCloud

- [ ] Testar descoberta CalDAV/CardDAV.
- [ ] Testar autenticacao com autorizacao Apple Account ou senha especifica de app.
- [ ] Integrar calendario iCloud.
- [ ] Integrar contatos iCloud.
- [ ] Documentar limitacoes e campos nao suportados.
