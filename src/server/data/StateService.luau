--!strict
--!optimize 2
-- Monta e envia o snapshot do jogador para a UI (StateUpdate). Ponto único usado
-- por AxeSystem e PetSystem, para a UI sempre receber a mesma forma de estado.

local Remotes = require(game.ReplicatedStorage.Shared.remotes)
local DataService = require(script.Parent.DataService)

local StateService = {}

function StateService.push(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	Remotes.StateUpdate:FireClient(player, {
		wood = math.floor(data.wood),
		level = data.level,
		xp = data.xp,
		materials = data.inventory.materials,
		ownedAxes = data.inventory.axes,
		equippedAxe = data.equipped.axe,
		ownedPets = data.inventory.pets,
		equippedPet = data.equipped.pet,
	})
end

return StateService
