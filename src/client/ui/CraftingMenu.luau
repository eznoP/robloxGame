--!strict
--!optimize 2
-- Menu de crafting de machados (Fusion). Reativo: um snapshot do servidor
-- (StateUpdate) alimenta `state`, e cada linha recalcula seu rótulo e botão.
-- Abre pela mesa de craft (ProximityPrompt) ou pela tecla C. O servidor valida
-- tudo; os botões só enviam CraftRequest/EquipRequest.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Axes = require(ReplicatedStorage.Shared.constants.Axes)
local Remotes = require(ReplicatedStorage.Shared.remotes)

local New = Fusion.New
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local Value = Fusion.Value
local Computed = Fusion.Computed

local COLORS = {
	backdrop = Color3.fromRGB(16, 18, 26),
	panel = Color3.fromRGB(32, 36, 50),
	panelLight = Color3.fromRGB(44, 50, 68),
	ink = Color3.fromRGB(12, 14, 20),
	text = Color3.fromRGB(236, 240, 248),
	textDim = Color3.fromRGB(168, 176, 196),
	gold = Color3.fromRGB(240, 196, 80),
	blue = Color3.fromRGB(86, 150, 236),
	green = Color3.fromRGB(96, 196, 112),
	red = Color3.fromRGB(226, 92, 86),
	locked = Color3.fromRGB(90, 96, 112),
}

type State = {
	wood: number,
	level: number,
	materials: { [string]: number },
	ownedAxes: { string },
	equippedAxe: string,
}

local CraftingMenu = {}

local isOpen = Value(false)
local state = Value({
	wood = 0,
	level = 1,
	materials = {},
	ownedAxes = {},
	equippedAxe = "Machado_Graveto",
} :: State)

local MATERIAL_NAMES = {
	wood_log = "madeira",
	stone = "pedra",
	iron = "ferro",
	gold = "ouro",
	diamond = "diamante",
	essence = "essência",
}

local function formatCost(cost: { [string]: number }): string
	local parts = {}
	for key, amount in cost do
		table.insert(parts, amount .. " " .. (MATERIAL_NAMES[key] or key))
	end
	if #parts == 0 then
		return "grátis"
	end
	return table.concat(parts, " + ")
end

local function owns(s: State, axeId: string): boolean
	return table.find(s.ownedAxes, axeId) ~= nil
end

local function canAfford(s: State, cost: { [string]: number }): boolean
	for key, amount in cost do
		local have = key == "wood_log" and s.wood or (s.materials[key] or 0)
		if have < amount then
			return false
		end
	end
	return true
end

-- Uma linha por machado. Rótulo e botão derivam reativamente de `state`.
local function axeRow(axeId: string, order: number): Instance
	local config = Axes.Configs[axeId]

	local status = Computed(function(): string
		local s = state:get()
		if s.equippedAxe == axeId then
			return "equipped"
		elseif owns(s, axeId) then
			return "owned"
		elseif s.level < config.requiredLevel then
			return "locked"
		elseif canAfford(s, config.craftCost) then
			return "craftable"
		end
		return "poor"
	end)

	local buttonText = Computed(function(): string
		local st = status:get()
		if st == "equipped" then
			return "Equipado"
		elseif st == "owned" then
			return "Equipar"
		elseif st == "locked" then
			return "Nível " .. config.requiredLevel
		elseif st == "craftable" then
			return "Craftar"
		end
		return formatCost(config.craftCost)
	end)

	local buttonColor = Computed(function(): Color3
		local st = status:get()
		if st == "equipped" then
			return COLORS.green
		elseif st == "owned" then
			return COLORS.blue
		elseif st == "locked" then
			return COLORS.locked
		elseif st == "craftable" then
			return COLORS.gold
		end
		return COLORS.red
	end)

	return New("Frame")({
		Name = axeId,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundColor3 = COLORS.panelLight,
		[Children] = {
			New("UICorner")({ CornerRadius = UDim.new(0, 10) }),
			New("UIPadding")({
				PaddingLeft = UDim.new(0, 14),
				PaddingRight = UDim.new(0, 10),
			}),
			New("TextLabel")({
				Name = "Title",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, 6),
				Size = UDim2.new(1, -140, 0, 24),
				Font = Enum.Font.GothamBold,
				TextSize = 17,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = COLORS.text,
				Text = config.displayName,
			}),
			New("TextLabel")({
				Name = "Sub",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, 30),
				Size = UDim2.new(1, -140, 0, 18),
				Font = Enum.Font.Gotham,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = COLORS.textDim,
				Text = ("Tier %d · dano %d · %s"):format(
					config.visualTier,
					config.damage,
					formatCost(config.craftCost)
				),
			}),
			New("TextButton")({
				Name = "Action",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.new(0, 120, 0, 38),
				BackgroundColor3 = buttonColor,
				AutoButtonColor = true,
				Font = Enum.Font.GothamBold,
				TextSize = 15,
				TextColor3 = COLORS.ink,
				Text = buttonText,
				[Children] = {
					New("UICorner")({ CornerRadius = UDim.new(0, 8) }),
				},
				[OnEvent("Activated")] = function()
					local st = status:get()
					if st == "owned" then
						Remotes.EquipRequest:FireServer(axeId)
					elseif st == "craftable" then
						Remotes.CraftRequest:FireServer(axeId)
					end
				end,
			}),
		},
	})
end

local function build(): ScreenGui
	local rows = {}
	for i, axeId in Axes.Order do
		table.insert(rows, axeRow(axeId, i))
	end

	local header = Computed(function(): string
		local s = state:get()
		return ("Madeira: %d      Nível: %d"):format(s.wood, s.level)
	end)

	return New("ScreenGui")({
		Name = "CraftingMenu",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 10,
		Enabled = isOpen,
		[Children] = {
			New("Frame")({
				Name = "Panel",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0, 460, 0, 500),
				BackgroundColor3 = COLORS.panel,
				[Children] = {
					New("UICorner")({ CornerRadius = UDim.new(0, 18) }),
					New("UIStroke")({ Color = COLORS.ink, Thickness = 3 }),
					New("UIPadding")({
						PaddingTop = UDim.new(0, 16),
						PaddingBottom = UDim.new(0, 16),
						PaddingLeft = UDim.new(0, 16),
						PaddingRight = UDim.new(0, 16),
					}),
					New("TextLabel")({
						Name = "Title",
						BackgroundTransparency = 1,
						Size = UDim2.new(1, -40, 0, 30),
						Font = Enum.Font.GothamBold,
						TextSize = 22,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextColor3 = COLORS.text,
						Text = "Mesa de Craft",
					}),
					New("TextLabel")({
						Name = "Resources",
						BackgroundTransparency = 1,
						Position = UDim2.new(0, 0, 0, 34),
						Size = UDim2.new(1, 0, 0, 22),
						Font = Enum.Font.GothamMedium,
						TextSize = 15,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextColor3 = COLORS.gold,
						Text = header,
					}),
					New("TextButton")({
						Name = "Close",
						AnchorPoint = Vector2.new(1, 0),
						Position = UDim2.new(1, 0, 0, 0),
						Size = UDim2.new(0, 32, 0, 32),
						BackgroundColor3 = COLORS.red,
						Font = Enum.Font.GothamBold,
						TextSize = 18,
						TextColor3 = COLORS.ink,
						Text = "X",
						[Children] = { New("UICorner")({ CornerRadius = UDim.new(0, 8) }) },
						[OnEvent("Activated")] = function()
							isOpen:set(false)
						end,
					}),
					New("ScrollingFrame")({
						Name = "List",
						Position = UDim2.new(0, 0, 0, 66),
						Size = UDim2.new(1, 0, 1, -66),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						ScrollBarThickness = 6,
						CanvasSize = UDim2.new(0, 0, 0, 0),
						AutomaticCanvasSize = Enum.AutomaticSize.Y,
						[Children] = {
							New("UIListLayout")({
								Padding = UDim.new(0, 8),
								SortOrder = Enum.SortOrder.LayoutOrder,
							}),
							table.unpack(rows),
						},
					}),
				},
			}),
		},
	})
end

function CraftingMenu.Init()
	local player = Players.LocalPlayer
	local gui = build()
	gui.Parent = player:WaitForChild("PlayerGui")

	Remotes.StateUpdate.OnClientEvent:Connect(function(snapshot)
		state:set(snapshot)
	end)

	local function open()
		isOpen:set(true)
		Remotes.RequestState:FireServer()
	end

	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		if prompt.Name == "CraftPrompt" then
			open()
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.KeyCode == Enum.KeyCode.C then
			if isOpen:get() then
				isOpen:set(false)
			else
				open()
			end
		end
	end)
end

return CraftingMenu
