# Palm Sync

Palm Sync e um app macOS para reviver o uso pratico de dispositivos Palm, combinando a experiencia classica do Palm Desktop com sincronizacao moderna.

Palm Sync is a macOS app for bringing Palm devices back into practical use, combining the classic Palm Desktop workflow with modern synchronization.

## Status

- Versao atual / Current version: `0.1.4`
- Lane: prerelease/teste
- Repositorio / Repository: [lferrarezi/Palm-Sync](https://github.com/lferrarezi/Palm-Sync)
- Criado por / Created by: [Luiz Ferrarezi](https://github.com/lferrarezi)

## Idiomas / Languages

A aplicacao deve ser sempre mantida em:

- Portugues brasileiro (`pt-BR`)
- Ingles (`en`)

Every user-facing feature must be kept available in:

- Brazilian Portuguese (`pt-BR`)
- English (`en`)

## Projeto / Project

- `projects/palm-sync-macos`: piloto macOS inspirado no Palm Desktop classico, com sincronizacao local e integracoes modernas.

Dispositivos iniciais de teste:

- Palm LifeDrive
- Palm Zire 22

Initial test devices:

- Palm LifeDrive
- Palm Zire 22

## Versionamento / Versioning

Este workspace segue versionamento controlado:

- Minor impar: prerelease/teste.
- Minor par: release final/aprovada.
- `VERSION`, `CHANGELOG.md` e `AppVersionInfo.swift` devem estar alinhados.

This workspace uses controlled versioning:

- Odd minor: prerelease/test.
- Even minor: final/approved release.
- `VERSION`, `CHANGELOG.md`, and `AppVersionInfo.swift` must stay aligned.

Gates:

```bash
bash scripts/validate-version-policy.sh
bash scripts/release-check.sh
```

## Build e execucao / Build and Run

```bash
./script/build_and_run.sh --verify
```

O app e instalado localmente em:

```text
~/Applications/Palm Sync/Palm Sync.app
```

The app is installed locally at:

```text
~/Applications/Palm Sync/Palm Sync.app
```

## Principios / Principles

- Backup antes de qualquer escrita no dispositivo.
- Sincronizacao explicavel, com historico e resolucao de conflitos.
- Formatos locais abertos quando possivel.
- Integracoes externas isoladas em adaptadores.
- Compatibilidade com Palms antigas tratada como requisito central.

- Backup before any device write.
- Explainable sync with history and conflict resolution.
- Open local formats whenever possible.
- External integrations isolated behind adapters.
- Compatibility with older Palm devices as a core requirement.
