# Decisoes iniciais

## 001 - Piloto macOS nativo

Status: proposta

Decisao: iniciar com aplicativo macOS nativo em Swift/SwiftUI.

Motivo: o piloto depende de integracao com USB/serial, Keychain, sandbox/permissoes locais e experiencia desktop. Comecar nativo reduz variaveis em comparacao com Electron ou web app.

## 002 - Core de sync separado da UI

Status: proposta

Decisao: manter o core de sincronizacao independente da interface SwiftUI.

Motivo: a comunicacao Palm, parsing PDB, persistencia e adaptadores externos precisam ser testaveis sem abrir a UI.

## 003 - SQLite como fonte local

Status: proposta

Decisao: usar SQLite para estado local, historico e metadados de sync.

Motivo: sincronizacao precisa de cursores, snapshots, mapeamentos externos, auditoria e consultas previsiveis. SwiftData/Core Data podem ser avaliados depois, mas SQLite da mais controle para o MVP.

## 004 - Diagnostico antes do app completo

Status: proposta

Decisao: criar primeiro um utilitario `palm-probe`.

Motivo: a maior incerteza e a comunicacao com hardware Palm no macOS atual. Validar isso cedo evita construir uma UI sobre uma premissa falsa.

## 005 - Adaptadores externos isolados

Status: proposta

Decisao: Google e iCloud entram como adaptadores independentes atras do core local.

Motivo: cada servico tem autenticacao, limites, campos e semantica de sync diferentes. O app deve continuar util mesmo sem conta externa conectada.

