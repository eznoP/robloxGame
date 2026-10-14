--!strict
-- Biomas (plano §3.1). Dados puros; o BiomeSystem (Fase 1+) os consome.
-- Valores de balanceamento são iniciais e revisados na Fase 7.

local Types = require(script.Parent.Parent.types)

export type BiomeConfig = Types.BiomeConfig

local Configs: { [Types.BiomeId]: Types.BiomeConfig } = {
	Floresta_Iniciante = {
		id = "Floresta_Iniciante",
		displayName = "Floresta Iniciante",
		levelRequired = 1,
		themeColor = Color3.fromRGB(85, 170, 85),
		personality = "calmo",
		treeDensity = 0.8,
		rareTreeChance = 0.05,
		petDropChance = 0.02,
		woodValueMultiplier = 1.0,
		environmentEffects = {},
		skybox = "",
		musicTrack = "",
		ambientSound = "",
	},
	Vale_Dos_Ventos = {
		id = "Vale_Dos_Ventos",
		displayName = "Vale dos Ventos",
		levelRequired = 10,
		themeColor = Color3.fromRGB(170, 200, 255),
		personality = "ventoso",
		treeDensity = 0.6,
		rareTreeChance = 0.12,
		petDropChance = 0.04,
		woodValueMultiplier = 1.5,
		environmentEffects = { "LeavesBlowing", "WindLines" },
		skybox = "",
		musicTrack = "",
		ambientSound = "",
	},
	Pantano_Escuro = {
		id = "Pantano_Escuro",
		displayName = "Pântano Escuro",
		levelRequired = 25,
		themeColor = Color3.fromRGB(60, 120, 60),
		personality = "misterioso",
		treeDensity = 0.9,
		rareTreeChance = 0.20,
		petDropChance = 0.06,
		woodValueMultiplier = 2.2,
		environmentEffects = { "Fog", "Fireflies", "Bubbles" },
		skybox = "",
		musicTrack = "",
		ambientSound = "",
	},
	Montanhas_Geladas = {
		id = "Montanhas_Geladas",
		displayName = "Montanhas Geladas",
		levelRequired = 50,
		themeColor = Color3.fromRGB(180, 220, 255),
		personality = "rigoroso",
		treeDensity = 0.4,
		rareTreeChance = 0.30,
		petDropChance = 0.08,
		woodValueMultiplier = 3.5,
		environmentEffects = { "Snowfall", "BreathVapor", "Aurora" },
		skybox = "",
		musicTrack = "",
		ambientSound = "",
	},
	Ilha_Vulcanica = {
		id = "Ilha_Vulcanica",
		displayName = "Ilha Vulcânica",
		levelRequired = 100,
		themeColor = Color3.fromRGB(255, 120, 40),
		personality = "explosivo",
		treeDensity = 0.3,
		rareTreeChance = 0.50,
		petDropChance = 0.12,
		woodValueMultiplier = 6.0,
		environmentEffects = { "AshFall", "Embers", "HeatDistortion", "LavaGlow" },
		skybox = "",
		musicTrack = "",
		ambientSound = "",
	},
}

-- Ordem de progressão (desbloqueio por nível).
local Order: { Types.BiomeId } = {
	"Floresta_Iniciante",
	"Vale_Dos_Ventos",
	"Pantano_Escuro",
	"Montanhas_Geladas",
	"Ilha_Vulcanica",
}

return {
	Configs = Configs,
	Order = Order,
}
