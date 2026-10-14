--!strict
--!optimize 2
-- Woodcutter Tycoon — bootstrap do cliente.
-- Inicializa controllers e UI. VFX e áudio entram nas fases seguintes.

local ToolController = require(script.controllers.ToolController)
local CraftingMenu = require(script.ui.CraftingMenu)
local PetEquipUI = require(script.ui.PetEquipUI)

ToolController.Init()
CraftingMenu.Init()
PetEquipUI.Init()

print("[WoodcutterTycoon] Client pronto.")
