--!strict
-- Machados (plano §3.2, §6.2). Progressão: graveto → madeira → pedra → ferro →
-- ouro → diamante → lendário. Valores de balanceamento iniciais (revisados Fase 7).
-- O "Machado_Graveto" é o machado do tutorial (craftado com 8 gravetos).

local Types = require(script.Parent.Parent.types)

export type AxeConfig = Types.AxeConfig

local Configs: { [Types.AxeId]: Types.AxeConfig } = {
	Machado_Graveto = {
		id = "Machado_Graveto",
		displayName = "Machado de Graveto",
		damage = 1,
		swingSpeed = 1.0,
		requiredLevel = 1,
		craftCost = { stick = 8 },
		visualTier = 1,
		criticalChance = 0.02,
		criticalMultiplier = 1.5,
		modelAsset = "",
		swingAnimation = "",
		hitSound = "",
	},
	Machado_Madeira = {
		id = "Machado_Madeira",
		displayName = "Machado de Madeira",
		damage = 2,
		swingSpeed = 1.1,
		requiredLevel = 3,
		craftCost = { wood_log = 50 },
		visualTier = 2,
		criticalChance = 0.03,
		criticalMultiplier = 1.6,
		modelAsset = "",
		swingAnimation = "",
		hitSound = "",
	},
	Machado_Pedra = {
		id = "Machado_Pedra",
		displayName = "Machado de Pedra",
		damage = 4,
		swingSpeed = 1.15,
		requiredLevel = 8,
		craftCost = { wood_log = 120, stone = 40 },
		visualTier = 3,
		criticalChance = 0.04,
		criticalMultiplier = 1.7,
		modelAsset = "",
		swingAnimation = "",
		hitSound = "",
	},
	Machado_Ferro = {
		id = "Machado_Ferro",
		displayName = "Machado de Ferro",
		damage = 7,
		swingSpeed = 1.25,
		requiredLevel = 18,
		craftCost = { wood_log = 250, iron = 60 },
		visualTier = 4,
		criticalChance = 0.06,
		criticalMultiplier = 1.8,
		modelAsset = "",
		swingAnimation = "",
		hitSound = "",
	},
	Machado_Ouro = {
		id = "Machado_Ouro",
		displayName = "Machado de Ouro",
		damage = 11,
		swingSpeed = 1.4,
		requiredLevel = 35,
		craftCost = { wood_log = 500, gold = 80 },
		visualTier = 5,
		criticalChance = 0.08,
		criticalMultiplier = 2.0,
		modelAsset = "",
		swingAnimation = "",
		hitSound = "",
	},
	Machado_Diamante = {
		id = "Machado_Diamante",
		displayName = "Machado de Diamante",
		damage = 16,
		swingSpeed = 1.5,
		requiredLevel = 60,
		craftCost = { wood_log = 900, diamond = 40 },
		visualTier = 6,
		criticalChance = 0.10,
		criticalMultiplier = 2.25,
		modelAsset = "",
		swingAnimation = "",
		hitSound = "",
	},
	Machado_Lendario = {
		id = "Machado_Lendario",
		displayName = "Machado Lendário",
		damage = 25,
		swingSpeed = 1.7,
		requiredLevel = 90,
		craftCost = { wood_log = 2000, diamond = 120, essence = 10 },
		visualTier = 7,
		criticalChance = 0.15,
		criticalMultiplier = 3.0,
		modelAsset = "",
		swingAnimation = "",
		hitSound = "",
	},
}

-- Ordem por tier (progressão de crafting).
local Order: { Types.AxeId } = {
	"Machado_Graveto",
	"Machado_Madeira",
	"Machado_Pedra",
	"Machado_Ferro",
	"Machado_Ouro",
	"Machado_Diamante",
	"Machado_Lendario",
}

return {
	Configs = Configs,
	Order = Order,
}
