-- ============================================================
-- VOID ULTRA v10.1
-- Recover: se martelo sumir no void/ceu -> pausa hold, TP loja, pega, VOLTA
-- Morte: primeiro arma+martelo, DEPOIS void/ceu
-- + caixa de texto / anti-void auto (v10)
-- ============================================================

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local ok, err = pcall(function()
	local src = game:HttpGet("https://raw.githubusercontent.com/marcelobatizado-commits/VoidSky/cb4f59bfa58fa2d06c44f8269f946b8492e7ad43/VoidSky.lua")

	-- config
	src = string.gsub(src, "%-100000", "-500000")
	src = string.gsub(src, "10000000", "15000000")
	src = string.gsub(src, "HEIGHT_TRIGGER = 100", "HEIGHT_TRIGGER = 30")
	src = string.gsub(src, "v9%.0", "v10.1")
	src = string.gsub(src, "VOID ULTRA v9", "VOID ULTRA v10")

	-- ===== REPLACE tryGrabWithTimeout: pausa hold, TP loja, pega, volta =====
	local oldGrab = [[local function tryGrabWithTimeout()
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
end]]

	local newGrab = [[local function tryGrabWithTimeout()
	local savedHold = currentHoldCF
	local t0 = tick()
	-- tenta no lugar atual (5s)
	while tick() - t0 < GRAB_TIMEOUT do
		if not running then return false end
		if tryGrabOnce() then return true end
		setStatus(string.format("Martelo... %.1fs", tick() - t0), Color3.fromRGB(255, 190, 60))
		task.wait(0.35)
	end
	-- pressao do void/ceu atrapalha: PAUSA hold, TP loja, pega, VOLTA
	setStatus("TP ate o martelo (loja)...", Color3.fromRGB(255, 140, 40))
	clearHoldConnections()
	pcall(function() RunService:UnbindFromRenderStep("VoidSkyHold") end)
	currentHoldCF = nil
	local shopCF = CFrame.new(POS_SHOP + Vector3.new(0, 4, 0))
	for i = 1, 20 do
		if not running then return false end
		local hrp = getHRP()
		if hrp then
			pcall(function()
				local char = player.Character
				if char then char:PivotTo(shopCF) end
				hrp.CFrame = shopCF
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.AssemblyAngularVelocity = Vector3.zero
			end)
		end
		task.wait()
	end
	task.wait(0.35)
	local got = false
	for i = 1, 12 do
		if not running then break end
		if tryGrabOnce() then got = true break end
		-- reforca TP loja entre tentativas
		local hrp = getHRP()
		if hrp then pcall(function() hrp.CFrame = shopCF hrp.AssemblyLinearVelocity = Vector3.zero end) end
		task.wait(0.2)
	end
	if not got then got = findTool() ~= nil end
	-- VOLTA pro void/ceu onde estava
	if savedHold and running then
		setStatus("Voltando void/ceu...", Color3.fromRGB(100, 200, 255))
		task.wait(0.08)
		moveTo(savedHold)
	elseif running then
		moveTo(POS_VOID)
	end
	return got
end]]

	if string.find(src, "local function tryGrabWithTimeout", 1, true) then
		-- troca por marcadores estaveis
		local a = string.find(src, "local function tryGrabWithTimeout", 1, true)
		local b = string.find(src, "local function startHammerRecover", 1, true)
		if a and b and b > a then
			src = string.sub(src, 1, a - 1) .. newGrab .. "\n\n" .. string.sub(src, b)
			print("[VOID v10.1] tryGrabWithTimeout substituido")
		end
	end

	-- ===== REPLACE CharacterAdded: martelo ANTES do void =====
	local oldChar = [[player.CharacterAdded:Connect(function()
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
end)]]

	local newChar = [[player.CharacterAdded:Connect(function()
	task.wait(0.35)
	setFallenHeight()
	local hrp, hum = waitForCharacter(4)
	if not hrp then return end
	if running then
		-- ORDEM: 1) pega arma/martelo  2) depois void/ceu
		setStatus("Respawn: pegando martelo...", Color3.fromRGB(255, 200, 80))
		clearHoldConnections()
		pcall(function() RunService:UnbindFromRenderStep("VoidSkyHold") end)
		currentHoldCF = nil
		local saved = (currentMode == "sky") and POS_SKY or POS_VOID
		-- tenta equipar qualquer arma e ir na loja
		local got = tryGrabWithTimeout()
		if got then
			forceEquipTool()
			startToolForce()
			hammerReady = true
		end
		startHammerRecover()
		-- agora sim void/ceu
		if running then
			setStatus("Respawn: indo void/ceu...", Color3.fromRGB(100, 180, 255))
			moveTo(saved)
		end
	else
		pcall(function()
			hum.PlatformStand = false hum.WalkSpeed = 16 hum.JumpPower = 50 hum.JumpHeight = 7.2 hum.AutoRotate = true hrp.Anchored = false
		end)
	end
	if godModeEnabled and hum then applyHumanoidProtect(hum) end
end)]]

	do
		local a = string.find(src, "player.CharacterAdded:Connect", 1, true)
		if a then
			local rest = string.sub(src, a)
			local close = string.find(rest, "\nend%)\n", 1, false) -- not reliable
			-- achar fim do Connect function ate print final
			local endMark = string.find(src, "print(", a, true)
			if endMark then
				-- volta ate o end) antes do print
				local chunk = string.sub(src, a, endMark - 1)
				src = string.sub(src, 1, a - 1) .. newChar .. "\n\n" .. string.sub(src, endMark)
				print("[VOID v10.1] CharacterAdded substituido")
			end
		end
	end

	local fn, cErr = loadstring(src)
	if not fn then error("Compile: " .. tostring(cErr)) end
	fn()
end)

if not ok then
	warn("[VOID v10.1] ERRO: " .. tostring(err))
	print("[VOID v10.1] ERRO: " .. tostring(err))
	return
end

print("[VOID v10.1] base OK")

-- ---------- ADDON caixa de texto (igual v10) ----------
task.spawn(function()
	local pg = player:WaitForChild("PlayerGui")
	local gui = pg:WaitForChild("VoidSkyUltra", 25)
	if not gui then return end
	local main = gui:FindFirstChildOfClass("Frame")
	if not main then return end
	local content = nil
	for _, c in ipairs(main:GetChildren()) do
		if c:IsA("Frame") and c.Position.Y.Offset >= 40 then content = c break end
	end
	if not content then content = main end
	for _, n in ipairs({"UnflyLabel", "UnflyBox", "UnflyStatus", "UnflyToggle"}) do
		local o = content:FindFirstChild(n)
		if o then o:Destroy() end
	end
	pcall(function() main.Size = UDim2.fromOffset(math.max(main.Size.X.Offset, 310), 430) end)

	local selectedTarget, boxEnabled, lastSent = nil, true, 0

	local label = Instance.new("TextLabel")
	label.Name = "UnflyLabel"
	label.Size = UDim2.new(1, -24, 0, 14)
	label.Position = UDim2.fromOffset(12, 116)
	label.BackgroundTransparency = 1
	label.Text = "Mensagem que vai pro chat (quando o alvo digitar fly):"
	label.TextColor3 = Color3.fromRGB(160, 165, 190)
	label.TextSize = 10
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 6
	label.Parent = content

	local box = Instance.new("TextBox")
	box.Name = "UnflyBox"
	box.Size = UDim2.new(1, -24, 0, 32)
	box.Position = UDim2.fromOffset(12, 132)
	box.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
	box.Text = ";unfly "
	box.PlaceholderText = ";unfly NomeDaPessoa"
	box.TextColor3 = Color3.fromRGB(240, 240, 255)
	box.PlaceholderColor3 = Color3.fromRGB(100, 105, 130)
	box.TextSize = 13
	box.Font = Enum.Font.Gotham
	box.ClearTextOnFocus = false
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.ZIndex = 6
	box.Parent = content
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
	local boxPad = Instance.new("UIPadding", box)
	boxPad.PaddingLeft = UDim.new(0, 10)

	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Name = "UnflyToggle"
	toggleBtn.Size = UDim2.new(1, -24, 0, 34)
	toggleBtn.Position = UDim2.fromOffset(12, 170)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(210, 50, 50)
	toggleBtn.Text = "PARAR CAIXA DE TEXTO"
	toggleBtn.TextColor3 = Color3.new(1, 1, 1)
	toggleBtn.TextSize = 13
	toggleBtn.Font = Enum.Font.GothamBold
	toggleBtn.BorderSizePixel = 0
	toggleBtn.AutoButtonColor = false
	toggleBtn.ZIndex = 6
	toggleBtn.Parent = content
	Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

	local statusLbl = Instance.new("TextLabel")
	statusLbl.Name = "UnflyStatus"
	statusLbl.Size = UDim2.new(1, -24, 0, 28)
	statusLbl.Position = UDim2.fromOffset(12, 208)
	statusLbl.BackgroundTransparency = 1
	statusLbl.Text = "Caixa: LIGADA | Alvo: ninguem"
	statusLbl.TextColor3 = Color3.fromRGB(120, 200, 140)
	statusLbl.TextSize = 11
	statusLbl.Font = Enum.Font.Gotham
	statusLbl.TextXAlignment = Enum.TextXAlignment.Left
	statusLbl.TextYAlignment = Enum.TextYAlignment.Top
	statusLbl.ZIndex = 6
	statusLbl.Parent = content

	local function refreshStatus()
		local alvo = selectedTarget and selectedTarget.Name or "ninguem"
		if boxEnabled then
			statusLbl.Text = "Caixa: LIGADA | Alvo: " .. alvo .. "\nSe o alvo digitar fly -> manda a mensagem da caixa"
			statusLbl.TextColor3 = Color3.fromRGB(120, 200, 140)
		else
			statusLbl.Text = "Caixa: DESLIGADA | Alvo: " .. alvo .. "\nNao envia nada no chat"
			statusLbl.TextColor3 = Color3.fromRGB(255, 120, 120)
		end
	end

	local function setBoxEnabled(on)
		boxEnabled = on
		if on then
			toggleBtn.BackgroundColor3 = Color3.fromRGB(210, 50, 50)
			toggleBtn.Text = "PARAR CAIXA DE TEXTO"
		else
			toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 170, 90)
			toggleBtn.Text = "INICIAR CAIXA DE TEXTO"
		end
		refreshStatus()
	end

	toggleBtn.MouseButton1Click:Connect(function() setBoxEnabled(not boxEnabled) end)

	local function setTarget(plr)
		if not plr or plr == player then return end
		selectedTarget = plr
		local t = box.Text or ""
		if t == "" or t == ";unfly " or t == ";unfly" then box.Text = ";unfly " .. plr.Name end
		refreshStatus()
	end

	local function forceAntiVoidOn()
		pcall(function() workspace.FallenPartsDestroyHeight = 0/0 end)
		for _, b in ipairs(content:GetDescendants()) do
			if b:IsA("TextButton") then
				local txt = string.upper(b.Text or "")
				if txt:find("ANTI VOID") and txt:find("OFF") then pcall(function() b.MouseButton1Click:Fire() end) end
				if txt:find("GOD MODE") and txt:find("OFF") then pcall(function() b.MouseButton1Click:Fire() end) end
			end
		end
	end

	RunService.Heartbeat:Connect(function()
		if gui.Parent then pcall(function() workspace.FallenPartsDestroyHeight = 0/0 end) end
	end)

	local function hookButtons()
		for _, d in ipairs(gui:GetDescendants()) do
			if d:IsA("TextButton") then
				local txt, up = d.Text or "", string.upper(d.Text or "")
				local plr = Players:FindFirstChild(txt)
				if plr and plr ~= player and not d:GetAttribute("V10Hook") then
					d:SetAttribute("V10Hook", true)
					d.MouseButton1Click:Connect(function() setTarget(plr) end)
				end
				if (up == "CONFIRMAR" or up == "CONFIRM") and not d:GetAttribute("V10Confirm") then
					d:SetAttribute("V10Confirm", true)
					d.MouseButton1Click:Connect(function() task.wait(0.05) forceAntiVoidOn() end)
				end
				if (up == "INICIAR" or up == "START") and not d:GetAttribute("V10Start") then
					d:SetAttribute("V10Start", true)
					d.MouseButton1Click:Connect(function()
						forceAntiVoidOn()
						task.delay(0.3, forceAntiVoidOn)
					end)
				end
			end
		end
	end
	hookButtons()
	gui.DescendantAdded:Connect(function() task.defer(hookButtons) end)

	local function sendChat(msg)
		if type(msg) ~= "string" then return false end
		msg = msg:gsub("^%s+", ""):gsub("%s+$", "")
		if #msg < 2 or tick() - lastSent < 1.0 then return false end
		lastSent = tick()
		local sent = false
		pcall(function()
			local channels = TextChatService:FindFirstChild("TextChannels")
			if channels then
				local ch = channels:FindFirstChild("RBXGeneral")
				if not ch then for _, c in ipairs(channels:GetChildren()) do if c:IsA("TextChannel") then ch = c break end end end
				if ch then ch:SendAsync(msg) sent = true end
			end
		end)
		if not sent then
			pcall(function()
				local ev = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
				if ev and ev:FindFirstChild("SayMessageRequest") then ev.SayMessageRequest:FireServer(msg, "All") sent = true end
			end)
		end
		return sent
	end

	local function isFlyMsg(text)
		if not text then return false end
		local t = string.lower(tostring(text)):gsub("<[^>]+>", "")
		return t:find(";%s*fly") or t:find(":%s*fly") or t:find("/fly") or t:match("^%s*fly%s*$") or t:match("^%s*fly%s+") or t:find("fly%s+me")
	end

	local function onChatted(speaker, message)
		if not boxEnabled or not selectedTarget or not speaker or speaker == player then return end
		if speaker.UserId ~= selectedTarget.UserId then return end
		if not isFlyMsg(message) then return end
		local cmd = box.Text
		if not cmd or cmd:gsub("%s", "") == "" or cmd == ";unfly" or cmd == ";unfly " then cmd = ";unfly " .. speaker.Name end
		statusLbl.Text = selectedTarget.Name .. " digitou fly! Enviando...\n" .. cmd
		statusLbl.TextColor3 = Color3.fromRGB(255, 200, 80)
		task.defer(function()
			if sendChat(cmd) then
				statusLbl.Text = "Enviado: " .. cmd
				statusLbl.TextColor3 = Color3.fromRGB(100, 255, 140)
			else
				statusLbl.Text = "Falha ao enviar no chat"
				statusLbl.TextColor3 = Color3.fromRGB(255, 90, 90)
			end
			task.delay(2.5, refreshStatus)
		end)
	end

	local function hookPlayer(plr)
		if plr == player then return end
		pcall(function() plr.Chatted:Connect(function(msg) onChatted(plr, msg) end) end)
	end
	for _, plr in ipairs(Players:GetPlayers()) do hookPlayer(plr) end
	Players.PlayerAdded:Connect(hookPlayer)
	pcall(function()
		TextChatService.MessageReceived:Connect(function(message)
			local src = message.TextSource
			if not src then return end
			local plr = Players:GetPlayerByUserId(src.UserId)
			if plr then onChatted(plr, message.Text) end
		end)
	end)

	setBoxEnabled(true)
	print("[VOID v10.1] addon OK | recover martelo melhorado")
end)
