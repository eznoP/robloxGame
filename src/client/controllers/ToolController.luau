--!strict
--!optimize 2
-- Liga o machado equipado ao servidor: ao ativar (clique), pede o corte.
-- O servidor decide o que foi atingido; o cliente só envia o pedido.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("remotes"))

local ToolController = {}

local hooked: { [Tool]: true } = {}

local function hookTool(instance: Instance)
	if not instance:IsA("Tool") or instance.Name ~= "Axe" or hooked[instance] then
		return
	end
	hooked[instance] = true
	instance.Activated:Connect(function()
		Remotes.ChopRequest:FireServer()
	end)
end

local function watch(container: Instance)
	for _, child in container:GetChildren() do
		hookTool(child)
	end
	container.ChildAdded:Connect(hookTool)
end

function ToolController.Init()
	local player = Players.LocalPlayer

	watch(player:WaitForChild("Backpack"))
	if player.Character then
		watch(player.Character)
	end
	player.CharacterAdded:Connect(watch)

	Remotes.ChopFeedback.OnClientEvent:Connect(function(kind: string, detail: number?)
		if kind == "tier" then
			warn(
				("[Axe] Você precisa de um machado tier %d ou melhor para esta árvore."):format(
					detail or 0
				)
			)
		end
	end)
end

return ToolController
