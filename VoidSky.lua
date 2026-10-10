-- VOID ULTRA v12.1
-- Void Y=-5000000 | Ceu Y=-50000000 | X=0 Z=0
-- Anti-torto + anti-void/ceu fortissimo
-- (carrega v12 completa e aplica patches de altura)

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local ok, err = pcall(function()
	local src = game:HttpGet("https://raw.githubusercontent.com/marcelobatizado-commits/VoidSky/3e8d8b67a814686c69551f2f30d0dc2c722a06b4/VoidSky.lua")

	-- troca alturas no loader interno (antes de executar)
	src = string.gsub(src, "%-1500000", "-5000000")
	src = string.gsub(src, "16000000", "-50000000")
	src = string.gsub(src, "v12 SUPER", "v12.1")
	src = string.gsub(src, "%[VOID v12%]", "[VOID v12.1]")

	local fn, cErr = loadstring(src)
	if not fn then error("Compile: " .. tostring(cErr)) end
	fn()
end)

if not ok then
	warn("[VOID v12.1] ERRO: " .. tostring(err))
	print("[VOID v12.1] ERRO: " .. tostring(err))
	return
end

print("[VOID v12.1] OK | Void Y=-5.000.000 | Ceu Y=-50.000.000 | X=0 Z=0")

-- Anti-torto + anti-void/ceu extra (sempre reto em extremos)
RunService.Heartbeat:Connect(function()
	pcall(function() workspace.FallenPartsDestroyHeight = 0 / 0 end)
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if hum then
		pcall(function()
			hum.MaxHealth = math.max(hum.MaxHealth, 9e9)
			hum.Health = hum.MaxHealth
			hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
		end)
	end
	if root and (root.Position.Y > 50000 or root.Position.Y < -500) then
		pcall(function()
			local p = root.Position
			-- sempre reto, X/Z mantidos, sem rotacao
			root.CFrame = CFrame.new(p.X, p.Y, p.Z)
			root.AssemblyAngularVelocity = Vector3.zero
		end)
	end
end)

RunService.Stepped:Connect(function()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root and (root.Position.Y > 50000 or root.Position.Y < -500) then
		pcall(function()
			local p = root.Position
			root.CFrame = CFrame.new(p.X, p.Y, p.Z)
			root.AssemblyAngularVelocity = Vector3.zero
		end)
	end
end)
