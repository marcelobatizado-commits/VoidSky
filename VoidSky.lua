-- ============================================================
-- VOID ULTRA V18 CLEAN
-- Multi-select + maioria void/ceu
-- GUI maior, clean, caixa OFF, so Anti-Void
-- Martelo desequipa/equipa a cada 3s
-- Void -725M | Ceu +725M | made by fickus
-- ============================================================

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local TOOL_NAME = "SledgeHammer"
local POS_VOID = CFrame.new(0, -725000000, 0)
local POS_SKY = CFrame.new(0, 725000000, 0)
local HEIGHT_TRIGGER = 30
local POS_BEFORE = nil

local selected = {} -- [UserId] = Player
local running = false
local killAuraOn = false
local currentMode = "void" -- void | sky

-- ---------- BASE (martelo grab + hold interno) ----------
local ok, err = pcall(function()
	local src = game:HttpGet("https://raw.githubusercontent.com/marcelobatizado-commits/VoidSky/3e8d8b67a814686c69551f2f30d0dc2c722a06b4/VoidSky.lua")
	src = string.gsub(src, "%-1500000", "-725000000")
	src = string.gsub(src, "16000000", "725000000")
	src = string.gsub(src, "HEIGHT_TRIGGER = 100", "HEIGHT_TRIGGER = 30")
	src = string.gsub(src, "v12 SUPER", "V18")
	src = string.gsub(src, "%[VOID v12%]", "[VOID V18]")
	local fn, cErr = loadstring(src)
	if not fn then error("Compile: " .. tostring(cErr)) end
	fn()
end)
if not ok then
	warn("[V18] ERRO base: " .. tostring(err))
	print("[V18] ERRO base: " .. tostring(err))
end
print("[V18] base OK")

-- ---------- helpers ----------
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

-- martelo: desequipa e equipa bem rapido a cada 3s
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

local function attackTarget(target)
	if not target or not target.Character then return end
	local tChar = target.Character
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

-- kill aura em TODOS os selecionados (round-robin)
local rrIndex = 1
RunService.Heartbeat:Connect(function()
	if not killAuraOn or not running then return end
	local list = {}
	for _, plr in pairs(selected) do
		if plr and plr.Parent then table.insert(list, plr) end
	end
	if #list == 0 then return end
	rrIndex = (rrIndex % #list) + 1
	attackTarget(list[rrIndex])
end)

-- maioria: quantos com Y >= 30
local function majorityWantsSky()
	local sky, ground = 0, 0
	for _, plr in pairs(selected) do
		if plr and plr.Character then
			local r = plr.Character:FindFirstChild("HumanoidRootPart")
			if r then
				if r.Position.Y >= HEIGHT_TRIGGER then sky += 1 else ground += 1 end
			end
		end
	end
	if sky + ground == 0 then return false end
	return sky >= ground
end

-- forca void/ceu pela maioria (overlay no hold da base)
RunService.Heartbeat:Connect(function()
	if not running then return end
	local wantSky = majorityWantsSky()
	local target = wantSky and POS_SKY or POS_VOID
	currentMode = wantSky and "sky" or "void"
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

-- anti-void only (sem god mode extra)
local function harden(char)
	if not char then return end
	pcall(function() workspace.FallenPartsDestroyHeight = 0/0 end)
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
	if root and (root.Position.Y > 100000 or root.Position.Y < -1000) then
		pcall(function()
			local p = Vector3.new(0, root.Position.Y, 0)
			local up = CFrame.new(p)
			char:PivotTo(up)
			root.CFrame = up
			root.AssemblyAngularVelocity = Vector3.zero
			for _, p2 in ipairs(char:GetDescendants()) do
				if p2:IsA("BasePart") then p2.LocalTransparencyModifier = 0 p2.CanCollide = false end
			end
		end)
	end
end
RunService.Heartbeat:Connect(function() harden(player.Character) end)
RunService.RenderStepped:Connect(function() harden(player.Character) end)

-- ---------- STATUS (so no iniciar) ----------
local statusGui
local function destroyStatus()
	if statusGui then pcall(function() statusGui:Destroy() end) end
	statusGui = nil
end

local function showStatus()
	destroyStatus()
	local pg = player:WaitForChild("PlayerGui")
	local sg = Instance.new("ScreenGui")
	sg.Name = "VoidSkyStatus"
	sg.ResetOnSpawn = false
	sg.Parent = pg
	statusGui = sg

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(200, 100)
	frame.Position = UDim2.new(1, -14, 0, 14)
	frame.AnchorPoint = Vector2.new(1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
	frame.BorderSizePixel = 0
	frame.ClipsDescendants = true
	frame.Parent = sg
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
	Instance.new("UIStroke", frame).Color = Color3.fromRGB(140, 130, 255)

	local modeLbl = Instance.new("TextLabel")
	modeLbl.Size = UDim2.new(1, -36, 0, 24)
	modeLbl.Position = UDim2.fromOffset(8, 4)
	modeLbl.BackgroundTransparency = 1
	modeLbl.Font = Enum.Font.GothamBold
	modeLbl.TextSize = 14
	modeLbl.TextXAlignment = Enum.TextXAlignment.Left
	modeLbl.Text = "--"
	modeLbl.Parent = frame

	local xbtn = Instance.new("TextButton")
	xbtn.Size = UDim2.fromOffset(24, 24)
	xbtn.Position = UDim2.new(1, -28, 0, 4)
	xbtn.BackgroundColor3 = Color3.fromRGB(210, 50, 60)
	xbtn.Text = "X"
	xbtn.Font = Enum.Font.GothamBold
	xbtn.TextSize = 12
	xbtn.TextColor3 = Color3.new(1,1,1)
	xbtn.BorderSizePixel = 0
	xbtn.Parent = frame
	Instance.new("UICorner", xbtn).CornerRadius = UDim.new(0, 6)
	xbtn.MouseButton1Click:Connect(destroyStatus)

	local info = Instance.new("TextLabel")
	info.Size = UDim2.new(1, -12, 0, 60)
	info.Position = UDim2.fromOffset(8, 30)
	info.BackgroundTransparency = 1
	info.Font = Enum.Font.Gotham
	info.TextSize = 11
	info.TextColor3 = Color3.fromRGB(200, 205, 230)
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.TextYAlignment = Enum.TextYAlignment.Top
	info.TextWrapped = true
	info.Parent = frame

	RunService.Heartbeat:Connect(function()
		if not statusGui or not statusGui.Parent then return end
		local n = 0
		for _ in pairs(selected) do n += 1 end
		if currentMode == "sky" then
			modeLbl.Text = "⬆ CEU"
			modeLbl.TextColor3 = Color3.fromRGB(80, 200, 255)
		else
			modeLbl.Text = "⬇ VOID"
			modeLbl.TextColor3 = Color3.fromRGB(160, 120, 255)
		end
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local y = root and math.floor(root.Position.Y) or 0
		info.Text = string.format("Alvos: %d\nY: %s\nKill: %s", n, tostring(y), killAuraOn and "ON" or "OFF")
	end)
end

-- ---------- CLEAN GUI + MULTI SELECT ----------
task.spawn(function()
	local pg = player:WaitForChild("PlayerGui")
	local gui = pg:WaitForChild("VoidSkyUltra", 20)
	if not gui then return end
	local main = gui:FindFirstChildOfClass("Frame")
	if not main then return end

	-- tamanho fixo maior + clip (texto nao vaza)
	pcall(function()
		main.Size = UDim2.fromOffset(340, 480)
		main.ClipsDescendants = true
		main.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
		local c = main:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", main)
		c.CornerRadius = UDim.new(0, 14)
		local s = main:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", main)
		s.Color = Color3.fromRGB(140, 130, 255)
		s.Thickness = 1.4
	end)

	-- esconde GOD MODE e deixa so anti void; caixa OFF
	local function cleanButtons()
		for _, d in ipairs(gui:GetDescendants()) do
			if d:IsA("TextButton") or d:IsA("TextLabel") or d:IsA("TextBox") then
				pcall(function()
					d.TextTruncate = Enum.TextTruncate.AtEnd
				end)
			end
			if d:IsA("TextButton") then
				local up = string.upper(d.Text or "")
				if up:find("GOD") then
					d.Visible = false
				end
				-- nao liga caixa no iniciar
			end
			if d:IsA("TextBox") and (d.Name == "UnflyBox" or (d.PlaceholderText or ""):find("unfly")) then
				-- deixa a secao de caixa escondida / desativada
				d.Visible = false
			end
		end
		for _, n in ipairs({"UnflyLabel", "UnflyBox", "UnflyStatus", "UnflyToggle"}) do
			local o = gui:FindFirstChild(n, true)
			if o then o.Visible = false end
		end
	end
	cleanButtons()
	task.delay(0.5, cleanButtons)
	task.delay(1.5, cleanButtons)

	-- painel multi-select limpo
	if main:FindFirstChild("V18Multi") then main.V18Multi:Destroy() end
	local panel = Instance.new("Frame")
	panel.Name = "V18Multi"
	panel.Size = UDim2.new(1, -24, 0, 200)
	panel.Position = UDim2.fromOffset(12, 250)
	panel.BackgroundColor3 = Color3.fromRGB(22, 22, 34)
	panel.BorderSizePixel = 0
	panel.ClipsDescendants = true
	panel.ZIndex = 8
	panel.Parent = main
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -12, 0, 22)
	title.Position = UDim2.fromOffset(8, 4)
	title.BackgroundTransparency = 1
	title.Text = "Alvos (toque p/ marcar)"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 12
	title.TextColor3 = Color3.fromRGB(200, 200, 230)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 9
	title.Parent = panel

	local countLbl = Instance.new("TextLabel")
	countLbl.Size = UDim2.new(1, -12, 0, 16)
	countLbl.Position = UDim2.fromOffset(8, 24)
	countLbl.BackgroundTransparency = 1
	countLbl.Text = "Selecionados: 0"
	countLbl.Font = Enum.Font.Gotham
	countLbl.TextSize = 11
	countLbl.TextColor3 = Color3.fromRGB(140, 200, 160)
	countLbl.TextXAlignment = Enum.TextXAlignment.Left
	countLbl.ZIndex = 9
	countLbl.Parent = panel

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -12, 0, 120)
	scroll.Position = UDim2.fromOffset(6, 44)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4
	scroll.ZIndex = 9
	scroll.Parent = panel
	local layout = Instance.new("UIListLayout", scroll)
	layout.Padding = UDim.new(0, 4)

	local function refreshCount()
		local n = 0
		for _ in pairs(selected) do n += 1 end
		countLbl.Text = "Selecionados: " .. n
	end

	local function togglePlayer(plr, btn)
		if selected[plr.UserId] then
			selected[plr.UserId] = nil
			btn.BackgroundColor3 = Color3.fromRGB(32, 32, 48)
		else
			selected[plr.UserId] = plr
			btn.BackgroundColor3 = Color3.fromRGB(40, 120, 80)
		end
		refreshCount()
	end

	local function rebuildList()
		for _, c in ipairs(scroll:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		local y = 0
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player then
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1, -4, 0, 28)
				btn.BackgroundColor3 = selected[plr.UserId] and Color3.fromRGB(40, 120, 80) or Color3.fromRGB(32, 32, 48)
				btn.Text = plr.Name
				btn.Font = Enum.Font.Gotham
				btn.TextSize = 13
				btn.TextColor3 = Color3.new(1,1,1)
				btn.BorderSizePixel = 0
				btn.AutoButtonColor = false
				btn.ZIndex = 10
				btn.Parent = scroll
				Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
				btn.MouseButton1Click:Connect(function() togglePlayer(plr, btn) end)
				y += 32
			end
		end
		scroll.CanvasSize = UDim2.new(0, 0, 0, math.max(y, 40))
		refreshCount()
	end
	rebuildList()
	Players.PlayerAdded:Connect(function() task.defer(rebuildList) end)
	Players.PlayerRemoving:Connect(function(plr)
		selected[plr.UserId] = nil
		task.defer(rebuildList)
	end)

	-- Selecionar todos
	local allBtn = Instance.new("TextButton")
	allBtn.Size = UDim2.new(0.48, -4, 0, 28)
	allBtn.Position = UDim2.new(0, 6, 1, -34)
	allBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 180)
	allBtn.Text = "Selecionar todos"
	allBtn.Font = Enum.Font.GothamBold
	allBtn.TextSize = 12
	allBtn.TextColor3 = Color3.new(1,1,1)
	allBtn.BorderSizePixel = 0
	allBtn.ZIndex = 10
	allBtn.Parent = panel
	Instance.new("UICorner", allBtn).CornerRadius = UDim.new(0, 8)
	allBtn.MouseButton1Click:Connect(function()
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player then selected[plr.UserId] = plr end
		end
		rebuildList()
	end)

	local clearBtn = Instance.new("TextButton")
	clearBtn.Size = UDim2.new(0.48, -4, 0, 28)
	clearBtn.Position = UDim2.new(0.52, 0, 1, -34)
	clearBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 60)
	clearBtn.Text = "Limpar"
	clearBtn.Font = Enum.Font.GothamBold
	clearBtn.TextSize = 12
	clearBtn.TextColor3 = Color3.new(1,1,1)
	clearBtn.BorderSizePixel = 0
	clearBtn.ZIndex = 10
	clearBtn.Parent = panel
	Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 8)
	clearBtn.MouseButton1Click:Connect(function()
		selected = {}
		rebuildList()
	end)

	-- credit
	if not main:FindFirstChild("FickusCredit") then
		local cr = Instance.new("TextLabel")
		cr.Name = "FickusCredit"
		cr.Size = UDim2.new(1, -16, 0, 14)
		cr.Position = UDim2.new(0, 8, 1, -16)
		cr.BackgroundTransparency = 1
		cr.Text = "made by fickus"
		cr.Font = Enum.Font.Gotham
		cr.TextSize = 10
		cr.TextColor3 = Color3.fromRGB(120, 120, 150)
		cr.TextXAlignment = Enum.TextXAlignment.Center
		cr.ZIndex = 10
		cr.Parent = main
	end

	-- hooks INICIAR / PARAR (caixa continua OFF)
	local function hook()
		for _, d in ipairs(gui:GetDescendants()) do
			if d:IsA("TextButton") then
				local up = string.upper(d.Text or "")
				if (up == "INICIAR" or up == "START" or up == "CONFIRMAR") and not up:find("CAIXA") and not d:GetAttribute("V18Start") then
					d:SetAttribute("V18Start", true)
					d.MouseButton1Click:Connect(function()
						local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
						if root then POS_BEFORE = root.CFrame end
						running = true
						killAuraOn = true
						-- caixa continua DESLIGADA
						cleanButtons()
						showStatus()
					end)
				end
				if (up == "PARAR" or up == "STOP") and not up:find("CAIXA") and not d:GetAttribute("V18Stop") then
					d:SetAttribute("V18Stop", true)
					d.MouseButton1Click:Connect(function()
						running = false
						killAuraOn = false
						destroyStatus()
					end)
				end
			end
		end
	end
	hook()
	gui.DescendantAdded:Connect(function() task.defer(function() cleanButtons() hook() end) end)
end)

print("[V18 CLEAN] multi-select | maioria | caixa OFF | martelo 3s | made by fickus")
