-- ============================================================
-- VOID ULTRA V19 — GUI LIMPA (do zero)
-- Anti-Void ON | Comecar → lista → selecionar → Ir
-- Multi-select + maioria void/ceu | martelo 3s
-- Void -725M | Ceu +725M | made by fickus
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local TOOL_NAME = "SledgeHammer"
local POS_VOID = CFrame.new(0, -725000000, 0)
local POS_SKY = CFrame.new(0, 725000000, 0)
local HEIGHT_TRIGGER = 30

local selected = {} -- UserId -> Player
local running = false
local antiVoidOn = true
local currentMode = "void"
local POS_BEFORE = nil

-- limpa GUI antiga do void
pcall(function()
	local pg = player:FindFirstChild("PlayerGui")
	if pg then
		for _, n in ipairs({"VoidSkyUltra", "VoidSkyStatus", "VoidUltraV19"}) do
			local o = pg:FindFirstChild(n)
			if o then o:Destroy() end
		end
	end
end)

-- tenta carregar so a logica de martelo da base em silencio (sem usar a GUI velha)
task.spawn(function()
	task.wait(0.3)
	pcall(function()
		local pg = player:FindFirstChild("PlayerGui")
		if not pg then return end
		local old = pg:FindFirstChild("VoidSkyUltra")
		if old then old:Destroy() end
	end)
end)

-- ---------- martelo ----------
local function getHammer()
	local char, bp = player.Character, player:FindFirstChild("Backpack")
	return (char and char:FindFirstChild(TOOL_NAME)) or (bp and bp:FindFirstChild(TOOL_NAME))
end

local function equipHammer()
	local t = getHammer()
	if not t then return nil end
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum and t.Parent ~= player.Character then pcall(function() hum:EquipTool(t) end) end
	return t
end

local function unequipHammer()
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then pcall(function() hum:UnequipTools() end) end
end

task.spawn(function()
	while true do
		task.wait(3)
		if running and getHammer() then
			unequipHammer()
			task.wait(0.05)
			equipHammer()
		end
	end
end)

local function attackTarget(plr)
	if not plr or not plr.Character then return end
	local tChar = plr.Character
	local tRoot = tChar:FindFirstChild("HumanoidRootPart")
	local tHum = tChar:FindFirstChildOfClass("Humanoid")
	if not tRoot or not tHum or tHum.Health <= 0 then return end
	local tool = equipHammer()
	if not tool then return end
	local handle = tool:FindFirstChild("Handle")
	for _ = 1, 4 do pcall(function() tool:Activate() end) end
	if handle and firetouchinterest then
		for _, part in ipairs(tChar:GetChildren()) do
			if part:IsA("BasePart") then
				pcall(function()
					firetouchinterest(handle, part, 0)
					firetouchinterest(handle, part, 1)
				end)
			end
		end
	end
end

local rr = 1
RunService.Heartbeat:Connect(function()
	if not running then return end
	local list = {}
	for _, p in pairs(selected) do
		if p and p.Parent then table.insert(list, p) end
	end
	if #list == 0 then return end
	rr = (rr % #list) + 1
	attackTarget(list[rr])
end)

local function majoritySky()
	local sky, ground = 0, 0
	for _, p in pairs(selected) do
		if p and p.Character then
			local r = p.Character:FindFirstChild("HumanoidRootPart")
			if r then
				if r.Position.Y >= HEIGHT_TRIGGER then sky += 1 else ground += 1 end
			end
		end
	end
	if sky + ground == 0 then return false end
	return sky >= ground
end

RunService.Heartbeat:Connect(function()
	if not running then return end
	local wantSky = majoritySky()
	currentMode = wantSky and "sky" or "void"
	local target = wantSky and POS_SKY or POS_VOID
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	pcall(function()
		char:PivotTo(target)
		root.CFrame = target
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end)
end)

-- anti void
RunService.Heartbeat:Connect(function()
	if not antiVoidOn then return end
	pcall(function() workspace.FallenPartsDestroyHeight = 0/0 end)
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if hum then
		pcall(function()
			hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
			hum.BreakJointsOnDeath = false
		end)
	end
	if root and (root.Position.Y > 50000 or root.Position.Y < -500) then
		pcall(function()
			local up = CFrame.new(0, root.Position.Y, 0)
			char:PivotTo(up)
			root.CFrame = up
			root.AssemblyAngularVelocity = Vector3.zero
			for _, p in ipairs(char:GetDescendants()) do
				if p:IsA("BasePart") then p.LocalTransparencyModifier = 0 p.CanCollide = false end
			end
		end)
	end
end)

-- ============================================================
-- GUI LIMPA
-- ============================================================
local pg = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "VoidUltraV19"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = pg

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(300, 160)
main.Position = UDim2.new(0.5, -150, 0.2, 0)
main.BackgroundColor3 = Color3.fromRGB(16, 16, 26)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.ClipsDescendants = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)
local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(130, 120, 255)
stroke.Thickness = 1.4

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 0, 32)
title.Position = UDim2.fromOffset(12, 4)
title.BackgroundTransparency = 1
title.Text = "VOID ULTRA V19"
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(230, 230, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local closeMain = Instance.new("TextButton")
closeMain.Size = UDim2.fromOffset(28, 28)
closeMain.Position = UDim2.new(1, -34, 0, 6)
closeMain.BackgroundColor3 = Color3.fromRGB(210, 50, 60)
closeMain.Text = "X"
closeMain.Font = Enum.Font.GothamBold
closeMain.TextSize = 14
closeMain.TextColor3 = Color3.new(1,1,1)
closeMain.BorderSizePixel = 0
closeMain.Parent = main
Instance.new("UICorner", closeMain).CornerRadius = UDim.new(0, 8)
closeMain.MouseButton1Click:Connect(function()
	running = false
	gui:Destroy()
end)

-- Anti Void toggle (ON por padrao)
local antiBtn = Instance.new("TextButton")
antiBtn.Size = UDim2.new(1, -24, 0, 36)
antiBtn.Position = UDim2.fromOffset(12, 42)
antiBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 95)
antiBtn.Text = "ANTI VOID: ON"
antiBtn.Font = Enum.Font.GothamBold
antiBtn.TextSize = 14
antiBtn.TextColor3 = Color3.new(1,1,1)
antiBtn.BorderSizePixel = 0
antiBtn.Parent = main
Instance.new("UICorner", antiBtn).CornerRadius = UDim.new(0, 10)
antiBtn.MouseButton1Click:Connect(function()
	antiVoidOn = not antiVoidOn
	if antiVoidOn then
		antiBtn.Text = "ANTI VOID: ON"
		antiBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 95)
	else
		antiBtn.Text = "ANTI VOID: OFF"
		antiBtn.BackgroundColor3 = Color3.fromRGB(200, 55, 65)
	end
end)

-- Comecar
local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(1, -24, 0, 40)
startBtn.Position = UDim2.fromOffset(12, 88)
startBtn.BackgroundColor3 = Color3.fromRGB(70, 100, 220)
startBtn.Text = "COMEÇAR"
startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 15
startBtn.TextColor3 = Color3.new(1,1,1)
startBtn.BorderSizePixel = 0
startBtn.Parent = main
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 10)

local credit = Instance.new("TextLabel")
credit.Size = UDim2.new(1, -16, 0, 14)
credit.Position = UDim2.new(0, 8, 1, -18)
credit.BackgroundTransparency = 1
credit.Text = "made by fickus"
credit.Font = Enum.Font.Gotham
credit.TextSize = 10
credit.TextColor3 = Color3.fromRGB(110, 110, 140)
credit.Parent = main

-- ---------- TELA LISTA ----------
local listFrame = Instance.new("Frame")
listFrame.Size = UDim2.fromOffset(300, 360)
listFrame.Position = UDim2.new(0.5, -150, 0.15, 0)
listFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 26)
listFrame.BorderSizePixel = 0
listFrame.Visible = false
listFrame.Active = true
listFrame.Draggable = true
listFrame.ClipsDescendants = true
listFrame.Parent = gui
Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 14)
local ls = Instance.new("UIStroke", listFrame)
ls.Color = Color3.fromRGB(130, 120, 255)
ls.Thickness = 1.4

local listTitle = Instance.new("TextLabel")
listTitle.Size = UDim2.new(1, -16, 0, 28)
listTitle.Position = UDim2.fromOffset(12, 6)
listTitle.BackgroundTransparency = 1
listTitle.Text = "Selecionar alvos"
listTitle.Font = Enum.Font.GothamBold
listTitle.TextSize = 15
listTitle.TextColor3 = Color3.fromRGB(230, 230, 255)
listTitle.TextXAlignment = Enum.TextXAlignment.Left
listTitle.Parent = listFrame

local countLbl = Instance.new("TextLabel")
countLbl.Size = UDim2.new(1, -16, 0, 18)
countLbl.Position = UDim2.fromOffset(12, 32)
countLbl.BackgroundTransparency = 1
countLbl.Text = "Selecionados: 0"
countLbl.Font = Enum.Font.Gotham
countLbl.TextSize = 12
countLbl.TextColor3 = Color3.fromRGB(140, 200, 160)
countLbl.TextXAlignment = Enum.TextXAlignment.Left
countLbl.Parent = listFrame

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -24, 0, 220)
scroll.Position = UDim2.fromOffset(12, 54)
scroll.BackgroundColor3 = Color3.fromRGB(22, 22, 34)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ClipsDescendants = true
scroll.Parent = listFrame
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 8)
local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0, 5)
layout.SortOrder = Enum.SortOrder.Name
local pad = Instance.new("UIPadding", scroll)
pad.PaddingTop = UDim.new(0, 4)
pad.PaddingLeft = UDim.new(0, 4)
pad.PaddingRight = UDim.new(0, 4)

local function refreshCount()
	local n = 0
	for _ in pairs(selected) do n += 1 end
	countLbl.Text = "Selecionados: " .. n
end

local function rebuildList()
	for _, c in ipairs(scroll:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	local y = 0
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player then
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, -8, 0, 32)
			btn.BackgroundColor3 = selected[plr.UserId] and Color3.fromRGB(40, 140, 90) or Color3.fromRGB(30, 30, 46)
			btn.Text = "  " .. plr.Name
			btn.Font = Enum.Font.Gotham
			btn.TextSize = 14
			btn.TextColor3 = Color3.new(1,1,1)
			btn.TextXAlignment = Enum.TextXAlignment.Left
			btn.BorderSizePixel = 0
			btn.AutoButtonColor = false
			btn.Parent = scroll
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
			btn.MouseButton1Click:Connect(function()
				if selected[plr.UserId] then
					selected[plr.UserId] = nil
					btn.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
				else
					selected[plr.UserId] = plr
					btn.BackgroundColor3 = Color3.fromRGB(40, 140, 90)
				end
				refreshCount()
			end)
			y += 37
		end
	end
	scroll.CanvasSize = UDim2.new(0, 0, 0, math.max(y + 8, 50))
	refreshCount()
end

Players.PlayerAdded:Connect(function() task.defer(rebuildList) end)
Players.PlayerRemoving:Connect(function(plr)
	selected[plr.UserId] = nil
	task.defer(rebuildList)
end)

local allBtn = Instance.new("TextButton")
allBtn.Size = UDim2.new(0.48, -8, 0, 34)
allBtn.Position = UDim2.new(0, 12, 1, -86)
allBtn.BackgroundColor3 = Color3.fromRGB(50, 110, 190)
allBtn.Text = "Selecionar todos"
allBtn.Font = Enum.Font.GothamBold
allBtn.TextSize = 12
allBtn.TextColor3 = Color3.new(1,1,1)
allBtn.BorderSizePixel = 0
allBtn.Parent = listFrame
Instance.new("UICorner", allBtn).CornerRadius = UDim.new(0, 8)
allBtn.MouseButton1Click:Connect(function()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player then selected[plr.UserId] = plr end
	end
	rebuildList()
end)

local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.new(0.48, -8, 0, 34)
clearBtn.Position = UDim2.new(0.52, 0, 1, -86)
clearBtn.BackgroundColor3 = Color3.fromRGB(140, 55, 65)
clearBtn.Text = "Limpar"
clearBtn.Font = Enum.Font.GothamBold
clearBtn.TextSize = 12
clearBtn.TextColor3 = Color3.new(1,1,1)
clearBtn.BorderSizePixel = 0
clearBtn.Parent = listFrame
Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 8)
clearBtn.MouseButton1Click:Connect(function()
	selected = {}
	rebuildList()
end)

local goBtn = Instance.new("TextButton")
goBtn.Size = UDim2.new(1, -24, 0, 40)
goBtn.Position = UDim2.fromOffset(12, 1, -46)
goBtn.Position = UDim2.new(0, 12, 1, -46)
goBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 95)
goBtn.Text = "IR (VOID / CÉU)"
goBtn.Font = Enum.Font.GothamBold
goBtn.TextSize = 15
goBtn.TextColor3 = Color3.new(1,1,1)
goBtn.BorderSizePixel = 0
goBtn.Parent = listFrame
Instance.new("UICorner", goBtn).CornerRadius = UDim.new(0, 10)

local backBtn = Instance.new("TextButton")
backBtn.Size = UDim2.fromOffset(28, 28)
backBtn.Position = UDim2.new(1, -34, 0, 6)
backBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
backBtn.Text = "<"
backBtn.Font = Enum.Font.GothamBold
backBtn.TextSize = 16
backBtn.TextColor3 = Color3.new(1,1,1)
backBtn.BorderSizePixel = 0
backBtn.Parent = listFrame
Instance.new("UICorner", backBtn).CornerRadius = UDim.new(0, 8)
backBtn.MouseButton1Click:Connect(function()
	listFrame.Visible = false
	main.Visible = true
end)

-- status minimo enquanto roda
local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1, -24, 0, 20)
statusLbl.Position = UDim2.fromOffset(12, 132)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = ""
statusLbl.Font = Enum.Font.Gotham
statusLbl.TextSize = 11
statusLbl.TextColor3 = Color3.fromRGB(160, 160, 190)
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.Parent = main

startBtn.MouseButton1Click:Connect(function()
	if running then
		-- parar
		running = false
		startBtn.Text = "COMEÇAR"
		startBtn.BackgroundColor3 = Color3.fromRGB(70, 100, 220)
		statusLbl.Text = "Parado"
		return
	end
	main.Visible = false
	rebuildList()
	listFrame.Visible = true
end)

goBtn.MouseButton1Click:Connect(function()
	local n = 0
	for _ in pairs(selected) do n += 1 end
	if n == 0 then
		countLbl.Text = "Selecione pelo menos 1!"
		countLbl.TextColor3 = Color3.fromRGB(255, 120, 120)
		task.delay(1.2, refreshCount)
		return
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then POS_BEFORE = root.CFrame end
	running = true
	equipHammer()
	listFrame.Visible = false
	main.Visible = true
	startBtn.Text = "PARAR"
	startBtn.BackgroundColor3 = Color3.fromRGB(200, 55, 65)
	statusLbl.Text = "Rodando · alvos: " .. n
end)

print("[V19] GUI limpa | Anti-Void ON | Comecar → lista → Ir | made by fickus")
