# Changelog

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
