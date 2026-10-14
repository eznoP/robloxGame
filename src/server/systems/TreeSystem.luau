--!strict
--!optimize 2
-- TreeSystem (plano §4.1). Server-authoritative: o servidor escolhe qual árvore foi
-- atingida, valida o tier do machado, aplica dano, derruba, dropa madeira e faz
-- respawn. O cliente só pede o corte (ChopRequest); nunca diz o que acertou.
--
-- Fase 1: spawna o bioma inicial em volta da origem e dá um machado de graveto
-- temporário. O AxeSystem (Fase 2) assume o machado; o BiomeSystem (§4.4) assume as
-- zonas; as MeshParts com LOD entram na Fase 6.

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Shared = game.ReplicatedStorage.Shared
local Types = require(Shared.types)
local Trees = require(Shared.constants.Trees)
local Axes = require(Shared.constants.Axes)
local XP = require(Shared.constants.XP)
local Remotes = require(Shared.remotes)
local TreeFactory = require(script.Parent.TreeFactory)
local DataService = require(script.Parent.Parent.data.DataService)

local TAG = "ChoppableTree"
local CHOP_RANGE = 7
local RESPAWN_SECONDS = 12
local WOOD_LIFETIME = 45

type TreeState = {
	config: Types.TreeConfig,
	health: number,
	maxHealth: number,
	bar: BillboardGui,
	fill: Frame,
	hitPoint: Attachment,
	chips: ParticleEmitter,
	hitSound: Sound,
	spawnCFrame: CFrame,
	falling: boolean,
}

local PALETTES: { [Types.BiomeId]: TreeFactory.Palette } = {
	Floresta_Iniciante = {
		bark = Color3.fromRGB(128, 86, 54),
		barkDark = Color3.fromRGB(101, 67, 42),
		leaves = {
			Color3.fromRGB(88, 184, 84),
			Color3.fromRGB(70, 160, 72),
			Color3.fromRGB(112, 204, 96),
			Color3.fromRGB(58, 142, 66),
		},
	},
}
local DEFAULT_PALETTE = PALETTES.Floresta_Iniciante

local TreeSystem = {}

local trees: { [Model]: TreeState } = {}
local lastChop: { [Player]: number } = {}
local treesFolder: Folder
local woodFolder: Folder
local axeTemplate: Tool

-- Procura o bioma de uma árvore (primeiro da whitelist) para escolher a paleta.
local function paletteFor(config: Types.TreeConfig): TreeFactory.Palette
	local biome = config.biomeWhitelist[1]
	return (biome and PALETTES[biome]) or DEFAULT_PALETTE
end

local function buildHealthBar(tree: Model): (BillboardGui, Frame)
	local gui = Instance.new("BillboardGui")
	gui.Name = "HealthBar"
	gui.Size = UDim2.fromOffset(96, 14)
	gui.StudsOffsetWorldSpace =
		Vector3.new(0, (tree:GetAttribute("Height") :: number or 7) * 0.5 + 2, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 60
	gui.Enabled = false

	local back = Instance.new("Frame")
	back.Name = "Back"
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Color3.fromRGB(38, 28, 22)
	back.BorderSizePixel = 0
	back.Parent = gui
	Instance.new("UICorner", back).CornerRadius = UDim.new(1, 0)

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.AnchorPoint = Vector2.new(0, 0.5)
	fill.Position = UDim2.new(0, 2, 0.5, 0)
	fill.Size = UDim2.new(1, -4, 1, -4)
	fill.BackgroundColor3 = Color3.fromRGB(112, 214, 96)
	fill.BorderSizePixel = 0
	fill.Parent = back
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

	gui.Parent = tree.PrimaryPart
	return gui, fill
end

local function buildEffects(tree: Model): (Attachment, ParticleEmitter, Sound)
	local attachment = Instance.new("Attachment")
	attachment.Name = "HitPoint"
	attachment.Parent = tree.PrimaryPart

	local chips = Instance.new("ParticleEmitter")
	chips.Name = "Chips"
	chips.Enabled = false
	chips.Color = ColorSequence.new(Color3.fromRGB(214, 170, 112), Color3.fromRGB(150, 104, 62))
	chips.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 0),
	})
	chips.Lifetime = NumberRange.new(0.4, 0.8)
	chips.Speed = NumberRange.new(8, 16)
	chips.SpreadAngle = Vector2.new(180, 180)
	chips.Acceleration = Vector3.new(0, -40, 0)
	chips.Rotation = NumberRange.new(0, 360)
	chips.RotSpeed = NumberRange.new(-300, 300)
	chips.Parent = attachment

	local sound = Instance.new("Sound")
	sound.Name = "Hit"
	sound.SoundId = "rbxasset://sounds/swordlunge.wav"
	sound.Volume = 0.6
	sound.RollOffMaxDistance = 80
	sound.Parent = attachment

	return attachment, chips, sound
end

local function spawnWood(position: Vector3)
	local block = Instance.new("Part")
	block.Name = "Wood"
	block.Size = Vector3.new(1.5, 1.5, 1.5)
	block.Material = Enum.Material.Wood
	block.Color = Color3.fromRGB(176, 124, 76)
	block.TopSurface = Enum.SurfaceType.Smooth
	block.BottomSurface = Enum.SurfaceType.Smooth
	block.CFrame = CFrame.new(position)
		* CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
	block.AssemblyLinearVelocity =
		Vector3.new(math.random(-6, 6), math.random(14, 22), math.random(-6, 6))
	block.Parent = woodFolder

	local armed, collected = false, false
	task.delay(0.8, function()
		armed = true
	end)
	block.Touched:Connect(function(hit)
		if not armed or collected then
			return
		end
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then
			return
		end
		collected = true
		DataService.Update(player, function(data)
			data.wood += 1
			data.stats.woodChopped += 1
		end)
		block.CanCollide = false
		block.CanTouch = false
		block.Anchored = true
		local tween = TweenService:Create(
			block,
			TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In),
			{
				Size = Vector3.zero,
				Position = block.Position + Vector3.new(0, 2.5, 0),
			}
		)
		tween:Play()
		tween.Completed:Wait()
		block:Destroy()
	end)
	Debris:AddItem(block, WOOD_LIFETIME)
end

local register -- forward declaration (respawn recria a árvore)

local function fell(tree: Model, state: TreeState, fallDir: Vector3, chopper: Player)
	state.falling = true
	state.bar.Enabled = false
	local config = state.config

	DataService.Update(chopper, function(data)
		data.stats.treesFelled += 1
		data.xp += config.woodValue
		data.level = XP.levelFromTotal(data.xp)
	end)

	local startPivot = tree:GetPivot()
	local basePos = startPivot.Position
	local axis = Vector3.new(0, 1, 0):Cross(fallDir)
	if axis.Magnitude < 0.05 then
		axis = Vector3.new(1, 0, 0)
	end
	axis = axis.Unit

	local angle = Instance.new("NumberValue")
	-- rotaciona a árvore inteira em torno da base (pivô no chão)
	local conn = angle.Changed:Connect(function(value)
		local rotateAboutBase = CFrame.new(basePos)
			* CFrame.fromAxisAngle(axis, value)
			* CFrame.new(-basePos)
		tree:PivotTo(rotateAboutBase * startPivot)
	end)
	local tween = TweenService:Create(
		angle,
		TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Value = math.rad(85) }
	)
	tween:Play()
	tween.Completed:Wait()
	conn:Disconnect()
	angle:Destroy()

	local height = (tree:GetAttribute("Height") :: number) or 7
	local drops = math.random(config.woodDrop.min, config.woodDrop.max)
	for i = 1, drops do
		local along = height * (i - 0.5) / drops
		spawnWood(basePos + fallDir * along + Vector3.new(0, 2.5, 0))
	end

	for _, descendant in tree:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
			TweenService:Create(descendant, TweenInfo.new(0.35), { Transparency = 1 }):Play()
		end
	end
	task.wait(0.4)

	trees[tree] = nil
	tree:Destroy()

	task.wait(RESPAWN_SECONDS)
	register(config, state.spawnCFrame)
end

local function shake(tree: Model, state: TreeState)
	local pivot = tree:GetPivot()
	for i = 1, 4 do
		if state.falling then
			break
		end
		local strength = math.rad(2.0) * (1 - (i - 1) / 4)
		local sign = (i % 2 == 0) and 1 or -1
		tree:PivotTo(pivot * CFrame.Angles(strength * sign, 0, strength * -sign))
		task.wait(0.04)
	end
	if not state.falling then
		tree:PivotTo(pivot)
	end
end

local function damage(
	tree: Model,
	state: TreeState,
	amount: number,
	rootPart: BasePart,
	chopper: Player
)
	state.health = math.max(0, state.health - amount)
	tree:SetAttribute("Health", state.health)

	local trunk = tree.PrimaryPart :: BasePart
	local toPlayer = (rootPart.Position - trunk.Position) * Vector3.new(1, 0, 1)
	local outward = toPlayer.Magnitude > 0.01 and toPlayer.Unit or Vector3.zAxis
	state.hitPoint.WorldPosition = Vector3.new(
		trunk.Position.X,
		rootPart.Position.Y + 0.5,
		trunk.Position.Z
	) + outward * ((tree:GetAttribute("TrunkRadius") :: number) or 1)
	state.chips:Emit(14)
	state.hitSound.PlaybackSpeed = 0.9 + math.random() * 0.25
	state.hitSound:Play()

	state.bar.Enabled = true
	local ratio = state.health / state.maxHealth
	state.fill.BackgroundColor3 = Color3.fromRGB(112, 214, 96)
		:Lerp(Color3.fromRGB(232, 82, 70), 1 - ratio)
	TweenService:Create(state.fill, TweenInfo.new(0.15), { Size = UDim2.new(ratio, -4, 1, -4) })
		:Play()

	if state.health <= 0 then
		task.spawn(fell, tree, state, -outward, chopper)
	else
		task.spawn(shake, tree, state)
	end
end

function register(config: Types.TreeConfig, cframe: CFrame)
	local model = TreeFactory.build(config.size, paletteFor(config))
	model.Name = config.id
	model:PivotTo(cframe)
	model:SetAttribute("TreeId", config.id)
	model:SetAttribute("Health", config.health)
	model:SetAttribute("TrunkRadius", 0.85)
	local _, size = model:GetBoundingBox()
	model:SetAttribute("Height", size.Y)
	model.Parent = treesFolder

	local bar, fill = buildHealthBar(model)
	local hitPoint, chips, hitSound = buildEffects(model)
	trees[model] = {
		config = config,
		health = config.health,
		maxHealth = config.health,
		bar = bar,
		fill = fill,
		hitPoint = hitPoint,
		chips = chips,
		hitSound = hitSound,
		spawnCFrame = cframe,
		falling = false,
	}
	CollectionService:AddTag(model, TAG)
end

-- Machado de graveto temporário (sem script; o cliente trata o Activated).
local function buildAxeTemplate(): Tool
	local tool = Instance.new("Tool")
	tool.Name = "Axe"
	tool.ToolTip = "Clique perto de uma árvore para cortar"
	tool.CanBeDropped = false
	tool.Grip = CFrame.new(0, -1.0, 0)
	CollectionService:AddTag(tool, "Axe")

	local function piece(
		name: string,
		size: Vector3,
		cf: CFrame,
		color: Color3,
		material: Enum.Material
	): BasePart
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cf -- offset local; o Handle fica na origem e as welds travam o relativo
		p.Color = color
		p.Material = material
		p.Anchored = false
		p.CanCollide = false
		p.Massless = true
		p.Parent = tool
		return p
	end

	local handle = piece(
		"Handle",
		Vector3.new(0.32, 3.4, 0.32),
		CFrame.new(),
		Color3.fromRGB(150, 104, 62),
		Enum.Material.Wood
	)
	handle.Massless = false

	local parts = {
		piece(
			"Grip",
			Vector3.new(0.4, 0.9, 0.4),
			CFrame.new(0, -1.15, 0),
			Color3.fromRGB(196, 62, 54),
			Enum.Material.SmoothPlastic
		),
		piece(
			"HeadEye",
			Vector3.new(0.5, 0.75, 0.6),
			CFrame.new(0, 1.25, 0),
			Color3.fromRGB(96, 102, 114),
			Enum.Material.Metal
		),
		piece(
			"Blade",
			Vector3.new(0.22, 1.25, 0.95),
			CFrame.new(0, 1.25, -0.72),
			Color3.fromRGB(205, 212, 222),
			Enum.Material.Metal
		),
		piece(
			"BladeEdge",
			Vector3.new(0.1, 1.45, 0.3),
			CFrame.new(0, 1.25, -1.3),
			Color3.fromRGB(240, 244, 250),
			Enum.Material.Metal
		),
	}
	for _, p in parts do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = p
		weld.Parent = p
	end
	return tool
end

local function giveAxe(player: Player)
	local function grant(character: Model)
		local backpack = player:FindFirstChildOfClass("Backpack")
		if
			backpack
			and not backpack:FindFirstChild("Axe")
			and not character:FindFirstChild("Axe")
		then
			axeTemplate:Clone().Parent = backpack
		end
	end
	if player.Character then
		grant(player.Character)
	end
	player.CharacterAdded:Connect(grant)
end

-- Núcleo server-authoritative: encontra a árvore à frente do jogador e valida.
function TreeSystem.Chop(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then
		return
	end

	local axe = Axes.Configs[data.equipped.axe]
	if not axe then
		return
	end

	-- rate limit pelo swingSpeed do machado
	local now = os.clock()
	local minInterval = 1 / math.max(axe.swingSpeed, 0.1)
	if lastChop[player] and now - lastChop[player] < minInterval * 0.9 then
		return
	end
	lastChop[player] = now

	local best: Model?, bestDistance: number?
	for tree, state in trees do
		if not state.falling and tree.Parent then
			local trunk = tree.PrimaryPart :: BasePart
			local offset = (trunk.Position - rootPart.Position) * Vector3.new(1, 0, 1)
			local distance = offset.Magnitude - ((tree:GetAttribute("TrunkRadius") :: number) or 1)
			local facing = offset.Magnitude < 0.1
				or offset.Unit:Dot(rootPart.CFrame.LookVector) > 0.25
			if
				distance <= CHOP_RANGE
				and facing
				and (not bestDistance or distance < bestDistance)
			then
				best, bestDistance = tree, distance
			end
		end
	end
	if not best then
		return
	end

	local state = trees[best]
	if axe.visualTier < state.config.requiredAxeTier then
		Remotes.ChopFeedback:FireClient(player, "tier", state.config.requiredAxeTier)
		return
	end

	local isCrit = math.random() < axe.criticalChance
	local dmg = axe.damage * (isCrit and axe.criticalMultiplier or 1)
	damage(best, state, dmg, rootPart, player)
	Remotes.ChopFeedback:FireClient(player, isCrit and "crit" or "hit")
end

function TreeSystem.Init()
	treesFolder = Instance.new("Folder")
	treesFolder.Name = "Trees"
	treesFolder.Parent = workspace

	woodFolder = Instance.new("Folder")
	woodFolder.Name = "WoodDrops"
	woodFolder.Parent = workspace

	axeTemplate = buildAxeTemplate()

	-- chão de referência
	local baseplate = workspace:FindFirstChild("Baseplate") :: BasePart?
	local groundY = baseplate and (baseplate.Position.Y + baseplate.Size.Y / 2) or 0

	-- Spawn inicial: bioma Floresta_Iniciante em anel ao redor da origem.
	local forest = Trees.ByBiome["Floresta_Iniciante"] or {}
	local count = 10
	for i = 1, count do
		local id = forest[(i - 1) % #forest + 1]
		local config = Trees.Configs[id]
		local angle = (i / count) * math.pi * 2
		local radius = 26 + (i % 3) * 7
		local pos = Vector3.new(math.cos(angle) * radius, groundY, math.sin(angle) * radius)
		register(config, CFrame.new(pos) * CFrame.Angles(0, math.random() * math.pi * 2, 0))
	end

	Remotes.ChopRequest.OnServerEvent:Connect(function(player)
		TreeSystem.Chop(player)
	end)

	for _, player in Players:GetPlayers() do
		giveAxe(player)
	end
	Players.PlayerAdded:Connect(giveAxe)
	Players.PlayerRemoving:Connect(function(player)
		lastChop[player] = nil
	end)
end

return TreeSystem
