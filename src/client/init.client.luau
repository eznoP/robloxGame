--!strict
--!optimize 2
-- Woodcutter Tycoon — bootstrap do cliente.
-- Inicializa os controllers. UI (Fusion), VFX e áudio entram nas fases seguintes.

local ToolController = require(script.controllers.ToolController)

ToolController.Init()

print("[WoodcutterTycoon] Client pronto.")
