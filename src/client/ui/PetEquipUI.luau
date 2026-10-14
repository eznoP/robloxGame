--!strict
--!optimize 2
-- Menu de pets (Fusion). Lista os pets do jogo; os possuídos podem ser equipados/
-- desequipados. Reativo via StateUpdate (ownedPets, equippedPet). Abre pela tecla P.
-- O servidor valida; os botões só pedem.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Pets = require(ReplicatedStorage.Shared.constants.Pets)
local Remotes = require(ReplicatedStorage.Shared.remotes)

local New = Fusion.New
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local Value = Fusion.Value
local Computed = Fusion.Computed

local COLORS = {
	panel = Color3.fromRGB(32, 36, 50),
	panelLight = Color3.fromRGB(44, 50, 68),
	ink = Color3.fromRGB(12, 14, 20),
	text = Color3.fromRGB(236, 240, 248),
	textDim = Color3.fromRGB(168, 176, 196),
	gold = Color3.fromRGB(240, 196, 80),
	blue = Color3.fromRGB(86, 150, 236),
	green = Color3.fromRGB(96, 196, 112),
	locked = Color3.fromRGB(90, 96, 112),
}

local RARITY_COLOR: { [string]: Color3 } = {
	Comum = Color3.fromRGB(176, 182, 196),
	Incomum = Color3.fromRGB(120, 200, 140),
	Raro = Color3.fromRGB(96, 156, 236),
	Epico = Color3.fromRGB(176, 118, 232),
	Lendario = Color3.fromRGB(240, 176, 80),
	Mitico = Color3.fromRGB(232, 96, 110),
	Divino = Color3.fromRGB(110, 224, 230),
}

type State = { ownedPets: { string }, equippedPet: string }

local PetEquipUI = {}

local isOpen = Value(false)
local state = Value({ ownedPets = {}, equippedPet = "" } :: State)

local function owns(s: State, petId: string): boolean
	return table.find(s.ownedPets, petId) ~= nil
end

local function petRow(petId: string, order: number): Instance
	local config = Pets.Configs[petId]

	local status = Computed(function(): string
		local s = state:get()
		if s.equippedPet == petId then
			return "equipped"
		elseif owns(s, petId) then
			return "owned"
		end
		return "locked"
	end)

	return New("Frame")({
		Name = petId,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 54),
		BackgroundColor3 = COLORS.panelLight,
		[Children] = {
			New("UICorner")({ CornerRadius = UDim.new(0, 10) }),
			New("UIPadding")({ PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 10) }),
			New("Frame")({
				Name = "Dot",
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.new(0, 14, 0, 14),
				BackgroundColor3 = RARITY_COLOR[config.rarity] or COLORS.textDim,
				[Children] = { New("UICorner")({ CornerRadius = UDim.new(1, 0) }) },
			}),
			New("TextLabel")({
				Name = "Title",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 24, 0, 6),
				Size = UDim2.new(1, -150, 0, 24),
				Font = Enum.Font.GothamBold,
				TextSize = 17,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = COLORS.text,
				Text = config.displayName,
			}),
			New("TextLabel")({
				Name = "Sub",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 24, 0, 29),
				Size = UDim2.new(1, -150, 0, 18),
				Font = Enum.Font.Gotham,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = COLORS.textDim,
				Text = ("%s · x%.2f madeira"):format(config.rarity, config.baseMultiplier),
			}),
			New("TextButton")({
				Name = "Action",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.new(0, 120, 0, 36),
				BackgroundColor3 = Computed(function(): Color3
					local st = status:get()
					return (st == "equipped" and COLORS.green)
						or (st == "owned" and COLORS.blue)
						or COLORS.locked
				end),
				Font = Enum.Font.GothamBold,
				TextSize = 15,
				TextColor3 = COLORS.ink,
				Text = Computed(function(): string
					local st = status:get()
					return (st == "equipped" and "Desequipar")
						or (st == "owned" and "Equipar")
						or "Não encontrado"
				end),
				[Children] = { New("UICorner")({ CornerRadius = UDim.new(0, 8) }) },
				[OnEvent("Activated")] = function()
					local st = status:get()
					if st == "equipped" then
						Remotes.PetUnequipRequest:FireServer()
					elseif st == "owned" then
						Remotes.PetEquipRequest:FireServer(petId)
					end
				end,
			}),
		},
	})
end

local function build(): ScreenGui
	local rows = {}
	for i, petId in Pets.Order do
		table.insert(rows, petRow(petId, i))
	end

	return New("ScreenGui")({
		Name = "PetEquipUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 10,
		Enabled = isOpen,
		[Children] = {
			New("Frame")({
				Name = "Panel",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0, 460, 0, 480),
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
						Text = "Pets",
					}),
					New("TextLabel")({
						Name = "Hint",
						BackgroundTransparency = 1,
						Position = UDim2.new(0, 0, 0, 34),
						Size = UDim2.new(1, 0, 0, 20),
						Font = Enum.Font.GothamMedium,
						TextSize = 14,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextColor3 = COLORS.gold,
						Text = "Derrube árvores para encontrar pets. Eles multiplicam a madeira.",
					}),
					New("TextButton")({
						Name = "Close",
						AnchorPoint = Vector2.new(1, 0),
						Position = UDim2.new(1, 0, 0, 0),
						Size = UDim2.new(0, 32, 0, 32),
						BackgroundColor3 = Color3.fromRGB(226, 92, 86),
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
						Position = UDim2.new(0, 0, 0, 62),
						Size = UDim2.new(1, 0, 1, -62),
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

function PetEquipUI.Init()
	local player = Players.LocalPlayer
	local gui = build()
	gui.Parent = player:WaitForChild("PlayerGui")

	Remotes.StateUpdate.OnClientEvent:Connect(function(snapshot)
		state:set({ ownedPets = snapshot.ownedPets or {}, equippedPet = snapshot.equippedPet or "" })
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.KeyCode == Enum.KeyCode.P then
			local nowOpen = not isOpen:get()
			isOpen:set(nowOpen)
			if nowOpen then
				Remotes.RequestState:FireServer()
			end
		end
	end)
end

return PetEquipUI
