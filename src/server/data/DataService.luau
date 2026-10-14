--!strict
--!optimize 2
-- Camada de dados (plano Fase 0, §4.5). Envolve o ProfileService (vendorizado) para
-- garantir session-locking, auto-save e zero perda de dados.
-- ProfileService não está no índice Wally (escopo loleris ausente), então o módulo
-- é vendorizado em server/vendor — ver errata.
--
-- Em Studio sem "Enable Studio Access to API Services", o ProfileService entra em
-- modo mock automaticamente, então o Play funciona sem DataStore real.

local Players = game:GetService("Players")

local ProfileService = require(script.Parent.Parent.vendor.ProfileService) :: any
local DataTemplate = require(script.Parent.DataTemplate)

export type PlayerData = DataTemplate.PlayerData

local DataService = {}

local PROFILE_STORE_KEY = "PlayerData_v1"
local KEY_PREFIX = "Player_"

local ProfileStore = ProfileService.GetProfileStore(PROFILE_STORE_KEY, DataTemplate)
local profiles: { [Player]: any } = {}

local function buildLeaderstats(player: Player, data: PlayerData)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"

	local wood = Instance.new("IntValue")
	wood.Name = "Wood"
	wood.Value = data.wood
	wood.Parent = stats

	local level = Instance.new("IntValue")
	level.Name = "Level"
	level.Value = data.level
	level.Parent = stats

	stats.Parent = player
end

local function onPlayerAdded(player: Player)
	local profile = ProfileStore:LoadProfileAsync(KEY_PREFIX .. player.UserId)
	if profile == nil then
		-- outra sessão segura o lock e não liberou; melhor pedir para religar
		player:Kick("Não foi possível carregar seus dados. Entre novamente.")
		return
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()
	profile:ListenToRelease(function()
		profiles[player] = nil
		player:Kick("Seus dados foram abertos em outro servidor.")
	end)

	if player:IsDescendantOf(Players) then
		profiles[player] = profile
		buildLeaderstats(player, profile.Data)
	else
		-- jogador saiu antes do perfil carregar
		profile:Release()
	end
end

-- Retorna os dados do jogador, ou nil se o perfil ainda não carregou/já saiu.
function DataService.Get(player: Player): PlayerData?
	local profile = profiles[player]
	return profile and profile.Data or nil
end

-- Executa `mutator` sobre os dados do jogador, se o perfil estiver ativo.
-- Centraliza a escrita para manter leaderstats e dados em sincronia.
function DataService.Update(player: Player, mutator: (PlayerData) -> ()): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end
	mutator(profile.Data)
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		local wood = stats:FindFirstChild("Wood") :: IntValue?
		local level = stats:FindFirstChild("Level") :: IntValue?
		if wood then
			wood.Value = profile.Data.wood
		end
		if level then
			level.Value = profile.Data.level
		end
	end
	return true
end

function DataService.Init()
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player)
		local profile = profiles[player]
		if profile then
			profile:Release()
		end
	end)
end

return DataService
