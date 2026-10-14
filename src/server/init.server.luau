--!strict
--!optimize 2
-- Woodcutter Tycoon — bootstrap do servidor.
-- Fase 0: apenas confirma que a árvore Rojo sincronizou e os módulos resolvem.
-- Os sistemas (Tree, Axe, Pet, Biome, Progression, Economy) são inicializados
-- aqui a partir da Fase 1.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local EventBus = require(Shared.utils.EventBus)

local bus = EventBus.new()
bus:on("ServerReady", function()
	print("[WoodcutterTycoon] Server pronto.")
end)
bus:emit("ServerReady")
