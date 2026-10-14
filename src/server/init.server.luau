--!strict
--!optimize 2
-- Woodcutter Tycoon — bootstrap do servidor.
-- Inicializa os serviços na ordem de dependência. Os demais sistemas (Axe, Pet,
-- Biome, Progression, Economy) entram aqui conforme cada fase.

local DataService = require(script.data.DataService)
local TreeSystem = require(script.systems.TreeSystem)

DataService.Init()
TreeSystem.Init()

print("[WoodcutterTycoon] Server pronto.")
