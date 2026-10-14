--!strict
--!optimize 2
-- Fábrica de machados (Parts, estilo cartoon). Cada tier tem visual próprio: cor e
-- material da cabeça/lâmina, brilho nos tiers altos e partícula no lendário.
-- Geometria temporária da Fase 2 — MeshParts únicas entram na Fase 6 (plano §6.2).

local Types = require(game.ReplicatedStorage.Shared.types)

local AxeFactory = {}

type TierVisual = {
	handle: Color3,
	head: Color3,
	headMaterial: Enum.Material,
	blade: Color3,
	glow: Color3?, -- PointLight/trilha nos tiers altos
	trail: boolean,
}

local VISUALS: { [number]: TierVisual } = {
	[1] = {
		handle = Color3.fromRGB(120, 86, 56),
		head = Color3.fromRGB(150, 110, 70),
		headMaterial = Enum.Material.Wood,
		blade = Color3.fromRGB(176, 140, 96),
		trail = false,
	},
	[2] = {
		handle = Color3.fromRGB(150, 104, 62),
		head = Color3.fromRGB(176, 124, 76),
		headMaterial = Enum.Material.Wood,
		blade = Color3.fromRGB(205, 170, 120),
		trail = false,
	},
	[3] = {
		handle = Color3.fromRGB(120, 90, 64),
		head = Color3.fromRGB(120, 124, 130),
		headMaterial = Enum.Material.Slate,
		blade = Color3.fromRGB(170, 176, 184),
		trail = false,
	},
	[4] = {
		handle = Color3.fromRGB(96, 74, 54),
		head = Color3.fromRGB(150, 158, 170),
		headMaterial = Enum.Material.Metal,
		blade = Color3.fromRGB(205, 212, 222),
		trail = false,
	},
	[5] = {
		handle = Color3.fromRGB(96, 74, 54),
		head = Color3.fromRGB(226, 182, 66),
		headMaterial = Enum.Material.Metal,
		blade = Color3.fromRGB(255, 226, 130),
		glow = Color3.fromRGB(255, 210, 110),
		trail = false,
	},
	[6] = {
		handle = Color3.fromRGB(80, 90, 104),
		head = Color3.fromRGB(110, 224, 230),
		headMaterial = Enum.Material.Glass,
		blade = Color3.fromRGB(190, 250, 255),
		glow = Color3.fromRGB(140, 240, 255),
		trail = false,
	},
	[7] = {
		handle = Color3.fromRGB(70, 52, 96),
		head = Color3.fromRGB(190, 110, 255),
		headMaterial = Enum.Material.Neon,
		blade = Color3.fromRGB(230, 190, 255),
		glow = Color3.fromRGB(205, 140, 255),
		trail = true,
	},
}

local function piece(
	tool: Tool,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material
): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Anchored = false
	p.CanCollide = false
	p.Massless = true
	p.Parent = tool
	return p
end

function AxeFactory.build(config: Types.AxeConfig): Tool
	local v = VISUALS[config.visualTier] or VISUALS[1]

	local tool = Instance.new("Tool")
	tool.Name = "Axe"
	tool.ToolTip = config.displayName .. " — clique perto de uma árvore para cortar"
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.Grip = CFrame.new(0, -1.0, 0)
	tool:SetAttribute("AxeId", config.id)
	tool:SetAttribute("Tier", config.visualTier)
	game:GetService("CollectionService"):AddTag(tool, "Axe")

	local handle = piece(
		tool,
		"Handle",
		Vector3.new(0.32, 3.4, 0.32),
		CFrame.new(),
		v.handle,
		Enum.Material.Wood
	)
	handle.Massless = false

	local head = piece(
		tool,
		"HeadEye",
		Vector3.new(0.5, 0.78, 0.62),
		CFrame.new(0, 1.25, 0),
		v.head,
		v.headMaterial
	)
	local blade = piece(
		tool,
		"Blade",
		Vector3.new(0.22, 1.3, 1.0),
		CFrame.new(0, 1.25, -0.72),
		v.blade,
		v.headMaterial
	)
	local edge = piece(
		tool,
		"BladeEdge",
		Vector3.new(0.1, 1.5, 0.32),
		CFrame.new(0, 1.25, -1.32),
		v.blade:Lerp(Color3.new(1, 1, 1), 0.5),
		v.headMaterial
	)
	local grip = piece(
		tool,
		"Grip",
		Vector3.new(0.4, 0.9, 0.4),
		CFrame.new(0, -1.15, 0),
		Color3.fromRGB(196, 62, 54),
		Enum.Material.SmoothPlastic
	)

	for _, p in { head, blade, edge, grip } do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = p
		weld.Parent = p
	end

	if v.glow then
		local light = Instance.new("PointLight")
		light.Color = v.glow
		light.Range = 10
		light.Brightness = 2.5
		light.Parent = head
	end
	if v.trail then
		local attachment = Instance.new("Attachment")
		attachment.Parent = edge
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Color = ColorSequence.new(v.glow or Color3.new(1, 1, 1))
		sparkle.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(1, 0),
		})
		sparkle.Lifetime = NumberRange.new(0.4, 0.7)
		sparkle.Rate = 24
		sparkle.Speed = NumberRange.new(0.5, 1.5)
		sparkle.SpreadAngle = Vector2.new(40, 40)
		sparkle.LightEmission = 1
		sparkle.Parent = attachment
	end

	return tool
end

return AxeFactory
