--!strict
--!optimize 2
-- Fábrica de árvores procedurais (Parts, estilo cartoon). Geometria temporária da
-- Fase 1 — as MeshParts com LOD entram na Fase 6 (plano §6.1). A silhueta (tronco,
-- base, copa em bolas) é a mesma em todos os tamanhos, escalada por `size`.

local Types = require(game.ReplicatedStorage.Shared.types)

local TreeFactory = {}

export type Palette = {
	bark: Color3,
	barkDark: Color3,
	leaves: { Color3 },
}

local SIZE_SCALE: { [Types.TreeSize]: number } = {
	Pequena = 0.75,
	Media = 1.0,
	Grande = 1.3,
	Massiva = 1.7,
	Colossal = 2.2,
}

local function part(props: { [string]: any }, parent: Instance): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

-- Constrói a árvore com a base na origem local; o chamador posiciona via PivotTo.
function TreeFactory.build(size: Types.TreeSize, palette: Palette): Model
	local scale = SIZE_SCALE[size] or 1.0
	local trunkHeight = 6.5 * scale
	local trunkDia = 1.7 * scale

	local model = Instance.new("Model")
	local base = Vector3.zero

	local trunk = part({
		Name = "Trunk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(trunkHeight, trunkDia, trunkDia),
		CFrame = CFrame.new(base + Vector3.new(0, trunkHeight / 2, 0))
			* CFrame.Angles(0, 0, math.rad(90)),
		Color = palette.bark,
		Material = Enum.Material.Wood,
	}, model)

	part({
		Name = "Roots",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.9 * scale, trunkDia * 1.45, trunkDia * 1.45),
		CFrame = CFrame.new(base + Vector3.new(0, 0.45 * scale, 0))
			* CFrame.Angles(0, 0, math.rad(90)),
		Color = palette.barkDark,
		Material = Enum.Material.Wood,
	}, model)

	local leaves = palette.leaves
	local balls = {
		{ Vector3.new(0, trunkHeight + 1.3 * scale, 0), 5.6 * scale, 1 },
		{ Vector3.new(-2.0 * scale, trunkHeight + 0.2 * scale, 0.7 * scale), 3.9 * scale, 2 },
		{ Vector3.new(2.0 * scale, trunkHeight + 0.4 * scale, -0.6 * scale), 4.1 * scale, 3 },
		{ Vector3.new(0.3 * scale, trunkHeight + 3.9 * scale, 0.2 * scale), 3.5 * scale, 4 },
	}
	for i, b in balls do
		local offset = b[1] :: Vector3
		local diameter = b[2] :: number
		local colorIndex = b[3] :: number
		part({
			Name = "Leaves" .. i,
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * diameter,
			Position = base + offset,
			Color = leaves[colorIndex] or leaves[1],
			CanCollide = false,
		}, model)
	end

	model.PrimaryPart = trunk
	-- pivô na base, para posicionar e tombar a partir do chão
	trunk.PivotOffset = trunk.CFrame:ToObjectSpace(CFrame.new(base))
	return model
end

return TreeFactory
