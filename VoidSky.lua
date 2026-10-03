-- Void ↔️ Céu v7.2
-- Fluxo:
-- 1) Seleciona player
-- 2) Fica parado onde está
-- 3) Pega martelo (fling da tool)
-- 4) Vai pro Void Y=-1000000
-- 5) Alvo Y >= 100 → Céu Y=10000000
-- 6) Alvo Y < 100  → Void

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer

if player.PlayerGui:FindFirstChild("VoidSky") then
	player.PlayerGui.VoidSky:Destroy()
end

-- ==================== CONFIG ====================
local POS_VOID = CFrame.new(0, -1000000, 0)
local POS_SKY  = CFrame.new(0, 10000000, 0)
local POS_SHOP = Vector3.new(-119.27, 18.30, 166.50)
local HEIGHT_TRIGGER = 100
local TOOL_NAME = "SledgeHammer"
local SWORD_NAME = "KatanaGroup"

-- ==================== ESTADO ====================
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

local protectConn = nil
local toolConn = nil
local trackConn = nil
local steppedConn = nil
local healthConn = nil

-- ==================== SONS ====================
local function makeSound(id, vol)
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. tostring(id)
	s.Volume = vol or 0.5
	s.Parent = SoundService
	return s
end

local sClick   = makeSound(6895079853, 0.45)
local sConfirm = makeSound(9117411612, 0.65)
local sCancel  = makeSound(9117423534, 0.5)
local sStart   = makeSound(6026984224, 0.7)
local sStop    = makeSound(9117423534, 0.6)
local sCount   = makeSound(6895079853, 0.6)

local function play(s)
	pcall(function() s:Stop() s:Play() end)
end

local function destroySounds()
	pcall(function()
		sClick:Destroy() sConfirm:Destroy() sCancel:Destroy()
		sStart:Destroy() sStop:Destroy() sCount:Destroy()
	end)
end

-- ==================== GUI ====================
local gui = Instance.new("ScreenGui")
gui.Name = "VoidSky"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(280, 200)
main.Position = UDim2.new(0.5, -140, 0.18, 0)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 21)
main.BorderSizePixel = 0
main.Active = true
main.ClipsDescendants = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)

local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(90, 90, 130)
stroke.Thickness = 1.4
stroke.Transparency = 0.25

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(23, 23, 32)
titleBar.BorderSizePixel = 0
titleBar.Parent = main
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 14)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -115, 1, 0)
title.Position = UDim2.fromOffset(16, 0)
title.BackgroundTransparency = 1
title.Text = "Void ↔️ Céu"
title.TextColor3 = Color3.fromRGB(235, 235, 245)
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local function titleBtn(txt, col, x)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(28, 28)
	b.Position = UDim2.new(1, x, 0.5, -14)
	b.BackgroundColor3 = col
	b.Text = txt
	b.TextColor3 = Color3.new(1, 1, 1)
	b.TextSize = 15
	b.Font = Enum.Font.GothamBold
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	b.Parent = titleBar
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
	return b
end

local btnClose = titleBtn("×", Color3.fromRGB(210, 55, 55), -36)
local btnMax   = titleBtn("□", Color3.fromRGB(55, 140, 220), -70)
local btnMin   = titleBtn("−", Color3.fromRGB(70, 70, 90), -104)

local content = Instance.new("Frame")
content.Size = UDim2.new(1, 0, 1, -40)
content.Position = UDim2.fromOffset(0, 40)
content.BackgroundTransparency = 1
content.Parent = main

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, -28, 0, 62)
info.Position = UDim2.fromOffset(14, 8)
info.BackgroundTransparency = 1
info.Text = "1. Escolhe o player\n2. Pega o martelo (fica parado)\n3. Void → Céu quando alvo Y≥100"
info.TextColor3 = Color3.fromRGB(165, 165, 185)
info.TextSize = 12
info.Font = Enum.Font.Gotham
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextYAlignment = Enum.TextYAlignment.Top
info.Parent = content

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -28, 0, 18)
status.Position = UDim2.fromOffset(14, 74)
status.BackgroundTransparency = 1
status.Text = "Status: Parado"
status.TextColor3 = Color3.fromRGB(200, 85, 85)
status.TextSize = 13
status.Font = Enum.Font.GothamBold
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = content

local function createBtn(parent, text, color, size, pos)
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos
	b.BackgroundColor3 = color
	b.Text = text
	b.TextColor3 = Color3.new(1, 1, 1)
	b.TextSize = 14
	b.Font = Enum.Font.GothamBold
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	local oSize, oPos = size, pos
	b.MouseButton1Down:Connect(function()
		if b.Active then
			TweenService:Create(b, TweenInfo.new(0.08), {Size = oSize - UDim2.fromOffset(4, 4), Position = oPos + UDim2.fromOffset(2, 2)}):Play()
		end
	end)
	b.MouseButton1Up:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.14, Enum.EasingStyle.Back), {Size = oSize, Position = oPos}):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.1), {Size = oSize, Position = oPos}):Play()
	end)
	return b
end

local startBtn = createBtn(content, "INICIAR", Color3.fromRGB(40, 170, 90), UDim2.new(0.5, -16, 0, 42), UDim2.new(0, 14, 1, -54))
local stopBtn  = createBtn(content, "PARAR",  Color3.fromRGB(210, 50, 50), UDim2.new(0.5, -16, 0, 42), UDim2.new(0.5, 2, 1, -54))

-- ==================== PLAYER LIST ====================
local playerListGui = Instance.new("Frame")
playerListGui.Size = UDim2.fromOffset(0, 0)
playerListGui.Position = UDim2.new(0.5, 0, 0.5, 0)
playerListGui.BackgroundColor3 = Color3.fromRGB(15, 15, 21)
playerListGui.BorderSizePixel = 0
playerListGui.Visible = false
playerListGui.Active = true
playerListGui.ClipsDescendants = true
playerListGui.Parent = gui
Instance.new("UICorner", playerListGui).CornerRadius = UDim.new(0, 14)

local plStroke = Instance.new("UIStroke", playerListGui)
plStroke.Color = Color3.fromRGB(90, 90, 130)
plStroke.Thickness = 1.4
plStroke.Transparency = 0.25

local plTitleBar = Instance.new("Frame")
plTitleBar.Size = UDim2.new(1, 0, 0, 40)
plTitleBar.BackgroundColor3 = Color3.fromRGB(23, 23, 32)
plTitleBar.BorderSizePixel = 0
plTitleBar.Parent = playerListGui
Instance.new("UICorner", plTitleBar).CornerRadius = UDim.new(0, 14)

local plTitle = Instance.new("TextLabel")
plTitle.Size = UDim2.new(1, -50, 1, 0)
plTitle.Position = UDim2.fromOffset(16, 0)
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
plClose.BackgroundColor3 = Color3.fromRGB(210, 55, 55)
plClose.Text = "×"
plClose.TextColor3 = Color3.new(1, 1, 1)
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

local plLayout = Instance.new("UIListLayout")
plLayout.Padding = UDim.new(0, 6)
plLayout.Parent = plScroll

local confirmFrame = Instance.new("Frame")
confirmFrame.Size = UDim2.new(1, -20, 0, 50)
confirmFrame.Position = UDim2.new(0, 10, 1, -60)
confirmFrame.BackgroundTransparency = 1
confirmFrame.Visible = false
confirmFrame.Parent = playerListGui

local confBtn = Instance.new("TextButton")
confBtn.Size = UDim2.new(0.48, 0, 1, 0)
confBtn.Position = UDim2.new(0, 0, 0, 0)
confBtn.BackgroundColor3 = Color3.fromRGB(40, 170, 90)
confBtn.Text = "Confirmar"
confBtn.TextColor3 = Color3.new(1, 1, 1)
confBtn.TextSize = 14
confBtn.Font = Enum.Font.GothamBold
confBtn.BorderSizePixel = 0
confBtn.AutoButtonColor = false
confBtn.Parent = confirmFrame
Instance.new("UICorner", confBtn).CornerRadius = UDim.new(0, 8)

local cancBtn = Instance.new("TextButton")
cancBtn.Size = UDim2.new(0.48, 0, 1, 0)
cancBtn.Position = UDim2.new(0.52, 0, 0, 0)
cancBtn.BackgroundColor3 = Color3.fromRGB(210, 50, 50)
cancBtn.Text = "Cancelar"
cancBtn.TextColor3 = Color3.new(1, 1, 1)
cancBtn.TextSize = 14
cancBtn.Font = Enum.Font.GothamBold
cancBtn.BorderSizePixel = 0
cancBtn.AutoButtonColor = false
cancBtn.Parent = confirmFrame
Instance.new("UICorner", cancBtn).CornerRadius = UDim.new(0, 8)

local countdownGui = Instance.new("Frame")
countdownGui.Size = UDim2.fromOffset(220, 120)
countdownGui.Position = UDim2.new(0.5, -110, 0.4, 0)
countdownGui.BackgroundColor3 = Color3.fromRGB(15, 15, 21)
countdownGui.BorderSizePixel = 0
countdownGui.Visible = false
countdownGui.Parent = gui
Instance.new("UICorner", countdownGui).CornerRadius = UDim.new(0, 14)

local cdStroke = Instance.new("UIStroke", countdownGui)
cdStroke.Color = Color3.fromRGB(90, 90, 130)
cdStroke.Thickness = 1.5

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

-- ==================== FUNÇÕES ====================
local function clearHoldConnections()
	if protectConn then protectConn:Disconnect() protectConn = nil end
	if toolConn then toolConn:Disconnect() toolConn = nil end
	if steppedConn then steppedConn:Disconnect() steppedConn = nil end
	if healthConn then healthConn:Disconnect() healthConn = nil end
	pcall(function() RunService:UnbindFromRenderStep("VoidSkyHold") end)
end

local function clearConnections()
	clearHoldConnections()
	if trackConn then trackConn:Disconnect() trackConn = nil end
end

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
	local start = tick()
	while tick() - start < timeout do
		local hrp = getHRP()
		local hum = getHumanoid()
		if hrp and hum and hum.Parent and hrp.Parent then
			return hrp, hum
		end
		task.wait(0.03)
	end
	return nil, nil
end

local function getTargetHRP()
	if not targetPlayer or not targetPlayer.Character then return nil end
	return targetPlayer.Character:FindFirstChild("HumanoidRootPart")
		or targetPlayer.Character:FindFirstChild("Torso")
end

local function findTool()
	local char = player.Character
	local backpack = player:FindFirstChild("Backpack")
	if char then
		local tool = char:FindFirstChild(TOOL_NAME)
		if tool and tool:IsA("Tool") then return tool end
	end
	if backpack then
		local tool = backpack:FindFirstChild(TOOL_NAME)
		if tool and tool:IsA("Tool") then return tool end
	end
	return nil
end

local function getAnyTool()
	local char = player.Character
	local backpack = player:FindFirstChild("Backpack")
	local katana = (char and char:FindFirstChild(SWORD_NAME)) or (backpack and backpack:FindFirstChild(SWORD_NAME))
	if katana then return katana end
	if char then
		for _, v in ipairs(char:GetChildren()) do
			if v:IsA("Tool") then return v end
		end
	end
	if backpack then
		for _, v in ipairs(backpack:GetChildren()) do
			if v:IsA("Tool") then return v end
		end
	end
	return nil
end

local function forceEquipTool()
	if not running then return end
	local hum = getHumanoid()
	if not hum then return end
	local tool = findTool()
	if tool and tool.Parent ~= player.Character then
		pcall(function() hum:EquipTool(tool) end)
	end
end

local function startToolForce()
	forceEquipTool()
	if toolConn then toolConn:Disconnect() end
	toolConn = RunService.Heartbeat:Connect(function()
		if not running then return end
		forceEquipTool()
	end)
end

local function forcePosition(cf)
	local hrp = getHRP()
	if hrp and hrp.Parent then
		pcall(function()
			hrp.CFrame = cf
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
		end)
	end
end

-- Anti-void MUITO forte
local function enableHold(cf)
	clearHoldConnections()
	currentHoldCF = cf

	local hrp, hum = waitForCharacter(3)
	if not hrp or not hum then return end

	pcall(function()
		hum.PlatformStand = true
		hum.WalkSpeed = 0
		hum.JumpPower = 0
		hum.JumpHeight = 0
		hum.AutoRotate = false
		hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
		hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
		hum:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
		hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
		hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
		hum.Health = hum.MaxHealth
	end)

	hrp.Anchored = false
	forcePosition(cf)

	RunService:BindToRenderStep("VoidSkyHold", Enum.RenderPriority.Last.Value + 20, function()
		if not running or not currentHoldCF then return end
		forcePosition(currentHoldCF)
	end)

	protectConn = RunService.Heartbeat:Connect(function()
		if not running or not currentHoldCF then return end
		forcePosition(currentHoldCF)
		local h = getHumanoid()
		if h and h.Parent then
			h.Health = h.MaxHealth
			h.PlatformStand = true
			h.WalkSpeed = 0
			h.JumpPower = 0
			h.JumpHeight = 0
		end
	end)

	steppedConn = RunService.Stepped:Connect(function()
		if not running or not currentHoldCF then return end
		forcePosition(currentHoldCF)
	end)

	healthConn = RunService.Heartbeat:Connect(function()
		if not running then return end
		local h = getHumanoid()
		if h and h.Parent then
			if h.Health < h.MaxHealth then h.Health = h.MaxHealth end
		end
	end)

	startToolForce()
end

local function moveTo(cf)
	if not running then return end
	local hrp, hum = waitForCharacter(2.5)
	if not hrp or not hum then return end

	clearHoldConnections()
	currentHoldCF = nil

	pcall(function()
		hum.PlatformStand = true
		hum.WalkSpeed = 0
		hum.JumpPower = 0
		hum.JumpHeight = 0
		hum.AutoRotate = false
	end)

	pcall(function()
		local char = player.Character
		if char then char:PivotTo(cf) end
		hrp.CFrame = cf
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end)

	if running then
		enableHold(cf)
	end
end

local function setStatus(text, color)
	if status and status.Parent then
		status.Text = "Status: " .. text
		status.TextColor3 = color
	end
end

local function setButtonsEnabled(enabled)
	startBtn.Active = enabled
	startBtn.BackgroundColor3 = enabled and Color3.fromRGB(40, 170, 90) or Color3.fromRGB(60, 60, 70)
end

local function restoreCharacter()
	clearConnections()
	currentHoldCF = nil
	targetPlayer = nil
	currentMode = nil
	hammerReady = false
	selectedPlayer = nil

	local hrp = getHRP()
	local hum = getHumanoid()

	if hum and hum.Parent then
		pcall(function()
			hum.PlatformStand = false
			hum.WalkSpeed = 16
			hum.JumpPower = 50
			hum.JumpHeight = 7.2
			hum.AutoRotate = true
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
		hrp.AssemblyAngularVelocity = Vector3.zero
	end
end

local function stopSequence()
	if not running and not countdownActive then return end
	running = false
	countdownActive = false
	currentHoldCF = nil
	hammerReady = false

	play(sStop)
	setStatus("Parado", Color3.fromRGB(200, 85, 85))
	if title and title.Parent then
		title.Text = "Void ↔️ Céu"
		title.TextColor3 = Color3.fromRGB(235, 235, 245)
	end

	countdownGui.Visible = false
	playerListGui.Visible = false
	playerListOpen = false
	confirmFrame.Visible = false
	setButtonsEnabled(true)
	task.wait(0.03)
	restoreCharacter()
end

-- Pega martelo SEM teleportar o personagem (fica parado)
local function tryGrabHammer()
	local char = player.Character
	if not char then return false end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	local backpack = player:FindFirstChild("Backpack")
	if not humanoid or not root then return false end

	-- Já tem?
	local hammer = findTool()
	if hammer then
		humanoid:EquipTool(hammer)
		return true
	end

	-- Workspace
	local wsHammer = workspace:FindFirstChild(TOOL_NAME)
	if wsHammer and wsHammer:IsA("Tool") then
		pcall(function()
			wsHammer.Parent = backpack
			task.wait(0.05)
			humanoid:EquipTool(wsHammer)
		end)
		if findTool() then return true end
	end

	-- Fling com qualquer tool (personagem NÃO se move)
	local tool = getAnyTool()
	if not tool then return false end

	local savedCF = root.CFrame
	humanoid:EquipTool(tool)
	task.wait(0.1)

	local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
	if not handle then return false end

	local function destroyGrip()
		for _, side in ipairs({"RightHand", "Right Arm"}) do
			local part = char:FindFirstChild(side)
			if part then
				local grip = part:FindFirstChild("RightGrip")
				if grip then grip:Destroy() end
			end
		end
	end

	destroyGrip()
	task.wait(0.03)
	destroyGrip()

	-- Só a tool vai pro shop, você fica parado
	handle.CFrame = CFrame.new(POS_SHOP + Vector3.new(0, 1.7, 0))
	handle.AssemblyLinearVelocity = Vector3.zero

	if firetouchinterest then
		local target = nil
		local h = workspace:FindFirstChild(TOOL_NAME, true)
		if h and h:IsA("Tool") then
			target = h:FindFirstChild("Handle") or h:FindFirstChildWhichIsA("BasePart")
		end
		if not target then
			for _, obj in pairs(workspace:GetDescendants()) do
				if obj:IsA("BasePart") and (obj.Position - POS_SHOP).Magnitude < 18 then
					target = obj
					break
				end
			end
		end
		if target then
			for i = 1, 8 do
				pcall(function()
					firetouchinterest(handle, target, 0)
					task.wait(0.012)
					firetouchinterest(handle, target, 1)
				end)
				task.wait(0.015)
			end
		end
	end

	-- Garante que você continua no mesmo lugar
	root.CFrame = savedCF
	root.AssemblyLinearVelocity = Vector3.zero
	task.wait(0.4)

	hammer = findTool()
	if hammer then
		humanoid:EquipTool(hammer)
		return true
	end
	return false
end

local function startTracking()
	if trackConn then trackConn:Disconnect() end

	trackConn = RunService.Heartbeat:Connect(function()
		if not running or not targetPlayer or not hammerReady then return end

		local targetHRP = getTargetHRP()
		if not targetHRP then
			if currentMode ~= "void" then
				currentMode = "void"
				moveTo(POS_VOID)
				setStatus("Void (alvo morto)", Color3.fromRGB(100, 180, 255))
			end
			return
		end

		local targetY = targetHRP.Position.Y

		-- Alvo Y >= 100 → CÉU
		-- Alvo Y < 100  → VOID
		if targetY >= HEIGHT_TRIGGER then
			if currentMode ~= "sky" then
				currentMode = "sky"
				moveTo(POS_SKY)
				setStatus("Céu (" .. targetPlayer.Name .. ")", Color3.fromRGB(100, 255, 160))
			end
		else
			if currentMode ~= "void" then
				currentMode = "void"
				moveTo(POS_VOID)
				setStatus("Void (" .. targetPlayer.Name .. ")", Color3.fromRGB(100, 180, 255))
			end
		end
	end)
end

local function startSequence()
	if running or not targetPlayer then return end

	running = true
	currentMode = nil
	hammerReady = false
	originalCF = getHRP() and getHRP().CFrame or CFrame.new()

	setStatus("Pegando martelo...", Color3.fromRGB(255, 200, 80))
	play(sStart)
	if title and title.Parent then
		title.Text = "⚡ " .. targetPlayer.Name
		title.TextColor3 = Color3.fromRGB(100, 255, 160)
	end
	setButtonsEnabled(false)

	playerListGui.Visible = false
	playerListOpen = false
	confirmFrame.Visible = false

	-- 1) Fica parado e pega o martelo
	local got = false
	for i = 1, 5 do
		if not running then return end
		got = tryGrabHammer()
		if got then break end
		setStatus("Tentando martelo (" .. i .. "/5)...", Color3.fromRGB(255, 180, 50))
		task.wait(0.6)
	end

	if not got then
		setStatus("Falha ao pegar martelo", Color3.fromRGB(255, 80, 80))
		task.wait(1.5)
		stopSequence()
		return
	end

	forceEquipTool()
	startToolForce()
	hammerReady = true
	setStatus("Martelo OK → Void", Color3.fromRGB(70, 220, 120))

	-- 2) Vai pro VOID
	task.wait(0.15)
	currentMode = "void"
	moveTo(POS_VOID)
	setStatus("Void (" .. targetPlayer.Name .. ")", Color3.fromRGB(100, 180, 255))

	-- 3) Começa a rastrear (quando alvo Y>=100 → céu)
	startTracking()
end

-- ==================== PLAYER LIST ====================
local function refreshPlayerList()
	for _, child in ipairs(plScroll:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	confirmFrame.Visible = false
	selectedPlayer = nil

	local ySize = 0
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player then
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, -4, 0, 36)
			btn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
			btn.Text = plr.Name
			btn.TextColor3 = Color3.new(1, 1, 1)
			btn.TextSize = 14
			btn.Font = Enum.Font.Gotham
			btn.BorderSizePixel = 0
			btn.AutoButtonColor = false
			btn.Parent = plScroll
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

			btn.MouseButton1Click:Connect(function()
				play(sClick)
				selectedPlayer = plr
				targetPlayer = plr
				for _, child in ipairs(plScroll:GetChildren()) do
					if child:IsA("TextButton") then child.BackgroundColor3 = Color3.fromRGB(35, 35, 50) end
				end
				btn.BackgroundColor3 = Color3.fromRGB(55, 90, 140)
				confirmFrame.Visible = true
			end)
			ySize = ySize + 42
		end
	end
	plScroll.CanvasSize = UDim2.new(0, 0, 0, math.max(ySize, 80))
end

local function openPlayerList()
	if playerListOpen or running or countdownActive then return end
	playerListOpen = true
	refreshPlayerList()
	playerListGui.Visible = true
	playerListGui.Size = UDim2.fromOffset(0, 0)
	playerListGui.Position = UDim2.new(0.5, 0, 0.5, 0)
	playerListGui.BackgroundTransparency = 1
	TweenService:Create(playerListGui, TweenInfo.new(0.32, Enum.EasingStyle.Back), {
		Size = UDim2.fromOffset(260, 340),
		Position = UDim2.new(0.5, -130, 0.5, -170),
		BackgroundTransparency = 0
	}):Play()
	play(sClick)
end

local function closePlayerList()
	if not playerListOpen then return end
	play(sCancel)
	local t = TweenService:Create(playerListGui, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Size = UDim2.fromOffset(0, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundTransparency = 1
	})
	t:Play()
	t.Completed:Wait()
	playerListGui.Visible = false
	playerListOpen = false
	confirmFrame.Visible = false
	selectedPlayer = nil
end

local function playCountdown(callback)
	if countdownActive then return end
	countdownActive = true
	countdownGui.Visible = true
	countdownGui.BackgroundTransparency = 1
	cdNumber.TextTransparency = 1
	cdTitle.TextTransparency = 1
	TweenService:Create(countdownGui, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
	TweenService:Create(cdTitle, TweenInfo.new(0.3), {TextTransparency = 0}):Play()

	for i = 3, 1, -1 do
		if not countdownActive then countdownGui.Visible = false return end
		cdNumber.Text = tostring(i)
		cdNumber.TextSize = 20
		cdNumber.TextTransparency = 1
		TweenService:Create(cdNumber, TweenInfo.new(0.15), {TextSize = 52, TextTransparency = 0}):Play()
		play(sCount)
		local waited = 0
		while waited < 0.85 do
			if not countdownActive then countdownGui.Visible = false return end
			task.wait(0.05)
			waited = waited + 0.05
		end
		TweenService:Create(cdNumber, TweenInfo.new(0.2), {TextSize = 30, TextTransparency = 1}):Play()
		task.wait(0.15)
	end

	if not countdownActive then countdownGui.Visible = false return end
	TweenService:Create(countdownGui, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
	TweenService:Create(cdTitle, TweenInfo.new(0.25), {TextTransparency = 1}):Play()
	task.wait(0.25)
	countdownGui.Visible = false
	countdownActive = false
	if callback then callback() end
end

-- ==================== EVENTOS ====================
confBtn.MouseButton1Click:Connect(function()
	if not selectedPlayer then return end
	play(sConfirm)
	targetPlayer = selectedPlayer
	closePlayerList()
	playCountdown(function() startSequence() end)
end)

cancBtn.MouseButton1Click:Connect(function()
	play(sCancel)
	selectedPlayer = nil
	targetPlayer = nil
	confirmFrame.Visible = false
	for _, child in ipairs(plScroll:GetChildren()) do
		if child:IsA("TextButton") then child.BackgroundColor3 = Color3.fromRGB(35, 35, 50) end
	end
end)

plClose.MouseButton1Click:Connect(function() closePlayerList() end)

startBtn.MouseButton1Click:Connect(function()
	if running or countdownActive or closing then return end
	openPlayerList()
end)

stopBtn.MouseButton1Click:Connect(function()
	play(sClick)
	stopSequence()
end)

local function makeDraggable(frame, handle)
	local dragging = false
	local dragStart, startPos, dragInput
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			local conn
			conn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if conn then conn:Disconnect() end
				end
			end)
		end
	end)
	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input == dragInput then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

makeDraggable(main, titleBar)
makeDraggable(playerListGui, plTitleBar)

local minimized, maximized = false, false
local normalSize, normalPos = main.Size, main.Position

btnMin.MouseButton1Click:Connect(function()
	play(sClick)
	minimized = not minimized
	if minimized then
		TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size = UDim2.fromOffset(280, 40)}):Play()
		content.Visible = false
		btnMin.Text = "+"
	else
		content.Visible = true
		TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size = maximized and UDim2.fromOffset(320, 220) or normalSize}):Play()
		btnMin.Text = "−"
	end
end)

btnMax.MouseButton1Click:Connect(function()
	if minimized then return end
	play(sClick)
	maximized = not maximized
	if maximized then
		normalSize = main.Size
		normalPos = main.Position
		TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
			Size = UDim2.fromOffset(320, 220),
			Position = UDim2.new(0.5, -160, 0.5, -110)
		}):Play()
		btnMax.Text = "❐"
	else
		TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size = normalSize, Position = normalPos}):Play()
		btnMax.Text = "□"
	end
end)

btnClose.MouseButton1Click:Connect(function()
	if closing then return end
	closing = true
	play(sCancel)
	running = false
	countdownActive = false
	clearConnections()
	local t = TweenService:Create(main, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Size = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1
	})
	t:Play()
	t.Completed:Wait()
	restoreCharacter()
	destroySounds()
	gui:Destroy()
end)

player.CharacterAdded:Connect(function()
	task.wait(0.25)
	local hrp, hum = waitForCharacter(4)
	if not hrp then return end
	if running then
		if currentHoldCF then
			enableHold(currentHoldCF)
		else
			enableHold(POS_VOID)
		end
		forceEquipTool()
		startToolForce()
	else
		pcall(function()
			hum.PlatformStand = false
			hum.WalkSpeed = 16
			hum.JumpPower = 50
			hum.JumpHeight = 7.2
			hum.AutoRotate = true
			hrp.Anchored = false
		end)
	end
end)

print("✅ Void ↔️ Céu v7.2 | Fica parado → Martelo → Void → Céu (Y≥100)")
