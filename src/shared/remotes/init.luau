--!strict
-- Remotes compartilhados. O servidor cria os objetos como filhos deste módulo
-- (replicados via ReplicatedStorage); o cliente apenas espera por eles.
-- Mantém um ponto único de definição e evita RemoteEvents soltos pela árvore.

local RunService = game:GetService("RunService")

local EVENTS = {
	"ChopRequest", -- client -> server: jogador pediu para cortar
	"ChopFeedback", -- server -> client: resultado do golpe (acerto, tier insuficiente, derrubou)
	"CraftRequest", -- client -> server: craftar um machado (axeId)
	"EquipRequest", -- client -> server: equipar um machado (axeId)
	"CraftFeedback", -- server -> client: resultado do craft/equip
	"StateUpdate", -- server -> client: snapshot (wood, level, materiais, machados, pets, equipados)
	"RequestState", -- client -> server: pedir um StateUpdate (ao abrir o menu)
	"PetEquipRequest", -- client -> server: equipar um pet (petId)
	"PetUnequipRequest", -- client -> server: desequipar o pet
	"PetDropped", -- server -> client: um pet dropou (petId) para toast
}

local container = script

if RunService:IsServer() then
	for _, name in EVENTS do
		if not container:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = container
		end
	end
end

local Remotes = {}
for _, name in EVENTS do
	Remotes[name] = container:WaitForChild(name) :: RemoteEvent
end

return Remotes
