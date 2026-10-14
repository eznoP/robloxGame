--!strict
--!optimize 2
-- PetSystem (plano §4.3). Pets geométricos que flutuam ao lado do jogador e
-- multiplicam o valor da madeira. Server-authoritative: drop, equip e multiplicador
-- são decididos no servidor. O multiplicador em si é aplicado no TreeSystem (ao
-- coletar madeira), lendo o pet equipado do perfil.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game.ReplicatedStorage.Shared
local Pets = require(Shared.constants.Pets)
local Biomes = require(Shared.constants.Biomes)
local Remotes = require(Shared.remotes)
local PetFactory = require(script.Parent.PetFactory)
local DataService = require(script.Parent.Parent.data.DataService)
local StateService = require(script.Parent.Parent.data.StateService)

local PetSystem = {}

local equipped: { [Player]: Model } = {}
local petsFolder: Folder

-- Offset do pet relativo ao HumanoidRootPart (direita, cima, trás).
local HOVER = Vector3.new(3, 3.5, 2)

local function unequip(player: Player)
	local model = equipped[player]
	if model then
		model:Destroy()
		equipped[player] = nil
	end
end

local function spawnModel(player: Player, petId: string)
	local config = Pets.Configs[petId]
	if not config then
		return
	end
	local model = PetFactory.build(config)
	model.Parent = petsFolder
	equipped[player] = model
end

function PetSystem.Equip(player: Player, petId: string)
	local data = DataService.Get(player)
	if not data then
		return
	end
	if not table.find(data.inventory.pets, petId) then
		Remotes.CraftFeedback:FireClient(player, "petnotowned", petId)
		return
	end
	unequip(player)
	DataService.Update(player, function(d)
		d.equipped.pet = petId
	end)
	spawnModel(player, petId)
	StateService.push(player)
end

function PetSystem.Unequip(player: Player)
	unequip(player)
	DataService.Update(player, function(d)
		d.equipped.pet = ""
	end)
	StateService.push(player)
end

-- Rola o drop de pet ao derrubar uma árvore (chamado pelo TreeSystem).
function PetSystem.RollDrop(player: Player, treeConfig: any)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local biome = Biomes.Configs[treeConfig.biomeWhitelist[1]]
	local chance = (biome and biome.petDropChance or 0.02) * treeConfig.dropPetChance
	if math.random() > chance then
		return
	end

	-- escolhe um pet ponderado pela dropChance (mais raro = menos provável)
	local total = 0
	for _, id in Pets.Order do
		total += Pets.Configs[id].dropChance
	end
	local r = math.random() * total
	local chosen = Pets.Order[1]
	for _, id in Pets.Order do
		r -= Pets.Configs[id].dropChance
		if r <= 0 then
			chosen = id
			break
		end
	end

	if not table.find(data.inventory.pets, chosen) then
		DataService.Update(player, function(d)
			table.insert(d.inventory.pets, chosen)
		end)
		StateService.push(player)
	end
	Remotes.PetDropped:FireClient(player, chosen)
end

function PetSystem.Init()
	petsFolder = Instance.new("Folder")
	petsFolder.Name = "Pets"
	petsFolder.Parent = workspace

	-- flutua + gira cada pet perto do dono (segue respawns automaticamente)
	RunService.Heartbeat:Connect(function()
		local t = os.clock()
		for player, model in equipped do
			local character = player.Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp and model.PrimaryPart then
				local float = math.sin(t * 2 + player.UserId % 10) * 0.5
				local pos = (hrp.CFrame * CFrame.new(HOVER.X, HOVER.Y + float, HOVER.Z)).Position
				model:PivotTo(CFrame.new(pos) * CFrame.Angles(0, t * 2, 0))
			end
		end
	end)

	Remotes.PetEquipRequest.OnServerEvent:Connect(function(player, petId)
		if type(petId) == "string" then
			PetSystem.Equip(player, petId)
		end
	end)
	Remotes.PetUnequipRequest.OnServerEvent:Connect(function(player)
		PetSystem.Unequip(player)
	end)

	local function restore(player: Player)
		for _ = 1, 60 do
			if DataService.Get(player) then
				break
			end
			task.wait(0.1)
		end
		local data = DataService.Get(player)
		if data and not equipped[player] and data.equipped.pet ~= "" then
			spawnModel(player, data.equipped.pet)
		end
	end
	for _, player in Players:GetPlayers() do
		task.spawn(restore, player)
	end
	Players.PlayerAdded:Connect(function(player)
		task.spawn(restore, player)
	end)
	Players.PlayerRemoving:Connect(unequip)
end

return PetSystem
