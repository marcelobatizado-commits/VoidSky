-- ============================================================
-- VOID ↔ CÉU + ANTI VOID PREMIUM  v9.0 ULTRA
-- Tudo junto: martelo, void/céu, anti-void NaN, god mode
-- ============================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer

if player.PlayerGui:FindFirstChild("VoidSkyUltra") then
	player.PlayerGui.VoidSkyUltra:Destroy()
end

-- ========== CONFIG ==========
local POS_VOID = CFrame.new(0, -100000, 0)
local POS_SKY  = CFrame.new(0, 10000000, 0)
local POS_SHOP = Vector3.new(-119.27, 18.30, 166.50)
local HEIGHT_TRIGGER = 100
local TOOL_NAME = "SledgeHammer"
local SWORD_NAME = "KatanaGroup"
local GRAB_TIMEOUT = 5

-- ========== STATE ==========
local running = false
local originalCF = nil
local currentHoldCF = nil
local targetPlayer = nil
local currentMode = nil
local countdownActive = false
local closing = false
local playerListOpen = false
local selectedPlayer = nil
local hammerReady = false
local recoveringHammer = false
local lastRecoverAttempt = 0
local antiVoidEnabled = true
local godModeEnabled = true

local protectConn, toolConn, trackConn, steppedConn, healthConn, recoverConn
local antiConn, godConn, antiStepped

-- ========== SOUNDS ==========
local function makeSound(id, vol)
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. tostring(id)
	s.Volume = vol or 0.5
	s.Parent = SoundService
	return s
end
local sClick = makeSound(6895079853, 0.45)
local sConfirm = makeSound(9117411612, 0.65)
local sCancel = makeSound(9117423534, 0.5)
local sStart = makeSound(6026984224, 0.7)
local sStop = makeSound(9117423534, 0.6)
local sCount = makeSound(6895079853, 0.6)
local function play(s) pcall(function() s:Stop() s:Play() end) end
local function destroySounds()
	pcall(function() sClick:Destroy() sConfirm:Destroy() sCancel:Destroy() sStart:Destroy() sStop:Destroy() sCount:Destroy() end)
end

-- ========== ANTI VOID CORE ==========
local function setFallenHeight()
	pcall(function() workspace.FallenPartsDestroyHeight = 0 / 0 end)
	pcall(function()
		if workspace.FallenPartsDestroyHeight == workspace.FallenPartsDestroyHeight then
			workspace.FallenPartsDestroyHeight = -math.huge
		end
	end)
end

local function applyHumanoidProtect(hum)
	if not hum or not hum.Parent then return end
	pcall(function()
		hum.MaxHealth = math.max(hum.MaxHealth, 9e9)
		hum.Health = hum.MaxHealth
		hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
		hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	end)
end

local function startAntiVoidLoop()
	if antiConn then return end
	setFallenHeight()
	antiConn = RunService.Heartbeat:Connect(function()
		if not antiVoidEnabled then return end
		setFallenHeight()
		local char = player.Character
		if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if root and hum and root.Position.Y < -200 then
			applyHumanoidProtect(hum)
		end
	end)
	antiStepped = RunService.Stepped:Connect(function()
		if not antiVoidEnabled then return end
		local char = player.Character
		if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		local root = char:FindFirstChild("HumanoidRootPart")
		if hum and root and root.Position.Y < -200 then applyHumanoidProtect(hum) end
	end)
end

local function stopAntiVoidLoop()
	if antiConn then antiConn:Disconnect() antiConn = nil end
	if antiStepped then antiStepped:Disconnect() antiStepped = nil end
end

local function startGodLoop()
	if godConn then return end
	godConn = RunService.Heartbeat:Connect(function()
		if not godModeEnabled then return end
		local char = player.Character
		if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then applyHumanoidProtect(hum) end
	end)
end

local function stopGodLoop()
	if godConn then godConn:Disconnect() godConn = nil end
end

-- Liga anti-void e god desde o início
setFallenHeight()
startAntiVoidLoop()
startGodLoop()

-- ========== HELPERS ==========
local function getHRP()
	local char = player.Character
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
end
local function getHumanoid()
	local char = player.Character
	if not char then return nil end
	return char:FindFirstChildOfClass("Humanoid")
end
local function waitForCharacter(timeout)
	timeout = timeout or 4
	local t0 = tick()
	while tick() - t0 < timeout do
		local hrp, hum = getHRP(), getHumanoid()
		if hrp and hum and hum.Parent and hrp.Parent then return hrp, hum end
		task.wait(0.03)
	end
	return nil, nil
end
local function getTargetHRP()
	if not targetPlayer or not targetPlayer.Character then return nil end
	return targetPlayer.Character:FindFirstChild("HumanoidRootPart") or targetPlayer.Character:FindFirstChild("Torso")
end
local function findTool()
	local char, bp = player.Character, player:FindFirstChild("Backpack")
	if char then local t = char:FindFirstChild(TOOL_NAME) if t and t:IsA("Tool") then return t end end
	if bp then local t = bp:FindFirstChild(TOOL_NAME) if t and t:IsA("Tool") then return t end end
	return nil
end
local function getAnyTool()
	local char, bp = player.Character, player:FindFirstChild("Backpack")
	local katana = (char and char:FindFirstChild(SWORD_NAME)) or (bp and bp:FindFirstChild(SWORD_NAME))
	if katana then return katana end
	if char then for _, v in ipairs(char:GetChildren()) do if v:IsA("Tool") and v.Name ~= TOOL_NAME then return v end end end
	if bp then for _, v in ipairs(bp:GetChildren()) do if v:IsA("Tool") and v.Name ~= TOOL_NAME then return v end end end
	return nil
end

local function forcePosition(cf)
	local char, hrp = player.Character, getHRP()
	if not hrp or not hrp.Parent then return end
	pcall(function()
		if char then char:PivotTo(cf) end
		hrp.CFrame = cf
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end)
end

local function applyHoldProtect()
	setFallenHeight()
	local hum = getHumanoid()
	if not hum then return end
	pcall(function()
		applyHumanoidProtect(hum)
		hum.PlatformStand = true
		hum.WalkSpeed = 0
		hum.JumpPower = 0
		hum.JumpHeight = 0
		hum.AutoRotate = false
		hum:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
		hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
		pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end)
	end)
end

local function clearHoldConnections()
	if protectConn then protectConn:Disconnect() protectConn = nil end
	if toolConn then toolConn:Disconnect() toolConn = nil end
	if steppedConn then steppedConn:Disconnect() steppedConn = nil end
	if healthConn then healthConn:Disconnect() healthConn = nil end
	pcall(function() RunService:UnbindFromRenderStep("VoidSkyHold") end)
end

local function clearAll()
	clearHoldConnections()
	if trackConn then trackConn:Disconnect() trackConn = nil end
	if recoverConn then recoverConn:Disconnect() recoverConn = nil end
end

local function forceEquipTool()
	if not running then return end
	local hum = getHumanoid()
	if not hum then return end
	local tool = findTool()
	if tool and tool.Parent ~= player.Character then pcall(function() hum:EquipTool(tool) end) end
end

local function startToolForce()
	forceEquipTool()
	if toolConn then toolConn:Disconnect() end
	toolConn = RunService.Heartbeat:Connect(function()
		if not running then return end
		forceEquipTool()
	end)
end

local function enableHold(cf)
	clearHoldConnections()
	currentHoldCF = cf
	local hrp, hum = waitForCharacter(3)
	if not hrp or not hum then return end
	applyHoldProtect()
	hrp.Anchored = false
	for i = 1, 12 do forcePosition(cf) task.wait() end

	RunService:BindToRenderStep("VoidSkyHold", Enum.RenderPriority.Last.Value + 50, function()
		if not running or not currentHoldCF then return end
		forcePosition(currentHoldCF)
		applyHoldProtect()
	end)
	protectConn = RunService.Heartbeat:Connect(function()
		if not running or not currentHoldCF then return end
		forcePosition(currentHoldCF)
		applyHoldProtect()
	end)
	steppedConn = RunService.Stepped:Connect(function()
		if not running or not currentHoldCF then return end
		forcePosition(currentHoldCF)
	end)
	healthConn = RunService.Heartbeat:Connect(function()
		if not running then return end
		applyHoldProtect()
	end)
	startToolForce()
end

local function moveTo(cf)
	if not running then return end
	local hrp, hum = waitForCharacter(2.5)
	if not hrp or not hum then return end
	clearHoldConnections()
	currentHoldCF = nil
	applyHoldProtect()
	for i = 1, 15 do
		pcall(function()
			local char = player.Character
			if char then char:PivotTo(cf) end
			hrp.CFrame = cf
			hrp.AssemblyLinearVelocity = Vector3.zero
		end)
		task.wait()
	end
	if running then enableHold(cf) end
end

-- ========== GUI ==========
local gui = Instance.new("ScreenGui")
gui.Name = "VoidSkyUltra"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(300, 310)
main.Position = UDim2.new(0.5, -150, 0.12, 0)
main.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
main.BorderSizePixel = 0
main.Active = true
main.ClipsDescendants = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)
local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color = Color3.fromRGB(90, 100, 255)
mainStroke.Thickness = 1.6
mainStroke.Transparency = 0.2

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 42)
titleBar.BackgroundColor3 = Color3.fromRGB(18, 20, 30)
titleBar.BorderSizePixel = 0
titleBar.Parent = main
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 14)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -110, 1, 0)
title.Position = UDim2.fromOffset(14, 0)
title.BackgroundTransparency = 1
title.Text = "VOID ULTRA v9"
title.TextColor3 = Color3.fromRGB(240, 240, 255)
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local function tBtn(txt, col, x)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(28, 28)
	b.Position = UDim2.new(1, x, 0.5, -14)
	b.BackgroundColor3 = col
	b.Text = txt
	b.TextColor3 = Color3.new(1,1,1)
	b.TextSize = 15
	b.Font = Enum.Font.GothamBold
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	b.Parent = titleBar
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
	return b
end
local btnClose = tBtn("×", Color3.fromRGB(210, 50, 50), -36)
local btnMax = tBtn("□", Color3.fromRGB(55, 140, 220), -70)
local btnMin = tBtn("−", Color3.fromRGB(70, 70, 90), -104)

local content = Instance.new("Frame")
content.Size = UDim2.new(1, 0, 1, -42)
content.Position = UDim2.fromOffset(0, 42)
content.BackgroundTransparency = 1
content.Parent = main

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, -24, 0, 48)
info.Position = UDim2.fromOffset(12, 4)
info.BackgroundTransparency = 1
info.Text = "1. Player → 2. Martelo (5s/TP) → 3. Void -100k\nAnti-Void NaN + God Mode sempre ligados"
info.TextColor3 = Color3.fromRGB(150, 155, 180)
info.TextSize = 11
info.Font = Enum.Font.Gotham
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextYAlignment = Enum.TextYAlignment.Top
info.Parent = content

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -24, 0, 18)
status.Position = UDim2.fromOffset(12, 54)
status.BackgroundTransparency = 1
status.Text = "Status: Parado"
status.TextColor3 = Color3.fromRGB(200, 85, 85)
status.TextSize = 13
status.Font = Enum.Font.GothamBold
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = content

local function mkBtn(parent, text, color, size, pos)
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos
	b.BackgroundColor3 = color
	b.Text = text
	b.TextColor3 = Color3.new(1,1,1)
	b.TextSize = 13
	b.Font = Enum.Font.GothamBold
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	return b
end

local antiBtn = mkBtn(content, "ANTI VOID: ON", Color3.fromRGB(40, 180, 90), UDim2.new(0.48, -8, 0, 36), UDim2.new(0, 12, 0, 80))
local godBtn = mkBtn(content, "GOD MODE: ON", Color3.fromRGB(40, 180, 90), UDim2.new(0.48, -8, 0, 36), UDim2.new(0.5, 4, 0, 80))
local startBtn = mkBtn(content, "INICIAR", Color3.fromRGB(40, 170, 90), UDim2.new(0.48, -8, 0, 44), UDim2.new(0, 12, 1, -56))
local stopBtn = mkBtn(content, "PARAR", Color3.fromRGB(210, 50, 50), UDim2.new(0.48, -8, 0, 44), UDim2.new(0.5, 4, 1, -56))

local function setStatus(t, c)
	if status and status.Parent then status.Text = "Status: " .. t status.TextColor3 = c end
end
local function setStartEnabled(e)
	startBtn.Active = e
	startBtn.BackgroundColor3 = e and Color3.fromRGB(40, 170, 90) or Color3.fromRGB(55, 55, 65)
end

antiBtn.MouseButton1Click:Connect(function()
	antiVoidEnabled = not antiVoidEnabled
	if antiVoidEnabled then
		antiBtn.Text = "ANTI VOID: ON"
		antiBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 90)
		startAntiVoidLoop()
	else
		antiBtn.Text = "ANTI VOID: OFF"
		antiBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 78)
		stopAntiVoidLoop()
	end
	play(sClick)
end)

godBtn.MouseButton1Click:Connect(function()
	godModeEnabled = not godModeEnabled
	if godModeEnabled then
		godBtn.Text = "GOD MODE: ON"
		godBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 90)
		startGodLoop()
	else
		godBtn.Text = "GOD MODE: OFF"
		godBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 78)
		stopGodLoop()
	end
	play(sClick)
end)

-- Player list
local playerListGui = Instance.new("Frame")
playerListGui.Size = UDim2.fromOffset(0, 0)
playerListGui.Position = UDim2.new(0.5, 0, 0.5, 0)
playerListGui.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
playerListGui.BorderSizePixel = 0
playerListGui.Visible = false
playerListGui.Active = true
playerListGui.ClipsDescendants = true
playerListGui.Parent = gui
Instance.new("UICorner", playerListGui).CornerRadius = UDim.new(0, 14)
local plStroke = Instance.new("UIStroke", playerListGui)
plStroke.Color = Color3.fromRGB(90, 100, 255)
plStroke.Thickness = 1.5

local plTitleBar = Instance.new("Frame")
plTitleBar.Size = UDim2.new(1, 0, 0, 40)
plTitleBar.BackgroundColor3 = Color3.fromRGB(18, 20, 30)
plTitleBar.BorderSizePixel = 0
plTitleBar.Parent = playerListGui
Instance.new("UICorner", plTitleBar).CornerRadius = UDim.new(0, 14)

local plTitle = Instance.new("TextLabel")
plTitle.Size = UDim2.new(1, -50, 1, 0)
plTitle.Position = UDim2.fromOffset(14, 0)
plTitle.BackgroundTransparency = 1
plTitle.Text = "Escolha o jogador"
plTitle.TextColor3 = Color3.fromRGB(235, 235, 245)
plTitle.TextSize = 15
plTitle.Font = Enum.Font.GothamBold
plTitle.TextXAlignment = Enum.TextXAlignment.Left
plTitle.Parent = plTitleBar

local plClose = Instance.new("TextButton")
plClose.Size = UDim2.fromOffset(28, 28)
plClose.Position = UDim2.new(1, -36, 0.5, -14)
plClose.BackgroundColor3 = Color3.fromRGB(210, 50, 50)
plClose.Text = "×"
plClose.TextColor3 = Color3.new(1,1,1)
plClose.TextSize = 15
plClose.Font = Enum.Font.GothamBold
plClose.BorderSizePixel = 0
plClose.AutoButtonColor = false
plClose.Parent = plTitleBar
Instance.new("UICorner", plClose).CornerRadius = UDim.new(0, 7)

local plScroll = Instance.new("ScrollingFrame")
plScroll.Size = UDim2.new(1, -20, 1, -110)
plScroll.Position = UDim2.fromOffset(10, 45)
plScroll.BackgroundTransparency = 1
plScroll.BorderSizePixel = 0
plScroll.ScrollBarThickness = 4
plScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
plScroll.Parent = playerListGui
Instance.new("UIListLayout", plScroll).Padding = UDim.new(0, 6)

local confirmFrame = Instance.new("Frame")
confirmFrame.Size = UDim2.new(1, -20, 0, 50)
confirmFrame.Position = UDim2.new(0, 10, 1, -60)
confirmFrame.BackgroundTransparency = 1
confirmFrame.Visible = false
confirmFrame.Parent = playerListGui

local confBtn = mkBtn(confirmFrame, "Confirmar", Color3.fromRGB(40, 170, 90), UDim2.new(0.48, 0, 1, 0), UDim2.new(0, 0, 0, 0))
local cancBtn = mkBtn(confirmFrame, "Cancelar", Color3.fromRGB(210, 50, 50), UDim2.new(0.48, 0, 1, 0), UDim2.new(0.52, 0, 0, 0))

local countdownGui = Instance.new("Frame")
countdownGui.Size = UDim2.fromOffset(220, 120)
countdownGui.Position = UDim2.new(0.5, -110, 0.4, 0)
countdownGui.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
countdownGui.BorderSizePixel = 0
countdownGui.Visible = false
countdownGui.Parent = gui
Instance.new("UICorner", countdownGui).CornerRadius = UDim.new(0, 14)
Instance.new("UIStroke", countdownGui).Color = Color3.fromRGB(90, 100, 255)

local cdTitle = Instance.new("TextLabel")
cdTitle.Size = UDim2.new(1, 0, 0, 30)
cdTitle.Position = UDim2.fromOffset(0, 12)
cdTitle.BackgroundTransparency = 1
cdTitle.Text = "Iniciando em"
cdTitle.TextColor3 = Color3.fromRGB(200, 200, 220)
cdTitle.TextSize = 14
cdTitle.Font = Enum.Font.Gotham
cdTitle.Parent = countdownGui

local cdNumber = Instance.new("TextLabel")
cdNumber.Size = UDim2.new(1, 0, 0, 60)
cdNumber.Position = UDim2.fromOffset(0, 40)
cdNumber.BackgroundTransparency = 1
cdNumber.Text = "3"
cdNumber.TextColor3 = Color3.fromRGB(100, 255, 160)
cdNumber.TextSize = 48
cdNumber.Font = Enum.Font.GothamBold
cdNumber.Parent = countdownGui

-- ========== HAMMER ==========
local function tryGrabOnce()
	local char = player.Character
	if not char then return false end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	local backpack = player:FindFirstChild("Backpack")
	if not humanoid or not root then return false end

	local hammer = findTool()
	if hammer then humanoid:EquipTool(hammer) return true end

	local wsH = workspace:FindFirstChild(TOOL_NAME)
	if wsH and wsH:IsA("Tool") then
		pcall(function() wsH.Parent = backpack task.wait(0.04) humanoid:EquipTool(wsH) end)
		if findTool() then return true end
	end

	local tool = getAnyTool()
	if not tool then return false end
	local savedCF = currentHoldCF or root.CFrame
	humanoid:EquipTool(tool)
	task.wait(0.06)
	local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
	if not handle then return false end

	local function destroyGrip()
		for _, side in ipairs({"RightHand", "Right Arm"}) do
			local part = char:FindFirstChild(side)
			if part then local g = part:FindFirstChild("RightGrip") if g then g:Destroy() end end
		end
	end
	destroyGrip() task.wait(0.02) destroyGrip()
	handle.CFrame = CFrame.new(POS_SHOP + Vector3.new(0, 1.7, 0))
	handle.AssemblyLinearVelocity = Vector3.zero

	if firetouchinterest then
		local target = nil
		local h = workspace:FindFirstChild(TOOL_NAME, true)
		if h and h:IsA("Tool") then target = h:FindFirstChild("Handle") or h:FindFirstChildWhichIsA("BasePart") end
		if not target then
			for _, obj in pairs(workspace:GetDescendants()) do
				if obj:IsA("BasePart") and (obj.Position - POS_SHOP).Magnitude < 18 then target = obj break end
			end
		end
		if target then
			for i = 1, 6 do
				pcall(function() firetouchinterest(handle, target, 0) task.wait(0.01) firetouchinterest(handle, target, 1) end)
				task.wait(0.012)
			end
		end
	end
	if currentHoldCF then forcePosition(currentHoldCF) else root.CFrame = savedCF root.AssemblyLinearVelocity = Vector3.zero end
	task.wait(0.25)
	hammer = findTool()
	if hammer then humanoid:EquipTool(hammer) return true end
	return false
end

local function tryGrabWithTimeout()
	local t0 = tick()
	while tick() - t0 < GRAB_TIMEOUT do
		if not running then return false end
		if tryGrabOnce() then return true end
		setStatus(string.format("Martelo... %.1fs", tick() - t0), Color3.fromRGB(255, 190, 60))
		task.wait(0.35)
	end
	setStatus("TP até o martelo...", Color3.fromRGB(255, 140, 40))
	local hrp = getHRP()
	if hrp then
		local cf = CFrame.new(POS_SHOP + Vector3.new(0, 4, 0))
		for i = 1, 8 do hrp.CFrame = cf hrp.AssemblyLinearVelocity = Vector3.zero task.wait() end
		task.wait(0.35)
		for i = 1, 8 do
			if not running then return false end
			if tryGrabOnce() then return true end
			task.wait(0.25)
		end
	end
	return findTool() ~= nil
end

local function startHammerRecover()
	if recoverConn then recoverConn:Disconnect() end
	recoverConn = RunService.Heartbeat:Connect(function()
		if not running then return end
		if findTool() then hammerReady = true forceEquipTool() return end
		hammerReady = false
		if recoveringHammer then return end
		if tick() - lastRecoverAttempt < 1.5 then return end
		recoveringHammer = true
		lastRecoverAttempt = tick()
		setStatus("Martelo sumiu! Recuperando...", Color3.fromRGB(255, 180, 50))
		task.spawn(function()
			local ok = tryGrabWithTimeout()
			if ok then
				hammerReady = true forceEquipTool() startToolForce()
				if currentHoldCF and running then moveTo(currentHoldCF) end
				setStatus("Martelo recuperado!", Color3.fromRGB(70, 220, 120))
			else
				setStatus("Falhou recuperar...", Color3.fromRGB(255, 120, 50))
			end
			recoveringHammer = false
		end)
	end)
end

local function startTracking()
	if trackConn then trackConn:Disconnect() end
	trackConn = RunService.Heartbeat:Connect(function()
		if not running or not targetPlayer then return end
		local thrp = getTargetHRP()
		if not thrp then
			if currentMode ~= "void" then currentMode = "void" moveTo(POS_VOID) setStatus("Void (alvo morto)", Color3.fromRGB(100, 180, 255)) end
			return
		end
		if thrp.Position.Y >= HEIGHT_TRIGGER then
			if currentMode ~= "sky" then currentMode = "sky" moveTo(POS_SKY) setStatus("Céu (" .. targetPlayer.Name .. ")", Color3.fromRGB(100, 255, 160)) end
		else
			if currentMode ~= "void" then currentMode = "void" moveTo(POS_VOID) setStatus("Void (" .. targetPlayer.Name .. ")", Color3.fromRGB(100, 180, 255)) end
		end
	end)
end

local function restoreCharacter()
	clearAll()
	currentHoldCF = nil targetPlayer = nil currentMode = nil hammerReady = false recoveringHammer = false selectedPlayer = nil
	local hrp, hum = getHRP(), getHumanoid()
	if hum and hum.Parent then
		pcall(function()
			hum.PlatformStand = false hum.WalkSpeed = 16 hum.JumpPower = 50 hum.JumpHeight = 7.2 hum.AutoRotate = true
			hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
			hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
			hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
			hum:SetStateEnabled(Enum.HumanoidStateType.Flying, true)
			hum:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
			hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
			hum:ChangeState(Enum.HumanoidStateType.Running)
		end)
	end
	if hrp and hrp.Parent then
		hrp.Anchored = false
		if originalCF then hrp.CFrame = originalCF end
		hrp.AssemblyLinearVelocity = Vector3.zero
	end
end

local function stopSequence()
	if not running and not countdownActive then return end
	running = false countdownActive = false currentHoldCF = nil hammerReady = false recoveringHammer = false
	play(sStop)
	setStatus("Parado", Color3.fromRGB(200, 85, 85))
	if title and title.Parent then title.Text = "VOID ULTRA v9" title.TextColor3 = Color3.fromRGB(240, 240, 255) end
	countdownGui.Visible = false playerListGui.Visible = false playerListOpen = false confirmFrame.Visible = false
	setStartEnabled(true)
	task.wait(0.03)
	restoreCharacter()
end

local function startSequence()
	if running or not targetPlayer then return end
	running = true currentMode = nil hammerReady = false recoveringHammer = false
	originalCF = getHRP() and getHRP().CFrame or CFrame.new()
	setFallenHeight()
	applyHoldProtect()
	setStatus("Pegando martelo (5s)...", Color3.fromRGB(255, 200, 80))
	play(sStart)
	if title and title.Parent then title.Text = "⚡ " .. targetPlayer.Name title.TextColor3 = Color3.fromRGB(100, 255, 160) end
	setStartEnabled(false)
	playerListGui.Visible = false playerListOpen = false confirmFrame.Visible = false

	local got = tryGrabWithTimeout()
	if not got then
		setStatus("Falha ao pegar martelo", Color3.fromRGB(255, 80, 80))
		task.wait(1.2) stopSequence() return
	end
	forceEquipTool() startToolForce() hammerReady = true
	setStatus("Martelo OK → Void -100k", Color3.fromRGB(70, 220, 120))
	task.wait(0.1)
	currentMode = "void"
	moveTo(POS_VOID)
	setStatus("Void (" .. targetPlayer.Name .. ")", Color3.fromRGB(100, 180, 255))
	startTracking()
	startHammerRecover()
end

-- Player list UI
local function refreshPlayerList()
	for _, c in ipairs(plScroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
	confirmFrame.Visible = false selectedPlayer = nil
	local y = 0
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player then
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, -4, 0, 36)
			btn.BackgroundColor3 = Color3.fromRGB(30, 32, 48)
			btn.Text = plr.Name
			btn.TextColor3 = Color3.new(1,1,1)
			btn.TextSize = 14
			btn.Font = Enum.Font.Gotham
			btn.BorderSizePixel = 0
			btn.AutoButtonColor = false
			btn.Parent = plScroll
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
			btn.MouseButton1Click:Connect(function()
				play(sClick)
				selectedPlayer = plr targetPlayer = plr
				for _, c in ipairs(plScroll:GetChildren()) do if c:IsA("TextButton") then c.BackgroundColor3 = Color3.fromRGB(30, 32, 48) end end
				btn.BackgroundColor3 = Color3.fromRGB(50, 90, 180)
				confirmFrame.Visible = true
			end)
			y = y + 42
		end
	end
	plScroll.CanvasSize = UDim2.new(0, 0, 0, math.max(y, 80))
end

local function openPlayerList()
	if playerListOpen or running or countdownActive then return end
	playerListOpen = true refreshPlayerList()
	playerListGui.Visible = true
	playerListGui.Size = UDim2.fromOffset(0, 0)
	playerListGui.Position = UDim2.new(0.5, 0, 0.5, 0)
	playerListGui.BackgroundTransparency = 1
	TweenService:Create(playerListGui, TweenInfo.new(0.32, Enum.EasingStyle.Back), {
		Size = UDim2.fromOffset(260, 340), Position = UDim2.new(0.5, -130, 0.5, -170), BackgroundTransparency = 0
	}):Play()
	play(sClick)
end

local function closePlayerList()
	if not playerListOpen then return end
	play(sCancel)
	local t = TweenService:Create(playerListGui, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Size = UDim2.fromOffset(0, 0), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1
	})
	t:Play() t.Completed:Wait()
	playerListGui.Visible = false playerListOpen = false confirmFrame.Visible = false selectedPlayer = nil
end

local function playCountdown(cb)
	if countdownActive then return end
	countdownActive = true countdownGui.Visible = true
	countdownGui.BackgroundTransparency = 1 cdNumber.TextTransparency = 1 cdTitle.TextTransparency = 1
	TweenService:Create(countdownGui, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
	TweenService:Create(cdTitle, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
	for i = 3, 1, -1 do
		if not countdownActive then countdownGui.Visible = false return end
		cdNumber.Text = tostring(i) cdNumber.TextSize = 20 cdNumber.TextTransparency = 1
		TweenService:Create(cdNumber, TweenInfo.new(0.15), {TextSize = 52, TextTransparency = 0}):Play()
		play(sCount)
		local w = 0
		while w < 0.85 do if not countdownActive then countdownGui.Visible = false return end task.wait(0.05) w = w + 0.05 end
		TweenService:Create(cdNumber, TweenInfo.new(0.2), {TextSize = 30, TextTransparency = 1}):Play()
		task.wait(0.15)
	end
	if not countdownActive then countdownGui.Visible = false return end
	TweenService:Create(countdownGui, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
	TweenService:Create(cdTitle, TweenInfo.new(0.25), {TextTransparency = 1}):Play()
	task.wait(0.25) countdownGui.Visible = false countdownActive = false
	if cb then cb() end
end

confBtn.MouseButton1Click:Connect(function()
	if not selectedPlayer then return end
	play(sConfirm) targetPlayer = selectedPlayer closePlayerList()
	playCountdown(function() startSequence() end)
end)
cancBtn.MouseButton1Click:Connect(function()
	play(sCancel) selectedPlayer = nil targetPlayer = nil confirmFrame.Visible = false
	for _, c in ipairs(plScroll:GetChildren()) do if c:IsA("TextButton") then c.BackgroundColor3 = Color3.fromRGB(30, 32, 48) end end
end)
plClose.MouseButton1Click:Connect(closePlayerList)
startBtn.MouseButton1Click:Connect(function()
	if running or countdownActive or closing then return end
	openPlayerList()
end)
stopBtn.MouseButton1Click:Connect(function() play(sClick) stopSequence() end)

-- Drag
local function makeDraggable(frame, handle)
	local dragging, dragStart, startPos, dragInput
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true dragStart = input.Position startPos = frame.Position
			local c c = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false if c then c:Disconnect() end end
			end)
		end
	end)
	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input == dragInput then
			local d = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end
makeDraggable(main, titleBar)
makeDraggable(playerListGui, plTitleBar)

local minimized, maximized = false, false
local normalSize, normalPos = main.Size, main.Position
btnMin.MouseButton1Click:Connect(function()
	play(sClick) minimized = not minimized
	if minimized then
		TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size = UDim2.fromOffset(300, 42)}):Play()
		content.Visible = false btnMin.Text = "+"
	else
		content.Visible = true
		TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size = maximized and UDim2.fromOffset(340, 340) or normalSize}):Play()
		btnMin.Text = "−"
	end
end)
btnMax.MouseButton1Click:Connect(function()
	if minimized then return end
	play(sClick) maximized = not maximized
	if maximized then
		normalSize = main.Size normalPos = main.Position
		TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size = UDim2.fromOffset(340, 340), Position = UDim2.new(0.5, -170, 0.5, -170)}):Play()
		btnMax.Text = "❐"
	else
		TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size = normalSize, Position = normalPos}):Play()
		btnMax.Text = "□"
	end
end)
btnClose.MouseButton1Click:Connect(function()
	if closing then return end
	closing = true play(sCancel)
	running = false countdownActive = false
	clearAll() stopAntiVoidLoop() stopGodLoop()
	local t = TweenService:Create(main, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1})
	t:Play() t.Completed:Wait()
	restoreCharacter() destroySounds() gui:Destroy()
end)

player.CharacterAdded:Connect(function()
	task.wait(0.3)
	setFallenHeight()
	local hrp, hum = waitForCharacter(4)
	if not hrp then return end
	if running then
		applyHoldProtect()
		if currentHoldCF then enableHold(currentHoldCF) else enableHold(POS_VOID) end
		forceEquipTool() startToolForce() startHammerRecover()
	else
		pcall(function()
			hum.PlatformStand = false hum.WalkSpeed = 16 hum.JumpPower = 50 hum.JumpHeight = 7.2 hum.AutoRotate = true hrp.Anchored = false
		end)
	end
	if godModeEnabled and hum then applyHumanoidProtect(hum) end
end)

print("✅ VOID ULTRA v9.0 | VoidSky + AntiVoid Premium + God Mode | Y=-100000")
