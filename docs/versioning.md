# Versionamento controlado / Controlled Versioning

O PalmIsAlive segue a mesma regra de lanes usada nos outros projetos:

Palm Sync follows the same lane rule used in the other projects:

- Minor impar: prerelease/teste.
- Minor par: release final/aprovada.
- Patch increments permanecem dentro da lane atual.

Exemplos:

- `0.1.0`, `0.1.1`, `0.1.2`: prerelease.
- `0.2.0`, `0.2.1`, `1.0.0`: release final.

## Fonte da verdade

- `VERSION`: versao semver atual.
- `CHANGELOG.md`: registro da versao e tipo de release.
- `projects/palm-sync-macos/Sources/PalmSyncMac/Generated/AppVersionInfo.swift`: versao exposta pelo app.

Esses arquivos devem ser atualizados juntos.

## Gates

Antes de qualquer commit de release:

```bash
bash scripts/validate-version-policy.sh
bash scripts/release-check.sh
```

## Fluxo esperado

1. Escolher a proxima versao respeitando a lane.
2. Atualizar `VERSION`, `CHANGELOG.md` e `AppVersionInfo.swift`.
3. Rodar `bash scripts/release-check.sh`.
4. Commitar apenas arquivos relevantes.
5. Criar tag `vX.Y.Z` quando a versao estiver pronta para distribuicao.

Como ainda e um piloto local, publicacao remota/GitHub Actions ficam para quando o repositorio remoto for configurado.
