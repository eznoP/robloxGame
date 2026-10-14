--!strict
-- Esquema do perfil de dados do jogador (plano §3, §4.5).
-- ProfileService:Reconcile() preenche chaves novas ao evoluir o template; por isso
-- incremente `version` ao mudar a forma e trate migrações no DataService.

export type PlayerData = {
	version: number,
	currency: { coins: number, gems: number },
	level: number,
	xp: number,
	wood: number, -- madeira coletada ainda não vendida
	stats: {
		treesFelled: number,
		woodChopped: number,
		playtimeSeconds: number,
	},
	inventory: {
		axes: { string }, -- AxeIds possuídos
		pets: { string }, -- PetIds possuídos
		materials: { [string]: number }, -- stone, iron, gold, diamond, essence...
	},
	equipped: {
		axe: string, -- AxeId
		pet: string, -- PetId, "" = nenhum
	},
	progression: {
		currentBiome: string,
		unlockedBiomes: { string },
	},
	tutorial: {
		completed: boolean,
		sticksCollected: number,
		axeCrafted: boolean,
		firstTreeCut: boolean,
	},
	settings: {
		musicVolume: number,
		sfxVolume: number,
	},
}

local DataTemplate: PlayerData = {
	version = 1,
	currency = { coins = 0, gems = 0 },
	level = 1,
	xp = 0,
	wood = 0,
	stats = {
		treesFelled = 0,
		woodChopped = 0,
		playtimeSeconds = 0,
	},
	inventory = {
		axes = { "Machado_Graveto" },
		pets = {},
		materials = {},
	},
	equipped = {
		axe = "Machado_Graveto",
		pet = "",
	},
	progression = {
		currentBiome = "Floresta_Iniciante",
		unlockedBiomes = { "Floresta_Iniciante" },
	},
	tutorial = {
		completed = false,
		sticksCollected = 0,
		axeCrafted = false,
		firstTreeCut = false,
	},
	settings = {
		musicVolume = 0.5,
		sfxVolume = 0.8,
	},
}

return DataTemplate
