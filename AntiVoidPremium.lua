-- Anti Void Premium v2 (aprimorado)
-- Base: seu script | Melhorias: NaN void, estados bloqueados, CharacterAdded, drag mobile, GUI melhor

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("VoidPremiumGUI") then
	playerGui.VoidPremiumGUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VoidPremiumGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = playerGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.fromOffset(340, 250)
MainFrame.Position = UDim2.new(0.5, -170, 0.32, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)

local stroke = Instance.new("UIStroke", MainFrame)
stroke.Color = Color3.fromRGB(255, 70, 70)
stroke.Thickness = 1.5
stroke.Transparency = 0.25

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 44)
TitleBar.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 14)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -90, 1, 0)
Title.Position = UDim2.fromOffset(14, 0)
Title.BackgroundTransparency = 1
Title.Text = "VOID CONTROL v2"
Title.TextColor3 = Color3.fromRGB(255, 90, 90)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.fromOffset(28, 28)
CloseBtn.Position = UDim2.new(1, -36, 0.5, -14)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 45, 45)
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.TextSize = 16
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 7)

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.fromOffset(28, 28)
MinBtn.Position = UDim2.new(1, -70, 0.5, -14)
MinBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
MinBtn.Text = "−"
MinBtn.TextColor3 = Color3.new(1, 1, 1)
MinBtn.TextSize = 16
MinBtn.Font = Enum.Font.GothamBold
MinBtn.BorderSizePixel = 0
MinBtn.AutoButtonColor = false
MinBtn.Parent = TitleBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 7)

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, 0, 1, -44)
Content.Position = UDim2.fromOffset(0, 44)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

local AntiVoidBtn = Instance.new("TextButton")
AntiVoidBtn.Size = UDim2.new(0.88, 0, 0, 48)
AntiVoidBtn.Position = UDim2.new(0.06, 0, 0.08, 0)
AntiVoidBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 90)
AntiVoidBtn.Text = "ANTI VOID: ATIVADO"
AntiVoidBtn.TextColor3 = Color3.new(1, 1, 1)
AntiVoidBtn.TextSize = 16
AntiVoidBtn.Font = Enum.Font.GothamBold
AntiVoidBtn.BorderSizePixel = 0
AntiVoidBtn.AutoButtonColor = false
AntiVoidBtn.Parent = Content
Instance.new("UICorner", AntiVoidBtn).CornerRadius = UDim.new(0, 10)

local GodModeBtn = Instance.new("TextButton")
GodModeBtn.Size = UDim2.new(0.88, 0, 0, 48)
GodModeBtn.Position = UDim2.new(0.06, 0, 0.38, 0)
GodModeBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 90)
GodModeBtn.Text = "GOD MODE: ATIVADO"
GodModeBtn.TextColor3 = Color3.new(1, 1, 1)
GodModeBtn.TextSize = 16
GodModeBtn.Font = Enum.Font.GothamBold
GodModeBtn.BorderSizePixel = 0
GodModeBtn.AutoButtonColor = false
GodModeBtn.Parent = Content
Instance.new("UICorner", GodModeBtn).CornerRadius = UDim.new(0, 10)

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(0.9, 0, 0, 36)
Status.Position = UDim2.new(0.05, 0, 0.72, 0)
Status.BackgroundTransparency = 1
Status.Text = "Anti-Void + God Mode ativos\nPode cair sem morrer"
Status.TextColor3 = Color3.fromRGB(100, 255, 140)
Status.TextSize = 13
Status.Font = Enum.Font.Gotham
Status.TextYAlignment = Enum.TextYAlignment.Top
Status.Parent = Content

-- Estado
local antiVoidEnabled = true
local godModeEnabled = true
local antiConn = nil
local godConn = nil
local steppedConn = nil
local charConn = nil

local function setFallenHeight()
	-- NaN desativa o kill do void (bypass do limite -50000..50000)
	pcall(function()
		workspace.FallenPartsDestroyHeight = 0 / 0
	end)
	pcall(function()
		if workspace.FallenPartsDestroyHeight == workspace.FallenPartsDestroyHeight then
			-- se não ficou NaN, tenta -math.huge
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

local function startAntiVoid()
	if antiConn then return end
	setFallenHeight()

	antiConn = RunService.Heartbeat:Connect(function()
		if not antiVoidEnabled then return end
		setFallenHeight()
		local char = player.Character
		if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not root or not hum then return end

		-- sempre protege no void (Y baixo)
		if root.Position.Y < -200 then
			applyHumanoidProtect(hum)
			pcall(function()
				root.AssemblyLinearVelocity = Vector3.new(
					root.AssemblyLinearVelocity.X,
					math.max(root.AssemblyLinearVelocity.Y, -50),
					root.AssemblyLinearVelocity.Z
				)
			end)
		end
	end)

	steppedConn = RunService.Stepped:Connect(function()
		if not antiVoidEnabled then return end
		local char = player.Character
		if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum and char:FindFirstChild("HumanoidRootPart") and char.HumanoidRootPart.Position.Y < -200 then
			applyHumanoidProtect(hum)
		end
	end)
end

local function stopAntiVoid()
	if antiConn then antiConn:Disconnect() antiConn = nil end
	if steppedConn then steppedConn:Disconnect() steppedConn = nil end
	-- não reseta FallenPartsDestroyHeight pra não matar se estiver no void
end

local function startGodMode()
	if godConn then return end
	godConn = RunService.Heartbeat:Connect(function()
		if not godModeEnabled then return end
		local char = player.Character
		if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then applyHumanoidProtect(hum) end
	end)
end

local function stopGodMode()
	if godConn then godConn:Disconnect() godConn = nil end
	local char = player.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			pcall(function()
				hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
				hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
				hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
			end)
		end
	end
end

local function updateStatus()
	if antiVoidEnabled and godModeEnabled then
		Status.Text = "Anti-Void + God Mode ativos\nPode cair sem morrer"
		Status.TextColor3 = Color3.fromRGB(100, 255, 140)
	elseif antiVoidEnabled then
		Status.Text = "Só Anti-Void ativo"
		Status.TextColor3 = Color3.fromRGB(255, 200, 80)
	elseif godModeEnabled then
		Status.Text = "Só God Mode ativo"
		Status.TextColor3 = Color3.fromRGB(255, 200, 80)
	else
		Status.Text = "Tudo desativado"
		Status.TextColor3 = Color3.fromRGB(255, 100, 100)
	end
end

AntiVoidBtn.MouseButton1Click:Connect(function()
	antiVoidEnabled = not antiVoidEnabled
	if antiVoidEnabled then
		AntiVoidBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 90)
		AntiVoidBtn.Text = "ANTI VOID: ATIVADO"
		startAntiVoid()
	else
		AntiVoidBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 78)
		AntiVoidBtn.Text = "ANTI VOID: DESATIVADO"
		stopAntiVoid()
	end
	updateStatus()
end)

GodModeBtn.MouseButton1Click:Connect(function()
	godModeEnabled = not godModeEnabled
	if godModeEnabled then
		GodModeBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 90)
		GodModeBtn.Text = "GOD MODE: ATIVADO"
		startGodMode()
	else
		GodModeBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 78)
		GodModeBtn.Text = "GOD MODE: DESATIVADO"
		stopGodMode()
	end
	updateStatus()
end)

-- Drag só pela title bar (melhor no celular)
local dragging, dragStart, startPos, dragInput
TitleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = MainFrame.Position
		local c
		c = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				if c then c:Disconnect() end
			end
		end)
	end
end)
TitleBar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and input == dragInput then
		local d = input.Position - dragStart
		MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end)

local minimized = false
local normalSize = MainFrame.Size
MinBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size = UDim2.fromOffset(340, 44)}):Play()
		Content.Visible = false
		MinBtn.Text = "+"
	else
		Content.Visible = true
		TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size = normalSize}):Play()
		MinBtn.Text = "−"
	end
end)

CloseBtn.MouseButton1Click:Connect(function()
	antiVoidEnabled = false
	godModeEnabled = false
	stopAntiVoid()
	stopGodMode()
	if charConn then charConn:Disconnect() end
	ScreenGui:Destroy()
end)

-- Respawn
charConn = player.CharacterAdded:Connect(function()
	task.wait(0.3)
	if antiVoidEnabled then setFallenHeight() end
	if godModeEnabled then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then applyHumanoidProtect(hum) end
	end
end)

-- Liga tudo
startAntiVoid()
startGodMode()
updateStatus()

print("✅ Anti Void Premium v2 carregado | FallenPartsDestroyHeight = NaN + God Mode")
