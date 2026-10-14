--!strict
-- Types centrais, compartilhados entre server e client.
-- Os dados vivem em src/shared/constants; aqui ficam só as formas (shapes).

export type Dictionary<V> = { [string]: V }
export type Array<V> = { V }

-- Identificadores. Em Luau estrito, aliases simples são mais úteis que os
-- "branded types" do plano (ver errata da skill).
export type BiomeId = string
export type AxeId = string
export type PetId = string
export type TreeId = string

export type Personality = "calmo" | "ventoso" | "misterioso" | "rigoroso" | "explosivo"
export type Rarity = "Comum" | "Incomum" | "Raro" | "Epico" | "Lendario" | "Mitico" | "Divino"
export type TreeSize = "Pequena" | "Media" | "Grande" | "Massiva" | "Colossal"
export type WoodType = "Comum" | "Incomum" | "Raro" | "Epico" | "Lendario"
-- Formas dos pets. Block/Ball/Cylinder saem de Part.Shape nativo; as demais
-- precisam de malha construída ou gerada (tratado no PetSystem — ver errata).
export type PetShape =
	"Block"
	| "Ball"
	| "Cylinder"
	| "Pyramid"
	| "Torus"
	| "Dodecahedron"
	| "Icosahedron"

export type BiomeConfig = {
	id: BiomeId,
	displayName: string,
	levelRequired: number,
	themeColor: Color3,
	personality: Personality,
	treeDensity: number, -- árvores por 100x100 studs
	rareTreeChance: number, -- 0-1
	petDropChance: number, -- 0-1 (multiplica a chance base da árvore)
	woodValueMultiplier: number,
	environmentEffects: { string }, -- nomes dos efeitos; instanciados no BiomeSystem
	-- Assets preenchidos na Fase 6. "" = ainda não definido.
	skybox: string,
	musicTrack: string,
	ambientSound: string,
}

export type AxeConfig = {
	id: AxeId,
	displayName: string,
	damage: number, -- dano por golpe
	swingSpeed: number, -- golpes por segundo
	requiredLevel: number,
	craftCost: Dictionary<number>, -- { wood_log = 50, stone = 10 }
	visualTier: number, -- 1-7, gate de árvores e efeitos visuais
	criticalChance: number, -- 0-1
	criticalMultiplier: number,
	-- Assets (Fase 6).
	modelAsset: string,
	swingAnimation: string,
	hitSound: string,
}

export type PetConfig = {
	id: PetId,
	displayName: string,
	shape: PetShape,
	baseMultiplier: number, -- multiplicador de valor da madeira
	rarity: Rarity,
	dropChance: number, -- chance base (modificada por biome.petDropChance)
	color: Color3,
	glowColor: Color3,
	floatAmplitude: number, -- bobbing (studs)
	rotationSpeed: number, -- rad/s no idle
}

export type TreeConfig = {
	id: TreeId,
	displayName: string,
	size: TreeSize,
	woodType: WoodType,
	health: number, -- golpes efetivos (dano acumulado) para derrubar
	woodDrop: { min: number, max: number },
	woodValue: number, -- valor por bloco (antes dos multiplicadores)
	requiredAxeTier: number, -- 1-7
	biomeWhitelist: { BiomeId },
	dropPetChance: number, -- chance base (biome modifica)
	-- Assets (Fase 6).
	modelLOD0: string,
	modelLOD1: string,
	modelLOD2: string,
	fallSound: string,
}

return {}
