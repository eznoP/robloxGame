--!strict
--!optimize 2
-- Woodcutter Tycoon — bootstrap do servidor.
-- Inicializa os serviços na ordem de dependência. Os sistemas de jogo (Tree, Axe,
-- Pet, Biome, Progression, Economy) entram aqui conforme cada fase.

local DataService = require(script.data.DataService)

DataService.Init()

print("[WoodcutterTycoon] Server pronto.")
