--!strict
--!optimize 2
-- AxeSystem (plano §4.2). Crafting e equip server-authoritative: o servidor valida
-- nível e custo, consome recursos, concede o machado e o equipa. O cliente só pede.
-- "wood_log" no custo consome a madeira coletada (data.wood); os demais materiais
-- vêm de data.inventory.materials (fontes de minério entram em fases futuras).

local Players = game:GetService("Players")

local Shared = game.ReplicatedStorage.Shared
local Axes = require(Shared.constants.Axes)
local Remotes = require(Shared.remotes)
local AxeFactory = require(script.Parent.AxeFactory)
local DataService = require(script.Parent.Parent.data.DataService)

local AxeSystem = {}

local lastAction: { [Player]: number } = {}
local ACTION_COOLDOWN = 0.25

local function canAfford(data: any, cost: { [string]: number }): boolean
	for key, amount in cost do
		if key == "wood_log" then
			if data.wood < amount then
				return false
			end
		elseif (data.inventory.materials[key] or 0) < amount then
			return false
		end
	end
	return true
end

local function consume(data: any, cost: { [string]: number })
	for key, amount in cost do
		if key == "wood_log" then
			data.wood -= amount
		else
			data.inventory.materials[key] = (data.inventory.materials[key] or 0) - amount
		end
	end
end

local function pushState(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	Remotes.StateUpdate:FireClient(player, {
		wood = data.wood,
		level = data.level,
		xp = data.xp,
		materials = data.inventory.materials,
		ownedAxes = data.inventory.axes,
		equippedAxe = data.equipped.axe,
	})
end
AxeSystem.pushState = pushState

-- Remove qualquer machado e dá o atualmente equipado.
local function refreshTool(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local config = Axes.Configs[data.equipped.axe]
	if not config then
		return
	end

	local function clear(container: Instance?)
		if not container then
			return
		end
		for _, child in container:GetChildren() do
			if child:IsA("Tool") and child.Name == "Axe" then
				child:Destroy()
			end
		end
	end
	clear(player:FindFirstChildOfClass("Backpack"))
	clear(player.Character)

	local tool = AxeFactory.build(config)
	tool.Parent = player:FindFirstChildOfClass("Backpack") or player.Character
end
AxeSystem.refreshTool = refreshTool

local function rateLimited(player: Player): boolean
	local now = os.clock()
	if lastAction[player] and now - lastAction[player] < ACTION_COOLDOWN then
		return true
	end
	lastAction[player] = now
	return false
end

function AxeSystem.Craft(player: Player, axeId: string)
	if rateLimited(player) then
		return
	end
	local data = DataService.Get(player)
	if not data then
		return
	end
	local config = Axes.Configs[axeId]
	if not config then
		Remotes.CraftFeedback:FireClient(player, "invalid")
		return
	end
	if table.find(data.inventory.axes, axeId) then
		Remotes.CraftFeedback:FireClient(player, "owned", axeId)
		return
	end
	if data.level < config.requiredLevel then
		Remotes.CraftFeedback:FireClient(player, "level", config.requiredLevel)
		return
	end
	if not canAfford(data, config.craftCost) then
		Remotes.CraftFeedback:FireClient(player, "cost", axeId)
		return
	end

	DataService.Update(player, function(d)
		consume(d, config.craftCost)
		table.insert(d.inventory.axes, axeId)
	end)
	Remotes.CraftFeedback:FireClient(player, "crafted", axeId)
	pushState(player)
end

function AxeSystem.Equip(player: Player, axeId: string)
	if rateLimited(player) then
		return
	end
	local data = DataService.Get(player)
	if not data then
		return
	end
	if not table.find(data.inventory.axes, axeId) then
		Remotes.CraftFeedback:FireClient(player, "notowned", axeId)
		return
	end
	DataService.Update(player, function(d)
		d.equipped.axe = axeId
	end)
	refreshTool(player)
	Remotes.CraftFeedback:FireClient(player, "equipped", axeId)
	pushState(player)
end

-- Mesa de craft física, com o ProximityPrompt que o menu do cliente escuta.
local function buildCraftingTable()
	local baseplate = workspace:FindFirstChild("Baseplate") :: BasePart?
	local groundY = baseplate and (baseplate.Position.Y + baseplate.Size.Y / 2) or 0

	local model = Instance.new("Model")
	model.Name = "CraftingTable"

	local top = Instance.new("Part")
	top.Name = "Top"
	top.Size = Vector3.new(5, 0.6, 3)
	top.Anchored = true
	top.Material = Enum.Material.WoodPlanks
	top.Color = Color3.fromRGB(135, 92, 56)
	top.Position = Vector3.new(10, groundY + 2.4, 8)
	top.Parent = model

	for _, dx in { -2, 2 } do
		for _, dz in { -1, 1 } do
			local leg = Instance.new("Part")
			leg.Size = Vector3.new(0.5, 2.4, 0.5)
			leg.Anchored = true
			leg.Material = Enum.Material.Wood
			leg.Color = Color3.fromRGB(101, 67, 42)
			leg.Position = top.Position + Vector3.new(dx, -1.5, dz)
			leg.Parent = model
		end
	end

	local anvil = Instance.new("Part")
	anvil.Name = "Anvil"
	anvil.Size = Vector3.new(1.6, 1.0, 1.0)
	anvil.Anchored = true
	anvil.Material = Enum.Material.Metal
	anvil.Color = Color3.fromRGB(70, 74, 84)
	anvil.Position = top.Position + Vector3.new(0, 0.8, 0)
	anvil.Parent = model

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "CraftPrompt"
	prompt.ActionText = "Craftar"
	prompt.ObjectText = "Mesa de Craft"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = anvil

	model.PrimaryPart = top
	model.Parent = workspace
end

function AxeSystem.Init()
	buildCraftingTable()

	local function onCharacter(player: Player)
		-- dá o machado equipado a cada spawn
		task.defer(refreshTool, player)
	end
	local function onPlayer(player: Player)
		if player.Character then
			onCharacter(player)
		end
		player.CharacterAdded:Connect(function()
			onCharacter(player)
		end)
	end
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerAdded:Connect(onPlayer)
	Players.PlayerRemoving:Connect(function(player)
		lastAction[player] = nil
	end)

	Remotes.CraftRequest.OnServerEvent:Connect(function(player, axeId)
		if type(axeId) == "string" then
			AxeSystem.Craft(player, axeId)
		end
	end)
	Remotes.EquipRequest.OnServerEvent:Connect(function(player, axeId)
		if type(axeId) == "string" then
			AxeSystem.Equip(player, axeId)
		end
	end)
	Remotes.RequestState.OnServerEvent:Connect(function(player)
		pushState(player)
	end)
end

return AxeSystem
