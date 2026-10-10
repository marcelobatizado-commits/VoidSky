-- ============================================================
-- VOID ULTRA v12.2
-- Void Y=-50.000.000 | Ceu Y=+100.000.000 | X=0 Z=0
-- Anti-void SUPER + Anti-ceu SUPER (anti-torto + anti-invisivel)
-- ============================================================

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local ok, err = pcall(function()
	local src = game:HttpGet("https://raw.githubusercontent.com/marcelobatizado-commits/VoidSky/3e8d8b67a814686c69551f2f30d0dc2c722a06b4/VoidSky.lua")

	-- Void -50M | Ceu +100M
	src = string.gsub(src, "%-1500000", "-50000000")
	src = string.gsub(src, "16000000", "100000000")
	src = string.gsub(src, "v12 SUPER", "v12.2")
	src = string.gsub(src, "%[VOID v12%]", "[VOID v12.2]")

	local fn, cErr = loadstring(src)
	if not fn then error("Compile: " .. tostring(cErr)) end
	fn()
end)

if not ok then
	warn("[VOID v12.2] ERRO: " .. tostring(err))
	print("[VOID v12.2] ERRO: " .. tostring(err))
	return
end

print("[VOID v12.2] OK | Void Y=-50.000.000 | Ceu Y=+100.000.000")

-- ============================================================
-- ANTI-VOID + ANTI-CEU ULTRA
-- (torto / invisivel / morte em Y extremo)
-- ============================================================

local function isExtreme(y)
	return y > 100000 or y < -1000
end

local function hardenCharacter(char)
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")

	-- anti-morte / anti-void
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
			hum:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
			hum.BreakJointsOnDeath = false
		end)
	end

	if not root then return end
	local y = root.Position.Y
	if not isExtreme(y) then return end

	-- anti-torto: CFrame SEMPRE reto (sem rotacao)
	pcall(function()
		local p = root.Position
		-- trava X=0 Z=0 se estiver no void/ceu do script (muito extremo)
		if math.abs(p.Y) > 1000000 then
			p = Vector3.new(0, p.Y, 0)
		end
		local upright = CFrame.new(p)
		char:PivotTo(upright)
		root.CFrame = upright
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end)

	-- anti-invisivel: forca todas as partes visiveis no cliente
	for _, part in ipairs(char:GetDescendants()) do
		pcall(function()
			if part:IsA("BasePart") then
				part.LocalTransparencyModifier = 0
				if part.Transparency > 0.9 and part.Name ~= "HumanoidRootPart" then
					-- nao mexe em partes que o jogo deixa transparente de proposito demais
					-- so corrige se ficou "sumido" por bug de distancia
				end
				part.CanCollide = false -- evita fisica estranha no extremo
			elseif part:IsA("Decal") or part:IsA("Texture") then
				part.Transparency = 0
			elseif part:IsA("SpecialMesh") or part:IsA("MeshPart") then
				if part:IsA("MeshPart") then
					part.LocalTransparencyModifier = 0
				end
			end
		end)
	end

	-- camera nao perde o personagem
	pcall(function()
		local cam = workspace.CurrentCamera
		if cam and hum then
			if cam.CameraSubject ~= hum then
				cam.CameraSubject = hum
			end
		end
	end)
end

-- 3 loops = max forca (Render + Heartbeat + Stepped)
pcall(function()
	RunService:UnbindFromRenderStep("VoidSkyAntiUltra")
end)
RunService:BindToRenderStep("VoidSkyAntiUltra", Enum.RenderPriority.Last.Value, function()
	hardenCharacter(player.Character)
end)

RunService.Heartbeat:Connect(function()
	hardenCharacter(player.Character)
end)

RunService.Stepped:Connect(function()
	hardenCharacter(player.Character)
end)

-- re-aplica quando respawna
player.CharacterAdded:Connect(function(char)
	task.wait(0.2)
	hardenCharacter(char)
	task.wait(0.5)
	hardenCharacter(char)
end)

print("[VOID v12.2] Anti-void/ceu ULTRA ativo (anti-torto + anti-invisivel)")
