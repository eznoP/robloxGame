# Woodcutter Tycoon

Tycoon de corte de árvores para Roblox — progressão por biomas, pets multiplicadores,
crafting de machados e tutorial in-world. Estilo cartoon polido.

Especificação completa: `Plano_Projeto_Woodcutter_Tycoon.pdf` (Cassandra).
Padrões técnicos: skill `roblox-master-dev`.

## Toolchain

Gerenciado por [Rokit](https://github.com/rojo-rbx/rokit) (ver `rokit.toml`):

| Ferramenta | Versão | Uso |
|---|---|---|
| Rojo | 7.7.1 | Sincroniza `src/` com o Studio |
| Wally | 0.3.2 | Dependências externas (`wally.toml`) |
| Selene | 0.32.0 | Linter |
| StyLua | 2.6.0 | Formatador |

## Setup

```bash
rokit install        # instala o toolchain fixado
wally install        # baixa as dependências para Packages/
rojo serve           # inicia o servidor de sync (conecte o plugin Rojo no Studio)
```

No Studio: instale o plugin **Rojo** (Toolbox ou `rojo plugin install`) e clique em
**Connect** para sincronizar.

## Estrutura

```
src/
  shared/   -> ReplicatedStorage.Shared   (types, constants, utils, remotes)
  server/   -> ServerScriptService.Server (systems, data, game)
  client/   -> StarterPlayer.StarterPlayerScripts.Client (controllers, ui, vfx, audio)
assets/     -> meshes, textures, animations, audio (adicionados por fase)
Packages/   -> dependências Wally (gitignored)
```

## Comandos

```bash
rojo build -o WoodcutterTycoon.rbxl   # gera um place a partir do src/
selene src                            # linter
stylua src                            # formata
```

## Status

- **Fase 0 — Setup & Foundation** ✅ toolchain, estrutura, libs core, camada de dados (ProfileService), CI
- **Fase 1 — Tree System** ✅ spawn por bioma, corte server-authoritative, queda, drops, respawn, gate de tier
- **Fase 2 — Axe & Crafting** ✅ 7 machados, craft/equip, mesa de craft, menu Fusion
- **Fase 3 — Pet System** ✅ pets geométricos, drop ponderado, equip + follow, multiplicador de madeira, UI
- **Fase 4 — Progression & Tutorial** ⬜
- **Fase 5 — Polish (UI/VFX/Áudio)** ⬜
- **Fase 6 — Modeling & Assets** ⬜ (hoje: Parts procedurais; meshes com LOD aqui)
- **Fase 7 — Integração & Balance** ⬜

Controles atuais: clique = cortar · **E** na mesa = craftar · **C** = menu de craft · **P** = menu de pets.
