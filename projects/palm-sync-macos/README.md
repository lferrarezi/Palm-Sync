# Palm Sync macOS

Piloto de aplicativo macOS para sincronizar dispositivos Palm com uma base local moderna e servicos externos.

## Objetivo

Criar uma alternativa contemporanea ao Palm Desktop para macOS, mantendo as funcoes essenciais:

- Agenda/calendario.
- Contatos.
- Tarefas.
- Notas/memos.
- Backup e restauracao.
- Sincronizacao via HotSync quando o hardware permitir.
- Sincronizacao externa com Google e iCloud.

## Escopo do piloto

O piloto deve validar primeiro a parte mais incerta: comunicacao real com o Palm no macOS atual.

## Dispositivos de teste iniciais

- Palm LifeDrive.
- Palm Zire 22.

Ambos devem ser tratados como prioridade para descoberta USB, handshake HotSync, backup PDB e compatibilidade dos bancos classicos.

### Incluido

- App macOS nativo.
- Banco local para dados sincronizados.
- Importacao/exportacao de dados Palm.
- Sync de agenda e contatos.
- Tela de logs e diagnostico.
- Adaptadores iniciais para Google Calendar, Google Contacts e iCloud via protocolos/API suportados.

### Fora do piloto

- Windows/Linux.
- Sincronizacao em nuvem propria.
- Multiusuario.
- Substituir todos os conduits historicos do Palm Desktop.
- Sincronizacao de aplicativos Palm de terceiros.

## Stack recomendada

- Linguagem/app: Swift + SwiftUI.
- Persistencia local: SQLite, possivelmente via GRDB, para controle fino de sync metadata.
- Integracoes Apple locais: EventKit e Contacts apenas se forem uteis como ponte opcional do Mac.
- Google: Google Calendar API e People API.
- iCloud: CalDAV/CardDAV com autenticacao suportada pela Apple para apps de terceiros.
- Comunicacao Palm: camada separada em CLI/helper, para facilitar testes com diferentes cabos, cradles e dispositivos.

## Estrutura criada

```text
Package.swift
Sources/
  PalmSyncMac/
    App/
    Design/
    Domain/
    Services/
    Views/
  PalmProbe/
```

Produtos SwiftPM:

- `PalmSyncMac`: aplicativo macOS SwiftUI.
- `palm-probe`: diagnostico inicial de portas seriais/USB relacionadas a Palm.

## Comandos

```bash
swift build
swift run PalmSyncMac
swift run palm-probe
swift run palm-probe capture --json --output ../../diagnostics/lifedrive/before.json
swift run palm-probe compare ../../diagnostics/lifedrive/before.json ../../diagnostics/lifedrive/after.json
```

## Diagnostico comparativo

O `palm-probe` suporta:

- `capture`: gera uma amostra do estado atual de portas seriais e USB.
- `compare`: compara duas amostras antes/depois.
- `session`: cria a pasta e o README de diagnostico por dispositivo.

Exemplo LifeDrive:

```bash
swift run palm-probe session --device lifedrive --output-dir ../../diagnostics/lifedrive
swift run palm-probe capture --json --output ../../diagnostics/lifedrive/before.json
# conectar LifeDrive e pressionar HotSync
swift run palm-probe capture --json --output ../../diagnostics/lifedrive/after.json
swift run palm-probe compare ../../diagnostics/lifedrive/before.json ../../diagnostics/lifedrive/after.json --json --output ../../diagnostics/lifedrive/comparison.json
```

## UI do piloto

A primeira versao do app ja esta estruturada com:

- `NavigationSplitView` no padrao desktop Apple.
- Painel principal com metricas, dispositivo ativo e historico.
- Secoes classicas: Agenda, Contatos, Tarefas e Notas.
- Secao de Dispositivos com estado, porta, bateria e ultimo sync.
- Centro de Sincronismo com fontes, politicas e historico.
- Ajustes com backup automatico, politica de conflito e colecoes habilitadas.
- Superficies Liquid Glass quando disponiveis no macOS 26+, com fallback para material nativo em macOS anterior.

## Arquitetura proposta

```text
Palm device / cradle
        |
        v
Palm Transport Layer
USB/serial discovery, HotSync handshake, device identity
        |
        v
Palm Data Layer
PDB/PRC parsing, Datebook, Address, ToDo, Memo conduits
        |
        v
Local Sync Core
SQLite, snapshots, change tracking, conflict resolution
        |
        +------------------+
        |                  |
        v                  v
macOS Desktop UI      External Adapters
SwiftUI               Google, iCloud, export/import
```

## Modelo de dados inicial

Entidades locais:

- `devices`: Palms conhecidas, ultimo sync, modelo, user id e estado.
- `collections`: agenda, contatos, tarefas, notas.
- `records`: item normalizado local.
- `record_sources`: relacao entre registro local, Palm record id e registro externo.
- `changes`: fila de alteracoes pendentes.
- `sync_runs`: historico de sincronizacao.
- `conflicts`: divergencias que exigem escolha do usuario.
- `snapshots`: backup antes de escrita destrutiva.

## Estrategia de sincronizacao

1. Primeiro sync sempre cria backup completo do Palm.
2. Cada fonte tem um cursor/token proprio quando disponivel.
3. O core local decide o estado canonico, nao os adaptadores.
4. Escritas no Palm e em servicos externos sao aplicadas em fases separadas.
5. Conflitos sao preservados e exibidos, nao sobrescritos silenciosamente.

## Integracoes externas

Google Calendar suporta sincronizacao incremental por token de sync. Google Contacts deve usar People API, incluindo `etag` nas operacoes de atualizacao/delecao para evitar sobrescrita concorrente.

iCloud deve ser tratado como CalDAV/CardDAV. A Apple documenta acesso de terceiros a Mail, Calendar e Contacts via autorizacao do Apple Account ou senha especifica de app, dependendo do suporte do cliente.

## Riscos tecnicos

- Suporte fisico no macOS moderno para cradles USB/serial antigos.
- Diferencas entre modelos Palm OS e formatos PDB.
- HotSync historico pode exigir engenharia reversa ou bibliotecas antigas.
- iCloud nao oferece uma API publica simples equivalente ao Google para contatos/calendario; CalDAV/CardDAV precisam ser testados cedo.
- Conflitos recorrentes entre campos Palm limitados e modelos modernos de contatos/eventos.
- Codificacao de caracteres e fusos horarios em dados antigos.

## Marcos

### Marco 0: Pesquisa tecnica

- Validar Palm LifeDrive e Palm Zire 22 como modelos-alvo do piloto.
- Identificar cabos/cradles disponiveis para cada modelo.
- Verificar se o macOS detecta o dispositivo.
- Testar leitura basica via serial/USB.
- Inventariar bibliotecas existentes: pilot-link, libpisock, parsers PDB.

### Marco 1: Backup local

- Detectar dispositivo.
- Ler identidade do Palm.
- Fazer dump/backup dos bancos PDB principais.
- Listar registros de agenda, contatos, tarefas e notas.

### Marco 2: Desktop local

- App SwiftUI com quatro secoes: Agenda, Contatos, Tarefas, Notas.
- Banco local SQLite.
- Importacao dos backups PDB.
- Exportacao vCard, ICS e texto/Markdown.

### Marco 3: Sync bidirecional Palm-local

- Detectar alteracoes locais e do Palm.
- Aplicar mudancas simples nos dois sentidos.
- Criar historico de sync e snapshots.
- Implementar resolucao manual de conflitos.

### Marco 4: Google

- OAuth.
- Calendar sync incremental.
- Contacts sync via People API.
- Mapeamento de campos e conflitos.

### Marco 5: iCloud

- Descoberta CalDAV/CardDAV.
- Autenticacao suportada.
- Sincronizacao de calendario e contatos.
- Tratamento de limitacoes especificas do iCloud.

## Primeira decisao pratica

Antes de escrever o app completo, o projeto deve produzir um pequeno utilitario de diagnostico:

```text
palm-probe
```

Ele deve responder:

- O Palm aparece no macOS?
- Por qual porta/interface?
- O handshake HotSync e possivel?
- Quais bancos PDB podem ser listados?
- Um backup bruto pode ser feito com seguranca?

Se essa etapa falhar, o projeto ainda pode seguir por importacao/exportacao de backups PDB existentes, mas a experiencia de HotSync real precisara de outra abordagem de hardware ou software.
