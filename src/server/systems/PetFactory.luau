--!strict
--!optimize 2
-- Fábrica de pets geométricos (plano §6.3 — "zero assets externos"). Block/Ball/
-- Cylinder saem de Part.Shape; os demais são compostos de primitivas (ver errata:
-- SpecialMesh não tem Pyramid/Torus/Dodecahedron/Icosahedron). Pivô no centro.
-- Formas priorizam leitura limpa e silhueta distinta sobre exatidão matemática.

local Types = require(game.ReplicatedStorage.Shared.types)

local PetFactory = {}

local function basePart(className: string): BasePart
	local p = Instance.new(className) :: BasePart
	p.Anchored = true
	p.CanCollide = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

local function solid(
	shape: Enum.PartType,
	size: Vector3,
	color: Color3,
	material: Enum.Material
): BasePart
	local p = basePart("Part")
	p.Shape = shape
	p.Size = size
	p.Color = color
	p.Material = material
	return p
end

local function ball(diameter: number, color: Color3, material: Enum.Material): BasePart
	return solid(Enum.PartType.Ball, Vector3.one * diameter, color, material)
end

-- Anel de esferas no plano XY (lê como um torus de frente).
local function ringOf(
	count: number,
	radius: number,
	bead: number,
	color: Color3,
	material: Enum.Material
): { BasePart }
	local parts = {}
	for i = 1, count do
		local a = (i / count) * math.pi * 2
		local b = ball(bead, color, material)
		b.CFrame = CFrame.new(math.cos(a) * radius, math.sin(a) * radius, 0)
		table.insert(parts, b)
	end
	return parts
end

function PetFactory.build(config: Types.PetConfig): Model
	local model = Instance.new("Model")
	model.Name = config.id

	local parts: { BasePart }
	local s = 2

	if config.shape == "Block" then
		parts = {
			solid(Enum.PartType.Block, Vector3.one * s, config.color, Enum.Material.SmoothPlastic),
		}
	elseif config.shape == "Ball" then
		parts = { ball(s, config.color, Enum.Material.SmoothPlastic) }
	elseif config.shape == "Cylinder" then
		local c = solid(
			Enum.PartType.Cylinder,
			Vector3.new(s, s, s),
			config.color,
			Enum.Material.SmoothPlastic
		)
		c.CFrame = CFrame.Angles(0, 0, math.rad(90)) -- em pé
		parts = { c }
	elseif config.shape == "Pyramid" then
		local w = basePart("WedgePart")
		w.Size = Vector3.new(s * 1.4, s * 1.4, s * 1.4)
		w.Color = config.color
		w.Material = Enum.Material.SmoothPlastic
		parts = { w }
	elseif config.shape == "Torus" then
		parts = ringOf(12, s * 0.7, s * 0.5, config.color, Enum.Material.Neon)
	elseif config.shape == "Dodecahedron" then
		-- gema: núcleo neon + anel equatorial
		parts = ringOf(10, s * 0.85, s * 0.3, config.color, Enum.Material.Neon)
		table.insert(parts, 1, ball(s * 1.1, config.color, Enum.Material.Neon))
	else -- Icosahedron: gema maior + anel + picos nos eixos
		parts = ringOf(12, s * 0.95, s * 0.32, config.color, Enum.Material.Neon)
		table.insert(parts, 1, ball(s * 1.2, config.color, Enum.Material.Neon))
		for _, dir in { Vector3.xAxis, -Vector3.xAxis, Vector3.yAxis, -Vector3.yAxis } do
			local spike = ball(s * 0.5, config.color, Enum.Material.Neon)
			spike.CFrame = CFrame.new((dir :: Vector3) * s * 0.9)
			table.insert(parts, spike)
		end
	end

	local root = parts[1]
	root.Name = "Root"
	for _, p in parts do
		p.Parent = model
	end
	model.PrimaryPart = root

	local light = Instance.new("PointLight")
	light.Color = config.glowColor
	light.Range = 8
	light.Brightness = 2
	light.Parent = root

	local attachment = Instance.new("Attachment")
	attachment.Parent = root
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Color = ColorSequence.new(config.glowColor)
	sparkle.Size =
		NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) })
	sparkle.Lifetime = NumberRange.new(0.5, 0.9)
	sparkle.Rate = 10 + config.baseMultiplier * 2
	sparkle.Speed = NumberRange.new(0.4, 1)
	sparkle.SpreadAngle = Vector2.new(180, 180)
	sparkle.LightEmission = 1
	sparkle.Parent = attachment

	return model
end

return PetFactory
