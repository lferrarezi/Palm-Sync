# Changelog

## 0.1.9 - 2026-06-11

Release kind: prerelease

- Criado target `PalmSyncCore`: nucleo reutilizavel sem dependencia de UI.
- Adicionada persistencia local SQLite (colecoes salvas em Application Support, seed na primeira execucao).
- Implementados parsers PDB para AddressDB, MemoDB, ToDoDB e DatebookDB (CP1252, datas Palm).
- Novo comando "Importar backup Palm (.pdb)" (Cmd+Shift+I) com deduplicacao e registro no historico de sync.
- Implementado motor de merge 3-vias com deteccao de conflitos (nada e sobrescrito sem revisao).
- Esqueleto do protocolo HotSync/DLP com transporte plugavel e sessao testavel (ReadUserInfo).
- Interfaces `CloudProvider` para Google/iCloud e `KeychainStore` para tokens OAuth.
- Busca da sidebar agora filtra agenda, contatos, tarefas e notas.
- Idioma e estado do inspetor persistidos entre execucoes.
- Corrigida corrida na simulacao de sync (atualizacao por ID, guarda de reentrancia).
- `palm-probe`: corrigido deadlock de pipe, timeout no `system_profiler`, sanitizacao do nome de dispositivo.
- Corrigido bootstrap do banco com marcador persistente, incluindo reload do historico de sync e preservacao de colecoes vazias.
- Corrigida importacao PDB para atualizar registros pelo uniqueID do Palm, associada ao dispositivo selecionado, sem duplicar edicoes posteriores.
- Corrigido mapeamento de email/telefone e separacao entre notas e localizacao de eventos.
- Corrigido descarte silencioso de JSON corrompido no SQLite; falhas agora sao explicitas e nao conectam o banco ao store.
- Endurecidos parser PDB, datas Palm, blocos opcionais Datebook e framing DLP contra entradas invalidas.
- Merge 3-vias agora tem ordem deterministica e reporta IDs duplicados em vez de causar trap.
- Release gate agora executa testes e valida README/changelog; bundle instalado recebe o build number correto.
- Adicionados 47 testes (PDB, merge, banco local, DLP, keychain, AppStore e regressoes de persistencia/importacao).

## 0.1.8 - 2026-06-08

Release kind: prerelease

- Evoluido `palm-probe` com subcomandos `capture`, `compare` e `session`.
- Adicionado fluxo de diagnostico antes/depois para HotSync.
- Adicionada criacao de pasta de diagnostico por dispositivo.
- Documentados comandos para LifeDrive e Zire 22.

## 0.1.7 - 2026-06-08

Release kind: prerelease

- Refatorados os dados demonstrativos para usar modelos localizaveis em vez de textos combinados pt/en.
- Corrigidos metadados restantes com o nome antigo PalmIsAlive.
- Melhorado `palm-probe` com status explicito e saida JSON opcional.
- Ajustado bundle identifier para `com.lferrarezi.PalmSync.PalmSyncMac`.

## 0.1.6 - 2026-06-08

Release kind: prerelease

- Adicionada licenca MIT ao projeto.
- README atualizado com informacao de licenciamento.

## 0.1.5 - 2026-06-08

Release kind: prerelease

- Expandida a cobertura bilingue da UI principal e dos dados demonstrativos.
- Menus, paineis, colecoes, diagnostico e politicas agora exibem textos em portugues brasileiro e ingles por idioma selecionado ou texto combinado.

## 0.1.4 - 2026-06-08

Release kind: prerelease

- Projeto renomeado para Palm Sync.
- Adicionado menu Sobre com autoria, GitHub e versao.
- Adicionada base de UI bilingue em portugues brasileiro e ingles, com seletor de idioma.
- README e `.gitignore` revisados para o repositorio `lferrarezi/Palm-Sync`.

## 0.1.3 - 2026-06-08

Release kind: prerelease

- Estabilizado o layout do detalhe ao trocar opcoes no menu lateral.
- Definido tamanho padrao da janela e comportamento de redimensionamento por tamanho minimo.
- Removidas variacoes de padding/background que causavam aparencia de redimensionamento entre secoes.

## 0.1.2 - 2026-06-08

Release kind: prerelease

- Definidos os primeiros dispositivos reais de teste: Palm LifeDrive e Palm Zire 22.
- App atualizado para exibir os dispositivos-alvo reais no painel e na secao Dispositivos.
- Backlog/documentacao atualizados para priorizar diagnostico USB/HotSync nesses modelos.

## 0.1.1 - 2026-06-08

Release kind: prerelease

- Adicionado script macOS `script/build_and_run.sh` para compilar, empacotar, instalar e abrir o app como `.app`.
- Configurado ambiente Codex com acao `Run`.
- Validada instalacao local em `~/Applications/PalmIsAlive/Palm Sync.app`.

## 0.1.0 - 2026-06-07

Release kind: prerelease

- Estrutura inicial do workspace PalmIsAlive.
- Projeto `palm-sync-macos` criado como piloto macOS.
- App SwiftUI com layout desktop, Liquid Glass em macOS 26+ e fallback material.
- Secoes iniciais para painel, agenda, contatos, tarefas, notas, dispositivos, sincronismo e ajustes.
- CLI `palm-probe` para diagnostico inicial de portas seriais/USB.
- Politica de versionamento controlado adicionada.
