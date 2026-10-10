-- ============================================================
-- VOID ULTRA V17
-- Void Y=-725.000.000 | Ceu Y=+725.000.000 | X=0 Z=0
-- Kill Aura | Status GUI | Confirm close | Anti MAX
-- made by fickus
-- ============================================================

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local TOOL_NAME = "SledgeHammer"
local POS_BEFORE = nil

local ok, err = pcall(function()
	local src = game:HttpGet("https://raw.githubusercontent.com/marcelobatizado-commits/VoidSky/3e8d8b67a814686c69551f2f30d0dc2c722a06b4/VoidSky.lua")

	-- Void -725M | Ceu +725M | trigger Y>=30
	src = string.gsub(src, "%-1500000", "-725000000")
	src = string.gsub(src, "16000000", "725000000")
	src = string.gsub(src, "HEIGHT_TRIGGER = 100", "HEIGHT_TRIGGER = 30")
	src = string.gsub(src, "v12 SUPER", "V17")
	src = string.gsub(src, "%[VOID v12%]", "[VOID V17]")

	local fn, cErr = loadstring(src)
	if not fn then error("Compile: " .. tostring(cErr)) end
	fn()
end)
if not ok then
	warn("[VOID V17] ERRO: " .. tostring(err))
	print("[VOID V17] ERRO: " .. tostring(err))
	return
end
print("[VOID V17] base OK | Void -725M | Ceu +725M")

-- ---------- KILL AURA ----------
local killTarget, killAuraOn = nil, false

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

local function attackTarget(target)
	if not target or not target.Character then return end
	local tChar = target.Character
	local tRoot = tChar:FindFirstChild("HumanoidRootPart")
	local tHum = tChar:FindFirstChildOfClass("Humanoid")
	if not tRoot or not tHum or tHum.Health <= 0 then return end
	local tool = equipHammer()
	if not tool then return end
	local handle = tool:FindFirstChild("Handle")
	for _ = 1, 6 do pcall(function() tool:Activate() end) end
	if handle and firetouchinterest then
		for _, part in ipairs(tChar:GetChildren()) do
			if part:IsA("BasePart") then
				pcall(function()
					firetouchinterest(handle, part, 0)
					firetouchinterest(handle, part, 1)
				end)
			end
		end
		pcall(function()
			firetouchinterest(handle, tRoot, 0)
			firetouchinterest(handle, tRoot, 1)
		end)
	end
end

local function killLoop()
	if not killAuraOn or not killTarget then return end
	if not killTarget.Parent then killAuraOn = false killTarget = nil return end
	attackTarget(killTarget)
end
RunService.Heartbeat:Connect(killLoop)
RunService.Stepped:Connect(killLoop)
RunService.RenderStepped:Connect(killLoop)

-- ---------- ANTI VOID/CEU MAX ----------
local function harden(char)
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	pcall(function() workspace.FallenPartsDestroyHeight = 0/0 end)
	if hum then
		pcall(function()
			hum.MaxHealth = math.max(hum.MaxHealth, 9e9)
			hum.Health = hum.MaxHealth
			hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
			hum.BreakJointsOnDeath = false
		end)
	end
	if not root then return end
	local y = root.Position.Y
	if y <= 100000 and y >= -1000 then return end
	pcall(function()
		local p = root.Position
		if math.abs(p.Y) > 1000000 then p = Vector3.new(0, p.Y, 0) end
		local up = CFrame.new(p)
		char:PivotTo(up)
		root.CFrame = up
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end)
	for _, p in ipairs(char:GetDescendants()) do
		pcall(function()
			if p:IsA("BasePart") or p:IsA("MeshPart") then
				p.LocalTransparencyModifier = 0
				if p:IsA("BasePart") then p.CanCollide = false end
			end
		end)
	end
	pcall(function()
		local cam = workspace.CurrentCamera
		if cam and hum then cam.CameraSubject = hum end
	end)
end

pcall(function() RunService:UnbindFromRenderStep("VoidSkyAntiUltra") end)
RunService:BindToRenderStep("VoidSkyAntiUltra", Enum.RenderPriority.Last.Value, function()
	harden(player.Character)
end)
RunService.Heartbeat:Connect(function() harden(player.Character) end)
RunService.Stepped:Connect(function() harden(player.Character) end)
player.CharacterAdded:Connect(function(c) task.wait(0.2) harden(c) end)

-- ---------- STATUS GUI ----------
local statusGui, statusVisible = nil, false
local function destroyStatus()
	if statusGui then pcall(function() statusGui:Destroy() end) end
	statusGui, statusVisible = nil, false
end

local function showStatus()
	if statusVisible and statusGui and statusGui.Parent then return end
	destroyStatus()
	local pg = player:WaitForChild("PlayerGui")
	local sg = Instance.new("ScreenGui")
	sg.Name = "VoidSkyStatus"
	sg.ResetOnSpawn = false
	sg.Parent = pg
	statusGui = sg
	statusVisible = true

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(0, 0)
	frame.Position = UDim2.new(1, -14, 0, 14)
	frame.AnchorPoint = Vector2.new(1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(12, 12, 22)
	frame.BackgroundTransparency = 0.05
	frame.BorderSizePixel = 0
	frame.ClipsDescendants = true
	frame.Parent = sg
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)
	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = Color3.fromRGB(150, 140, 255)
	stroke.Thickness = 1.3
	TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = UDim2.fromOffset(220, 138)}):Play()

	local modeLbl = Instance.new("TextLabel")
	modeLbl.Size = UDim2.new(1, -42, 0, 26)
	modeLbl.Position = UDim2.fromOffset(10, 6)
	modeLbl.BackgroundTransparency = 1
	modeLbl.Text = "MODO: --"
	modeLbl.Font = Enum.Font.GothamBold
	modeLbl.TextSize = 15
	modeLbl.TextColor3 = Color3.new(1,1,1)
	modeLbl.TextXAlignment = Enum.TextXAlignment.Left
	modeLbl.Parent = frame

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.fromOffset(26, 26)
	closeBtn.Position = UDim2.new(1, -30, 0, 6)
	closeBtn.BackgroundColor3 = Color3.fromRGB(220, 55, 70)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.new(1,1,1)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 13
	closeBtn.BorderSizePixel = 0
	closeBtn.Parent = frame
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
	closeBtn.MouseButton1Click:Connect(function()
		local t = TweenService:Create(frame, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.fromOffset(0,0)})
		t:Play() t.Completed:Wait() destroyStatus()
	end)

	local infoLbl = Instance.new("TextLabel")
	infoLbl.Size = UDim2.new(1, -16, 0, 70)
	infoLbl.Position = UDim2.fromOffset(10, 34)
	infoLbl.BackgroundTransparency = 1
	infoLbl.Font = Enum.Font.Gotham
	infoLbl.TextSize = 12
	infoLbl.TextColor3 = Color3.fromRGB(200, 205, 230)
	infoLbl.TextXAlignment = Enum.TextXAlignment.Left
	infoLbl.TextYAlignment = Enum.TextYAlignment.Top
	infoLbl.TextWrapped = true
	infoLbl.Parent = frame

	local credit = Instance.new("TextLabel")
	credit.Size = UDim2.new(1, -12, 0, 14)
	credit.Position = UDim2.new(0, 6, 1, -18)
	credit.BackgroundTransparency = 1
	credit.Text = "made by fickus"
	credit.Font = Enum.Font.Gotham
	credit.TextSize = 10
	credit.TextColor3 = Color3.fromRGB(120, 120, 150)
	credit.TextXAlignment = Enum.TextXAlignment.Right
	credit.Parent = frame

	local fps, frames, lastFps = 60, 0, tick()
	local fpsConn = RunService.RenderStepped:Connect(function()
		frames += 1
		if tick() - lastFps >= 1 then fps = frames frames = 0 lastFps = tick() end
	end)
	local hbConn
	hbConn = RunService.Heartbeat:Connect(function()
		if not statusGui or not statusGui.Parent then
			if fpsConn then fpsConn:Disconnect() end
			if hbConn then hbConn:Disconnect() end
			return
		end
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local y = root and root.Position.Y or 0
		local x = root and math.floor(root.Position.X) or 0
		local z = root and math.floor(root.Position.Z) or 0
		local ping = 0
		pcall(function()
			local item = Stats.Network.ServerStatsItem["Data Ping"]
			if item then ping = math.floor(item:GetValue()) end
		end)
		local mode, col = "MAPA", Color3.fromRGB(180,180,200)
		if y <= -1000000 then mode, col = "⬇  VOID", Color3.fromRGB(160, 110, 255)
		elseif y >= 1000000 then mode, col = "⬆  CEU", Color3.fromRGB(80, 210, 255) end
		modeLbl.Text = mode
		modeLbl.TextColor3 = col
		local ka = killAuraOn and killTarget and ("ON → " .. killTarget.Name) or "OFF"
		infoLbl.Text = string.format("Y: %s\nX: %d   Z: %d\nFPS: %d   Ping: %dms\nKill Aura: %s", tostring(math.floor(y)), x, z, fps, ping, ka)
	end)
end

local function returnToMap()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root and POS_BEFORE then
		pcall(function() RunService:UnbindFromRenderStep("VoidSkyHold") end)
		for i = 1, 15 do
			pcall(function()
				player.Character:PivotTo(POS_BEFORE)
				root.CFrame = POS_BEFORE
				root.AssemblyLinearVelocity = Vector3.zero
			end)
			task.wait()
		end
	end
	killAuraOn = false
end

-- ---------- HOOK GUI ----------
task.spawn(function()
	local pg = player:WaitForChild("PlayerGui")
	local gui = pg:WaitForChild("VoidSkyUltra", 25)
	if not gui then return end
	local main = gui:FindFirstChildOfClass("Frame")
	if not main then return end

	pcall(function()
		main.ClipsDescendants = true
		main.BackgroundColor3 = Color3.fromRGB(12, 12, 22)
		if main.Size.X.Offset < 300 then main.Size = UDim2.fromOffset(320, math.max(main.Size.Y.Offset, 420)) end
		local c = main:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", main)
		c.CornerRadius = UDim.new(0, 16)
		local s = main:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", main)
		s.Color = Color3.fromRGB(150, 140, 255)
		s.Thickness = 1.5
	end)

	if not main:FindFirstChild("FickusCredit") then
		local cr = Instance.new("TextLabel")
		cr.Name = "FickusCredit"
		cr.Size = UDim2.new(1, -16, 0, 16)
		cr.Position = UDim2.new(0, 8, 1, -20)
		cr.BackgroundTransparency = 1
		cr.Text = "made by fickus"
		cr.Font = Enum.Font.Gotham
		cr.TextSize = 11
		cr.TextColor3 = Color3.fromRGB(130, 130, 160)
		cr.TextXAlignment = Enum.TextXAlignment.Center
		cr.ZIndex = 10
		cr.Parent = main
	end

	local overlay = Instance.new("Frame")
	overlay.Name = "CloseConfirm"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
	overlay.BackgroundTransparency = 0.45
	overlay.Visible = false
	overlay.ZIndex = 50
	overlay.Parent = main
	Instance.new("UICorner", overlay).CornerRadius = UDim.new(0, 16)

	local box = Instance.new("Frame")
	box.Size = UDim2.fromOffset(260, 130)
	box.Position = UDim2.new(0.5, -130, 0.5, -65)
	box.BackgroundColor3 = Color3.fromRGB(18, 18, 30)
	box.BorderSizePixel = 0
	box.ZIndex = 51
	box.Parent = overlay
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 14)

	local q = Instance.new("TextLabel")
	q.Size = UDim2.new(1, -20, 0, 50)
	q.Position = UDim2.fromOffset(10, 12)
	q.BackgroundTransparency = 1
	q.Text = "Você tem certeza que deseja\nfechar esse GUI?"
	q.Font = Enum.Font.GothamBold
	q.TextSize = 14
	q.TextColor3 = Color3.fromRGB(240, 240, 255)
	q.TextWrapped = true
	q.ZIndex = 52
	q.Parent = box

	local yesBtn = Instance.new("TextButton")
	yesBtn.Size = UDim2.fromOffset(100, 34)
	yesBtn.Position = UDim2.fromOffset(20, 78)
	yesBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 95)
	yesBtn.Text = "Sim"
	yesBtn.Font = Enum.Font.GothamBold
	yesBtn.TextSize = 14
	yesBtn.TextColor3 = Color3.new(1,1,1)
	yesBtn.BorderSizePixel = 0
	yesBtn.ZIndex = 52
	yesBtn.Parent = box
	Instance.new("UICorner", yesBtn).CornerRadius = UDim.new(0, 10)

	local noBtn = Instance.new("TextButton")
	noBtn.Size = UDim2.fromOffset(100, 34)
	noBtn.Position = UDim2.fromOffset(140, 78)
	noBtn.BackgroundColor3 = Color3.fromRGB(220, 55, 70)
	noBtn.Text = "Não"
	noBtn.Font = Enum.Font.GothamBold
	noBtn.TextSize = 14
	noBtn.TextColor3 = Color3.new(1,1,1)
	noBtn.BorderSizePixel = 0
	noBtn.ZIndex = 52
	noBtn.Parent = box
	Instance.new("UICorner", noBtn).CornerRadius = UDim.new(0, 10)

	noBtn.MouseButton1Click:Connect(function() overlay.Visible = false end)
	yesBtn.MouseButton1Click:Connect(function()
	overlay.Visible = false
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local y = root and root.Position.Y or 0
		if math.abs(y) > 1000000 then returnToMap() end
		killAuraOn = false
		destroyStatus()
		local t = TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.fromOffset(0,0), BackgroundTransparency = 1
		})
		t:Play() t.Completed:Wait()
		pcall(function() gui:Destroy() end)
	end)

	if not main:FindFirstChild("V15MainClose") then
		local xc = Instance.new("TextButton")
		xc.Name = "V15MainClose"
		xc.Size = UDim2.fromOffset(28, 28)
		xc.Position = UDim2.new(1, -34, 0, 6)
		xc.BackgroundColor3 = Color3.fromRGB(220, 55, 70)
		xc.Text = "X"
		xc.TextColor3 = Color3.new(1,1,1)
		xc.Font = Enum.Font.GothamBold
		xc.TextSize = 14
		xc.BorderSizePixel = 0
		xc.ZIndex = 20
		xc.Parent = main
		Instance.new("UICorner", xc).CornerRadius = UDim.new(0, 8)
		xc.MouseButton1Click:Connect(function() overlay.Visible = true end)
	end

	local function hookAll()
		for _, d in ipairs(gui:GetDescendants()) do
			if d:IsA("TextButton") then
				local txt, up = d.Text or "", string.upper(d.Text or "")
				local plr = Players:FindFirstChild(txt)
				if plr and plr ~= player and not d:GetAttribute("V17Kill") then
					d:SetAttribute("V17Kill", true)
					d.MouseButton1Click:Connect(function()
						killTarget = plr
						killAuraOn = true
						print("[V17] Kill Aura -> " .. plr.Name)
					end)
				end
				if (up == "INICIAR" or up == "START") and not up:find("CAIXA") and not d:GetAttribute("V17Start") then
					d:SetAttribute("V17Start", true)
					d.MouseButton1Click:Connect(function()
						local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
						if root then POS_BEFORE = root.CFrame end
						task.defer(showStatus)
					end)
				end
				if (up == "CONFIRMAR" or up == "CONFIRM") and not d:GetAttribute("V17Confirm") then
					d:SetAttribute("V17Confirm", true)
					d.MouseButton1Click:Connect(function()
						local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
						if root and not POS_BEFORE then POS_BEFORE = root.CFrame end
						task.defer(showStatus)
						if killTarget then killAuraOn = true end
					end)
				end
				if (up == "PARAR" or up == "STOP") and not up:find("CAIXA") and not d:GetAttribute("V17Stop") then
					d:SetAttribute("V17Stop", true)
					d.MouseButton1Click:Connect(function()
						destroyStatus()
						killAuraOn = false
					end)
				end
			end
		end
	end
	hookAll()
	gui.DescendantAdded:Connect(function() task.defer(hookAll) end)
end)

print("[VOID V17] made by fickus | Void+Ceu | Kill Aura | bugs corrigidos")
