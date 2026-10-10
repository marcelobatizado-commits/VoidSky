-- ============================================================
-- VOID ULTRA v13.1
-- Void Y=-500.000.000 | Ceu Y=+500.000.000 | X=0 Z=0
-- Status GUI so aparece no INICIAR (tem X pra fechar)
-- Kill Aura + Anti max + GUIs mais bonitos
-- ============================================================

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local TOOL_NAME = "SledgeHammer"

local ok, err = pcall(function()
	local src = game:HttpGet("https://raw.githubusercontent.com/marcelobatizado-commits/VoidSky/3e8d8b67a814686c69551f2f30d0dc2c722a06b4/VoidSky.lua")

	-- Void -500M | Ceu +500M
	src = string.gsub(src, "%-1500000", "-500000000")
	src = string.gsub(src, "16000000", "500000000")
	src = string.gsub(src, "v12 SUPER", "v13.1")
	src = string.gsub(src, "%[VOID v12%]", "[VOID v13.1]")

	local fn, cErr = loadstring(src)
	if not fn then error("Compile: " .. tostring(cErr)) end
	fn()
end)

if not ok then
	warn("[VOID v13.1] ERRO base: " .. tostring(err))
	print("[VOID v13.1] ERRO base: " .. tostring(err))
	return
end

print("[VOID v13.1] base OK | Void -500M | Ceu +500M")

-- ============================================================
-- KILL AURA
-- ============================================================
local killTarget = nil
local killAuraOn = false
local lastAttack = 0

local function getHammer()
	local char = player.Character
	local bp = player:FindFirstChild("Backpack")
	return (char and char:FindFirstChild(TOOL_NAME)) or (bp and bp:FindFirstChild(TOOL_NAME))
end

local function equipHammer()
	local t = getHammer()
	if not t then return nil end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum and t.Parent ~= char then pcall(function() hum:EquipTool(t) end) end
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
	pcall(function() tool:Activate() end)
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

RunService.Heartbeat:Connect(function()
	if not killAuraOn or not killTarget then return end
	if tick() - lastAttack < 0.05 then return end
	lastAttack = tick()
	if not killTarget.Parent then killAuraOn = false killTarget = nil return end
	attackTarget(killTarget)
end)

-- ============================================================
-- ANTI-VOID / ANTI-CEU MAX
-- ============================================================
local function isExtreme(y)
	return y > 100000 or y < -1000
end

local function hardenCharacter(char)
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	pcall(function() workspace.FallenPartsDestroyHeight = 0 / 0 end)
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
	if not root or not isExtreme(root.Position.Y) then return end
	pcall(function()
		local p = root.Position
		if math.abs(p.Y) > 1000000 then p = Vector3.new(0, p.Y, 0) end
		local upright = CFrame.new(p)
		char:PivotTo(upright)
		root.CFrame = upright
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end)
	for _, part in ipairs(char:GetDescendants()) do
		pcall(function()
			if part:IsA("BasePart") or part:IsA("MeshPart") then
				part.LocalTransparencyModifier = 0
				if part:IsA("BasePart") then part.CanCollide = false end
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
	hardenCharacter(player.Character)
end)
RunService.Heartbeat:Connect(function() hardenCharacter(player.Character) end)
RunService.Stepped:Connect(function() hardenCharacter(player.Character) end)
player.CharacterAdded:Connect(function(char) task.wait(0.2) hardenCharacter(char) end)

-- ============================================================
-- STATUS GUI (so no INICIAR, com X)
-- ============================================================
local statusGui = nil
local statusVisible = false

local function destroyStatus()
	if statusGui then statusGui:Destroy() statusGui = nil end
	statusVisible = false
end

local function showStatus()
	if statusVisible and statusGui and statusGui.Parent then return end
	destroyStatus()

	local pg = player:WaitForChild("PlayerGui")
	local sg = Instance.new("ScreenGui")
	sg.Name = "VoidSkyStatus"
	sg.ResetOnSpawn = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent = pg
	statusGui = sg
	statusVisible = true

	local frame = Instance.new("Frame")
	frame.Name = "Card"
	frame.Size = UDim2.fromOffset(0, 0)
	frame.Position = UDim2.new(1, -16, 0, 16)
	frame.AnchorPoint = Vector2.new(1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(14, 14, 24)
	frame.BackgroundTransparency = 0.08
	frame.BorderSizePixel = 0
	frame.ClipsDescendants = true
	frame.Parent = sg
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)
	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = Color3.fromRGB(150, 140, 255)
	stroke.Thickness = 1.3
	stroke.Transparency = 0.25

	-- animacao de entrada
	TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Back), {
		Size = UDim2.fromOffset(210, 128)
	}):Play()

	local modeLbl = Instance.new("TextLabel")
	modeLbl.Size = UDim2.new(1, -40, 0, 26)
	modeLbl.Position = UDim2.fromOffset(10, 6)
	modeLbl.BackgroundTransparency = 1
	modeLbl.Text = "MODO: --"
	modeLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	modeLbl.TextSize = 15
	modeLbl.Font = Enum.Font.GothamBold
	modeLbl.TextXAlignment = Enum.TextXAlignment.Left
	modeLbl.Parent = frame

	-- botao X
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.fromOffset(26, 26)
	closeBtn.Position = UDim2.new(1, -30, 0, 6)
	closeBtn.BackgroundColor3 = Color3.fromRGB(220, 55, 70)
	closeBtn.BackgroundTransparency = 0.1
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.TextSize = 13
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.BorderSizePixel = 0
	closeBtn.AutoButtonColor = false
	closeBtn.Parent = frame
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
	closeBtn.MouseButton1Click:Connect(function()
		local t = TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.fromOffset(0, 0)
		})
		t:Play()
		t.Completed:Wait()
		destroyStatus()
	end)
	closeBtn.MouseEnter:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(255, 80, 90)}):Play()
	end)
	closeBtn.MouseLeave:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(220, 55, 70)}):Play()
	end)

	local infoLbl = Instance.new("TextLabel")
	infoLbl.Size = UDim2.new(1, -16, 0, 88)
	infoLbl.Position = UDim2.fromOffset(10, 36)
	infoLbl.BackgroundTransparency = 1
	infoLbl.Text = "..."
	infoLbl.TextColor3 = Color3.fromRGB(200, 205, 230)
	infoLbl.TextSize = 12
	infoLbl.Font = Enum.Font.Gotham
	infoLbl.TextXAlignment = Enum.TextXAlignment.Left
	infoLbl.TextYAlignment = Enum.TextYAlignment.Top
	infoLbl.Parent = frame

	local fps, frames, lastFps = 60, 0, tick()
	local fpsConn = RunService.RenderStepped:Connect(function()
		frames = frames + 1
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

		local mode, modeColor = "MAPA", Color3.fromRGB(180, 180, 200)
		if y <= -1000000 then
			mode, modeColor = "⬇  VOID", Color3.fromRGB(150, 100, 255)
		elseif y >= 1000000 then
			mode, modeColor = "⬆  CEU", Color3.fromRGB(80, 210, 255)
		end
		modeLbl.Text = mode
		modeLbl.TextColor3 = modeColor

		local ka = killAuraOn and killTarget and ("ON → " .. killTarget.Name) or "OFF"
		infoLbl.Text = string.format(
			"Y: %s\nX: %d   Z: %d\nFPS: %d   Ping: %dms\nKill Aura: %s",
			tostring(math.floor(y)), x, z, fps, ping, ka
		)
	end)
end

-- ============================================================
-- HOOK GUI principal: INICIAR / nomes / polish
-- ============================================================
task.spawn(function()
	local pg = player:WaitForChild("PlayerGui")
	local gui = pg:WaitForChild("VoidSkyUltra", 25)
	if not gui then return end
	local main = gui:FindFirstChildOfClass("Frame")

	-- polish main
	if main then
		pcall(function()
			main.BackgroundColor3 = Color3.fromRGB(14, 14, 24)
			main.BackgroundTransparency = 0.05
			local c = main:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", main)
			c.CornerRadius = UDim.new(0, 16)
			local s = main:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", main)
			s.Color = Color3.fromRGB(160, 150, 255)
			s.Thickness = 1.4
			s.Transparency = 0.25
		end)
	end

	local function hook()
		for _, d in ipairs(gui:GetDescendants()) do
			if d:IsA("TextButton") then
				local txt, up = d.Text or "", string.upper(d.Text or "")

				-- nome de player = kill aura
				local plr = Players:FindFirstChild(txt)
				if plr and plr ~= player and not d:GetAttribute("V13KillHook") then
					d:SetAttribute("V13KillHook", true)
					d.MouseButton1Click:Connect(function()
						killTarget = plr
						killAuraOn = true
						print("[VOID v13.1] Kill Aura -> " .. plr.Name)
					end)
				end

				-- INICIAR = mostra status
				if (up == "INICIAR" or up == "START") and not up:find("CAIXA") and not d:GetAttribute("V13StartStatus") then
					d:SetAttribute("V13StartStatus", true)
					d.MouseButton1Click:Connect(function()
						task.defer(showStatus)
					end)
				end

				-- CONFIRMAR tambem
				if (up == "CONFIRMAR" or up == "CONFIRM") and not d:GetAttribute("V13ConfirmStatus") then
					d:SetAttribute("V13ConfirmStatus", true)
					d.MouseButton1Click:Connect(function()
						task.defer(showStatus)
						task.delay(0.15, function()
							if killTarget then killAuraOn = true end
						end)
					end)
				end

				-- PARAR esconde status
				if (up == "PARAR" or up == "STOP") and not up:find("CAIXA") and not d:GetAttribute("V13StopStatus") then
					d:SetAttribute("V13StopStatus", true)
					d.MouseButton1Click:Connect(function()
						destroyStatus()
						killAuraOn = false
					end)
				end
			end
		end
	end

	hook()
	gui.DescendantAdded:Connect(function() task.defer(hook) end)
end)

print("[VOID v13.1] pronto | status so no INICIAR | Void -500M | Ceu +500M")
