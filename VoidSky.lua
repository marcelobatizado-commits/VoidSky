-- ============================================================
-- VOID ULTRA v13
-- Void Y=-100.000.000 | Ceu Y=+125.000.000 | X=0 Z=0
-- Kill Aura auto no alvo do martelo + knockback max
-- Anti-void/ceu MAXIMO + Status GUI (ping/fps/coords/modo)
-- ============================================================

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")
local player = Players.LocalPlayer

local TOOL_NAME = "SledgeHammer"

local ok, err = pcall(function()
	local src = game:HttpGet("https://raw.githubusercontent.com/marcelobatizado-commits/VoidSky/3e8d8b67a814686c69551f2f30d0dc2c722a06b4/VoidSky.lua")

	-- Void -100M | Ceu +125M
	src = string.gsub(src, "%-1500000", "-100000000")
	src = string.gsub(src, "16000000", "125000000")
	src = string.gsub(src, "v12 SUPER", "v13")
	src = string.gsub(src, "%[VOID v12%]", "[VOID v13]")

	local fn, cErr = loadstring(src)
	if not fn then error("Compile: " .. tostring(cErr)) end
	fn()
end)

if not ok then
	warn("[VOID v13] ERRO base: " .. tostring(err))
	print("[VOID v13] ERRO base: " .. tostring(err))
	return
end

print("[VOID v13] base OK | Void -100M | Ceu +125M")

-- ============================================================
-- KILL AURA + STATUS + ANTI MAX
-- ============================================================

local killTarget = nil -- Player
local killAuraOn = false
local lastAttack = 0

local function getHammer()
	local char = player.Character
	local bp = player:FindFirstChild("Backpack")
	local t = char and char:FindFirstChild(TOOL_NAME)
	if t then return t end
	t = bp and bp:FindFirstChild(TOOL_NAME)
	return t
end

local function equipHammer()
	local t = getHammer()
	if not t then return nil end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return t end
	if t.Parent ~= char then
		pcall(function() hum:EquipTool(t) end)
	end
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

	-- ativa a tool varias vezes (dano + knockback do martelo no Y extremo)
	pcall(function() tool:Activate() end)

	-- firetouchinterest se existir (handle x corpo do alvo)
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

	-- reforco: simula hit no root
	if handle and tRoot and firetouchinterest then
		pcall(function()
			firetouchinterest(handle, tRoot, 0)
			firetouchinterest(handle, tRoot, 1)
		end)
	end
end

-- loop kill aura (muito rapido)
RunService.Heartbeat:Connect(function()
	if not killAuraOn or not killTarget then return end
	if tick() - lastAttack < 0.05 then return end -- ~20 hits/s
	lastAttack = tick()
	if not killTarget.Parent then
		killAuraOn = false
		killTarget = nil
		return
	end
	attackTarget(killTarget)
end)

-- detecta clique no nome na GUI do VoidSky = ativa kill aura
task.spawn(function()
	local pg = player:WaitForChild("PlayerGui")
	local gui = pg:WaitForChild("VoidSkyUltra", 25)
	if not gui then return end

	local function hookPlayerButtons()
		for _, d in ipairs(gui:GetDescendants()) do
			if d:IsA("TextButton") and not d:GetAttribute("V13KillHook") then
				local plr = Players:FindFirstChild(d.Text or "")
				if plr and plr ~= player then
					d:SetAttribute("V13KillHook", true)
					d.MouseButton1Click:Connect(function()
						killTarget = plr
						killAuraOn = true
						print("[VOID v13] Kill Aura ON -> " .. plr.Name)
					end)
				end
			end
		end
	end
	hookPlayerButtons()
	gui.DescendantAdded:Connect(function() task.defer(hookPlayerButtons) end)

	-- CONFIRMAR / INICIAR tambem pega alvo do titulo se existir
	for _, d in ipairs(gui:GetDescendants()) do
		if d:IsA("TextButton") then
			local up = string.upper(d.Text or "")
			if (up == "CONFIRMAR" or up == "INICIAR" or up == "START") and not d:GetAttribute("V13ConfirmKill") then
				d:SetAttribute("V13ConfirmKill", true)
				d.MouseButton1Click:Connect(function()
					task.delay(0.15, function()
						if killTarget then
							killAuraOn = true
						end
					end)
				end)
			end
		end
	end
end)

-- ============================================================
-- ANTI-VOID / ANTI-CEU MAXIMO
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
			hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
			hum.BreakJointsOnDeath = false
		end)
	end

	if not root then return end
	if not isExtreme(root.Position.Y) then return end

	-- anti-torto + trava X/Z em extremos do script
	pcall(function()
		local p = root.Position
		if math.abs(p.Y) > 1000000 then
			p = Vector3.new(0, p.Y, 0)
		end
		local upright = CFrame.new(p)
		char:PivotTo(upright)
		root.CFrame = upright
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end)

	-- anti-invisivel
	for _, part in ipairs(char:GetDescendants()) do
		pcall(function()
			if part:IsA("BasePart") then
				part.LocalTransparencyModifier = 0
				part.CanCollide = false
			elseif part:IsA("MeshPart") then
				part.LocalTransparencyModifier = 0
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

player.CharacterAdded:Connect(function(char)
	task.wait(0.2)
	hardenCharacter(char)
end)

-- ============================================================
-- STATUS GUI (ping, fps, coords, VOID/CEU)
-- ============================================================
task.spawn(function()
	local pg = player:WaitForChild("PlayerGui")
	-- remove antigo
	local old = pg:FindFirstChild("VoidSkyStatus")
	if old then old:Destroy() end

	local sg = Instance.new("ScreenGui")
	sg.Name = "VoidSkyStatus"
	sg.ResetOnSpawn = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent = pg

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(200, 110)
	frame.Position = UDim2.new(1, -212, 0, 12)
	frame.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel = 0
	frame.Parent = sg
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
	local st = Instance.new("UIStroke", frame)
	st.Color = Color3.fromRGB(140, 130, 255)
	st.Thickness = 1.2
	st.Transparency = 0.3

	local modeLbl = Instance.new("TextLabel")
	modeLbl.Size = UDim2.new(1, -12, 0, 28)
	modeLbl.Position = UDim2.fromOffset(6, 4)
	modeLbl.BackgroundTransparency = 1
	modeLbl.Text = "MODO: --"
	modeLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	modeLbl.TextSize = 16
	modeLbl.Font = Enum.Font.GothamBold
	modeLbl.TextXAlignment = Enum.TextXAlignment.Left
	modeLbl.Parent = frame

	local infoLbl = Instance.new("TextLabel")
	infoLbl.Size = UDim2.new(1, -12, 0, 72)
	infoLbl.Position = UDim2.fromOffset(6, 34)
	infoLbl.BackgroundTransparency = 1
	infoLbl.Text = "..."
	infoLbl.TextColor3 = Color3.fromRGB(200, 205, 230)
	infoLbl.TextSize = 12
	infoLbl.Font = Enum.Font.Gotham
	infoLbl.TextXAlignment = Enum.TextXAlignment.Left
	infoLbl.TextYAlignment = Enum.TextYAlignment.Top
	infoLbl.Parent = frame

	local fps = 60
	local frames = 0
	local lastFps = tick()
	RunService.RenderStepped:Connect(function()
		frames = frames + 1
		if tick() - lastFps >= 1 then
			fps = frames
			frames = 0
			lastFps = tick()
		end
	end)

	RunService.Heartbeat:Connect(function()
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local y = root and root.Position.Y or 0
		local x = root and math.floor(root.Position.X) or 0
		local z = root and math.floor(root.Position.Z) or 0
		local ping = 0
		pcall(function()
			local item = Stats.Network.ServerStatsItem["Data Ping"]
			if item then ping = math.floor(item:GetValue()) end
		end)

		local mode = "MAPA"
		local modeColor = Color3.fromRGB(180, 180, 200)
		if y <= -1000000 then
			mode = "⬇ VOID"
			modeColor = Color3.fromRGB(120, 80, 255) -- roxo
		elseif y >= 1000000 then
			mode = "⬆ CEU"
			modeColor = Color3.fromRGB(80, 200, 255) -- azul ceu
		end

		modeLbl.Text = mode
		modeLbl.TextColor3 = modeColor

		local ka = killAuraOn and killTarget and ("ON -> " .. killTarget.Name) or "OFF"
		infoLbl.Text = string.format(
			"Y: %s\nX: %d  Z: %d\nFPS: %d  |  Ping: %dms\nKill Aura: %s",
			tostring(math.floor(y)),
			x, z,
			fps, ping,
			ka
		)
	end)
end)

print("[VOID v13] Kill Aura + Status GUI + Anti MAX prontos")
