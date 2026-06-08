# PalmIsAlive

Workspace para projetos voltados a reviver o uso pratico de dispositivos Palm.

## Projetos

- `projects/palm-sync-macos`: piloto de sincronizacao desktop para macOS, inspirado no Palm Desktop classico, com sincronizacao local e integracoes modernas.

## Versionamento

Este workspace segue versionamento controlado:

- Minor impar: prerelease/teste.
- Minor par: release final/aprovada.
- `VERSION`, `CHANGELOG.md` e `AppVersionInfo.swift` devem estar alinhados.

Gates:

```bash
bash scripts/validate-version-policy.sh
bash scripts/release-check.sh
```

## Direcao inicial

O primeiro produto deve priorizar:

1. Detectar e sincronizar dispositivos Palm reais no macOS.
2. Preservar os dados classicos do Palm: agenda, contatos, tarefas e notas.
3. Oferecer um desktop simples para visualizar, editar, exportar e restaurar dados.
4. Sincronizar com servicos externos como Google e iCloud sem perder o controle local.
5. Comecar com macOS apenas, evitando custo prematuro de multiplataforma.

## Principios

- Backup antes de qualquer escrita no dispositivo.
- Sincronizacao explicavel, com historico e resolucao de conflitos.
- Formatos locais abertos quando possivel.
- Integracoes externas isoladas em adaptadores.
- Compatibilidade com Palms antigas tratada como requisito central, nao como detalhe.
