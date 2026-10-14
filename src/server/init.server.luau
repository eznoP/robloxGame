--!strict
--!optimize 2
-- Woodcutter Tycoon — bootstrap do servidor.
-- Inicializa os serviços na ordem de dependência. Os demais sistemas (Biome,
-- Progression, Economy) entram aqui conforme cada fase.

local DataService = require(script.data.DataService)
local AxeSystem = require(script.systems.AxeSystem)
local PetSystem = require(script.systems.PetSystem)
local TreeSystem = require(script.systems.TreeSystem)

DataService.Init()
AxeSystem.Init()
PetSystem.Init()
TreeSystem.Init()

print("[WoodcutterTycoon] Server pronto.")
