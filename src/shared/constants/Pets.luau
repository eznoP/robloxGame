--!strict
-- Pets geométricos (plano §3.3, §6.3). Multiplicam o valor da madeira.
-- Block/Ball/Cylinder saem de Part.Shape; Pyramid/Torus/Dodecahedron/Icosahedron
-- precisam de malha construída ou gerada no PetSystem (Fase 3) — ver errata:
-- SpecialMesh não tem esses tipos prontos.

local Types = require(script.Parent.Parent.types)

export type PetConfig = Types.PetConfig

local Configs: { [Types.PetId]: Types.PetConfig } = {
	Cubo = {
		id = "Cubo",
		displayName = "Cubo",
		shape = "Block",
		baseMultiplier = 1.1,
		rarity = "Comum",
		dropChance = 0.50,
		color = Color3.fromRGB(180, 180, 190),
		glowColor = Color3.fromRGB(235, 235, 245),
		floatAmplitude = 0.4,
		rotationSpeed = 1.0,
	},
	Esfera = {
		id = "Esfera",
		displayName = "Esfera",
		shape = "Ball",
		baseMultiplier = 1.25,
		rarity = "Incomum",
		dropChance = 0.25,
		color = Color3.fromRGB(90, 200, 120),
		glowColor = Color3.fromRGB(150, 255, 180),
		floatAmplitude = 0.5,
		rotationSpeed = 1.2,
	},
	Piramide = {
		id = "Piramide",
		displayName = "Pirâmide",
		shape = "Pyramid",
		baseMultiplier = 1.5,
		rarity = "Raro",
		dropChance = 0.12,
		color = Color3.fromRGB(90, 150, 230),
		glowColor = Color3.fromRGB(150, 200, 255),
		floatAmplitude = 0.6,
		rotationSpeed = 1.4,
	},
	Cilindro = {
		id = "Cilindro",
		displayName = "Cilindro",
		shape = "Cylinder",
		baseMultiplier = 2.0,
		rarity = "Epico",
		dropChance = 0.06,
		color = Color3.fromRGB(165, 110, 230),
		glowColor = Color3.fromRGB(205, 160, 255),
		floatAmplitude = 0.7,
		rotationSpeed = 1.6,
	},
	Torus = {
		id = "Torus",
		displayName = "Torus",
		shape = "Torus",
		baseMultiplier = 3.0,
		rarity = "Lendario",
		dropChance = 0.03,
		color = Color3.fromRGB(240, 150, 60),
		glowColor = Color3.fromRGB(255, 200, 120),
		floatAmplitude = 0.8,
		rotationSpeed = 1.9,
	},
	Dodecaedro = {
		id = "Dodecaedro",
		displayName = "Dodecaedro",
		shape = "Dodecahedron",
		baseMultiplier = 5.0,
		rarity = "Mitico",
		dropChance = 0.012,
		color = Color3.fromRGB(235, 80, 90),
		glowColor = Color3.fromRGB(255, 140, 150),
		floatAmplitude = 0.9,
		rotationSpeed = 2.2,
	},
	Icosaedro = {
		id = "Icosaedro",
		displayName = "Icosaedro",
		shape = "Icosahedron",
		baseMultiplier = 10.0,
		rarity = "Divino",
		dropChance = 0.004,
		color = Color3.fromRGB(95, 230, 230),
		glowColor = Color3.fromRGB(180, 255, 255),
		floatAmplitude = 1.1,
		rotationSpeed = 2.6,
	},
}

-- Ordem por raridade/multiplicador.
local Order: { Types.PetId } = {
	"Cubo",
	"Esfera",
	"Piramide",
	"Cilindro",
	"Torus",
	"Dodecaedro",
	"Icosaedro",
}

return {
	Configs = Configs,
	Order = Order,
}
