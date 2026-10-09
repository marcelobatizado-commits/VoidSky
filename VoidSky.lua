-- ============================================================
-- VOID ULTRA v10.2
-- Espadas: KatanaGroup > LightSword > AzureSword
-- Recover martelo + morte ordem certa
-- GUI mais bonita (botoes, animacao, visual)
-- Caixa de texto + anti-void auto
-- ============================================================

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local ok, err = pcall(function()
	local src = game:HttpGet("https://raw.githubusercontent.com/marcelobatizado-commits/VoidSky/cb4f59bfa58fa2d06c44f8269f946b8492e7ad43/VoidSky.lua")

	src = string.gsub(src, "%-100000", "-500000")
	src = string.gsub(src, "10000000", "15000000")
	src = string.gsub(src, "HEIGHT_TRIGGER = 100", "HEIGHT_TRIGGER = 30")
	src = string.gsub(src, "v9%.0", "v10.2")
	src = string.gsub(src, "VOID ULTRA v9", "VOID ULTRA v10")

	-- ===== espadas prioritarias =====
	local oldGet = [[local function getAnyTool()
	local char, bp = player.Character, player:FindFirstChild("Backpack")
	local katana = (char and char:FindFirstChild(SWORD_NAME)) or (bp and bp:FindFirstChild(SWORD_NAME))
	if katana then return katana end
	if char then for _, v in ipairs(char:GetChildren()) do if v:IsA("Tool") and v.Name ~= TOOL_NAME then return v end end end
	if bp then for _, v in ipairs(bp:GetChildren()) do if v:IsA("Tool") and v.Name ~= TOOL_NAME then return v end end end
	return nil
end]]

	local newGet = [[local function getAnyTool()
	local char, bp = player.Character, player:FindFirstChild("Backpack")
	local order = { "KatanaGroup", "LightSword", "AzureSword", SWORD_NAME }
	for _, name in ipairs(order) do
		local t = (char and char:FindFirstChild(name)) or (bp and bp:FindFirstChild(name))
		if t and t:IsA("Tool") then return t end
	end
	if char then for _, v in ipairs(char:GetChildren()) do if v:IsA("Tool") and v.Name ~= TOOL_NAME then return v end end end
	if bp then for _, v in ipairs(bp:GetChildren()) do if v:IsA("Tool") and v.Name ~= TOOL_NAME then return v end end end
	return nil
end]]

	if string.find(src, "local function getAnyTool", 1, true) then
		local a = string.find(src, "local function getAnyTool", 1, true)
		local b = string.find(src, "local function forcePosition", 1, true)
		if a and b and b > a then
			src = string.sub(src, 1, a - 1) .. newGet .. "\n\n" .. string.sub(src, b)
			print("[v10.2] getAnyTool: KatanaGroup > LightSword > AzureSword")
		end
	end

	-- ===== tryGrabWithTimeout melhorado =====
	local newGrab = [[local function tryGrabWithTimeout()
	local savedHold = currentHoldCF
	local t0 = tick()
	while tick() - t0 < GRAB_TIMEOUT do
		if not running then return false end
		if tryGrabOnce() then return true end
		setStatus(string.format("Martelo... %.1fs", tick() - t0), Color3.fromRGB(255, 190, 60))
		task.wait(0.35)
	end
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
			end)
		end
		task.wait()
	end
	task.wait(0.35)
	local got = false
	for i = 1, 12 do
		if not running then break end
		if tryGrabOnce() then got = true break end
		local hrp = getHRP()
		if hrp then pcall(function() hrp.CFrame = shopCF hrp.AssemblyLinearVelocity = Vector3.zero end) end
		task.wait(0.2)
	end
	if not got then got = findTool() ~= nil end
	if savedHold and running then
		setStatus("Voltando void/ceu...", Color3.fromRGB(100, 200, 255))
		task.wait(0.08)
		moveTo(savedHold)
	elseif running then
		moveTo(POS_VOID)
	end
	return got
end]]

	do
		local a = string.find(src, "local function tryGrabWithTimeout", 1, true)
		local b = string.find(src, "local function startHammerRecover", 1, true)
		if a and b and b > a then
			src = string.sub(src, 1, a - 1) .. newGrab .. "\n\n" .. string.sub(src, b)
			print("[v10.2] tryGrabWithTimeout OK")
		end
	end

	-- ===== CharacterAdded: martelo antes do void =====
	local newChar = [[player.CharacterAdded:Connect(function()
	task.wait(0.35)
	setFallenHeight()
	local hrp, hum = waitForCharacter(4)
	if not hrp then return end
	if running then
		setStatus("Respawn: pegando martelo...", Color3.fromRGB(255, 200, 80))
		clearHoldConnections()
		pcall(function() RunService:UnbindFromRenderStep("VoidSkyHold") end)
		currentHoldCF = nil
		local saved = (currentMode == "sky") and POS_SKY or POS_VOID
		local got = tryGrabWithTimeout()
		if got then forceEquipTool() startToolForce() hammerReady = true end
		startHammerRecover()
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
		local endMark = a and string.find(src, "print(", a, true)
		if a and endMark then
			src = string.sub(src, 1, a - 1) .. newChar .. "\n\n" .. string.sub(src, endMark)
			print("[v10.2] CharacterAdded OK")
		end
	end

	local fn, cErr = loadstring(src)
	if not fn then error("Compile: " .. tostring(cErr)) end
	fn()
end)

if not ok then
	warn("[VOID v10.2] ERRO: " .. tostring(err))
	print("[VOID v10.2] ERRO: " .. tostring(err))
	return
end

print("[VOID v10.2] base OK")

-- ---------- VISUAL + CAIXA DE TEXTO ----------
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

	for _, n in ipairs({"UnflyLabel", "UnflyBox", "UnflyStatus", "UnflyToggle", "V10Glow"}) do
		local o = content:FindFirstChild(n) or main:FindFirstChild(n)
		if o then o:Destroy() end
	end

	-- estilo main
	pcall(function()
		main.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
		main.Size = UDim2.fromOffset(320, 450)
		local stroke = main:FindFirstChildOfClass("UIStroke")
		if not stroke then stroke = Instance.new("UIStroke", main) end
		stroke.Color = Color3.fromRGB(120, 100, 255)
		stroke.Thickness = 1.8
		stroke.Transparency = 0.15
		-- glow animado no stroke
		task.spawn(function()
			while main.Parent do
				TweenService:Create(stroke, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.45}):Play()
				task.wait(1.2)
				TweenService:Create(stroke, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.1}):Play()
				task.wait(1.2)
			end
		end)
	end)

	-- anima entrada
	pcall(function()
		local s = main.Size
		main.Size = UDim2.fromOffset(0, 0)
		main.BackgroundTransparency = 0.5
		TweenService:Create(main, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(320, 450),
			BackgroundTransparency = 0
		}):Play()
	end)

	-- polish botoes existentes
	local function styleBtn(b, hoverColor)
		if not b:IsA("TextButton") then return end
		b.AutoButtonColor = false
		local base = b.BackgroundColor3
		local corner = b:FindFirstChildOfClass("UICorner")
		if not corner then
			corner = Instance.new("UICorner", b)
			corner.CornerRadius = UDim.new(0, 10)
		end
		if not b:FindFirstChildOfClass("UIStroke") then
			local s = Instance.new("UIStroke", b)
			s.Color = Color3.fromRGB(255, 255, 255)
			s.Thickness = 1
			s.Transparency = 0.85
		end
		if b:GetAttribute("StyledV10") then return end
		b:SetAttribute("StyledV10", true)
		b.MouseEnter:Connect(function()
			TweenService:Create(b, TweenInfo.new(0.15), {
				BackgroundColor3 = hoverColor or base:Lerp(Color3.new(1,1,1), 0.15),
				Size = b.Size + UDim2.fromOffset(0, 2)
			}):Play()
		end)
		b.MouseLeave:Connect(function()
			TweenService:Create(b, TweenInfo.new(0.15), {
				BackgroundColor3 = base,
				Size = b.Size - UDim2.fromOffset(0, 2)
			}):Play()
		end)
		b.MouseButton1Click:Connect(function()
			local o = b.Size
			TweenService:Create(b, TweenInfo.new(0.08), {Size = o - UDim2.fromOffset(4, 4)}):Play()
			task.wait(0.08)
			TweenService:Create(b, TweenInfo.new(0.12, Enum.EasingStyle.Back), {Size = o}):Play()
		end)
	end

	for _, d in ipairs(gui:GetDescendants()) do
		if d:IsA("TextButton") then
			local up = string.upper(d.Text or "")
			if up:find("INICIAR") or up:find("START") then
				d.BackgroundColor3 = Color3.fromRGB(45, 190, 110)
				d.Font = Enum.Font.GothamBold
				styleBtn(d, Color3.fromRGB(70, 220, 140))
			elseif up:find("PARAR") or up:find("STOP") then
				d.BackgroundColor3 = Color3.fromRGB(220, 55, 70)
				d.Font = Enum.Font.GothamBold
				styleBtn(d, Color3.fromRGB(255, 90, 100))
			elseif up:find("ANTI VOID") or up:find("GOD MODE") then
				d.Font = Enum.Font.GothamBold
				styleBtn(d)
			else
				styleBtn(d)
			end
		end
	end

	-- titulo
	for _, d in ipairs(main:GetDescendants()) do
		if d:IsA("TextLabel") and d.Text and (d.Text:find("VOID") or d.Text:find("ULTRA")) then
			d.Text = "VOID ULTRA v10.2"
			d.TextColor3 = Color3.fromRGB(200, 190, 255)
			d.Font = Enum.Font.GothamBold
		end
	end

	-- ===== caixa de texto =====
	local selectedTarget, boxEnabled, lastSent = nil, true, 0

	local label = Instance.new("TextLabel")
	label.Name = "UnflyLabel"
	label.Size = UDim2.new(1, -24, 0, 14)
	label.Position = UDim2.fromOffset(12, 116)
	label.BackgroundTransparency = 1
	label.Text = "Mensagem no chat (alvo digitar fly):"
	label.TextColor3 = Color3.fromRGB(170, 175, 210)
	label.TextSize = 11
	label.Font = Enum.Font.GothamMedium
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 6
	label.Parent = content

	local box = Instance.new("TextBox")
	box.Name = "UnflyBox"
	box.Size = UDim2.new(1, -24, 0, 34)
	box.Position = UDim2.fromOffset(12, 132)
	box.BackgroundColor3 = Color3.fromRGB(22, 24, 38)
	box.Text = ";unfly "
	box.PlaceholderText = ";unfly NomeDaPessoa"
	box.TextColor3 = Color3.fromRGB(245, 245, 255)
	box.PlaceholderColor3 = Color3.fromRGB(110, 115, 145)
	box.TextSize = 14
	box.Font = Enum.Font.Gotham
	box.ClearTextOnFocus = false
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.ZIndex = 6
	box.Parent = content
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 10)
	local bs = Instance.new("UIStroke", box)
	bs.Color = Color3.fromRGB(120, 100, 255)
	bs.Thickness = 1.3
	bs.Transparency = 0.3
	local bp = Instance.new("UIPadding", box)
	bp.PaddingLeft = UDim.new(0, 12)
	bp.PaddingRight = UDim.new(0, 12)
	box.Focused:Connect(function()
		TweenService:Create(bs, TweenInfo.new(0.2), {Transparency = 0, Color = Color3.fromRGB(160, 140, 255)}):Play()
	end)
	box.FocusLost:Connect(function()
		TweenService:Create(bs, TweenInfo.new(0.2), {Transparency = 0.3, Color = Color3.fromRGB(120, 100, 255)}):Play()
	end)

	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Name = "UnflyToggle"
	toggleBtn.Size = UDim2.new(1, -24, 0, 36)
	toggleBtn.Position = UDim2.fromOffset(12, 172)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(210, 50, 60)
	toggleBtn.Text = "PARAR CAIXA DE TEXTO"
	toggleBtn.TextColor3 = Color3.new(1, 1, 1)
	toggleBtn.TextSize = 13
	toggleBtn.Font = Enum.Font.GothamBold
	toggleBtn.BorderSizePixel = 0
	toggleBtn.AutoButtonColor = false
	toggleBtn.ZIndex = 6
	toggleBtn.Parent = content
	Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 10)
	local ts = Instance.new("UIStroke", toggleBtn)
	ts.Color = Color3.fromRGB(255, 255, 255)
	ts.Transparency = 0.8

	local statusLbl = Instance.new("TextLabel")
	statusLbl.Name = "UnflyStatus"
	statusLbl.Size = UDim2.new(1, -24, 0, 30)
	statusLbl.Position = UDim2.fromOffset(12, 214)
	statusLbl.BackgroundTransparency = 1
	statusLbl.Text = "Caixa: LIGADA | Alvo: ninguem"
	statusLbl.TextColor3 = Color3.fromRGB(120, 210, 150)
	statusLbl.TextSize = 11
	statusLbl.Font = Enum.Font.Gotham
	statusLbl.TextXAlignment = Enum.TextXAlignment.Left
	statusLbl.TextYAlignment = Enum.TextYAlignment.Top
	statusLbl.ZIndex = 6
	statusLbl.Parent = content

	local function refreshStatus()
		local alvo = selectedTarget and selectedTarget.Name or "ninguem"
		if boxEnabled then
			statusLbl.Text = "Caixa: LIGADA | Alvo: " .. alvo .. "\nAlvo digitar fly -> manda a mensagem"
			statusLbl.TextColor3 = Color3.fromRGB(120, 210, 150)
		else
			statusLbl.Text = "Caixa: DESLIGADA | Alvo: " .. alvo .. "\nNao envia nada"
			statusLbl.TextColor3 = Color3.fromRGB(255, 120, 120)
		end
	end

	local function setBoxEnabled(on)
		boxEnabled = on
		if on then
			toggleBtn.Text = "PARAR CAIXA DE TEXTO"
			TweenService:Create(toggleBtn, TweenInfo.new(0.25), {BackgroundColor3 = Color3.fromRGB(210, 50, 60)}):Play()
		else
			toggleBtn.Text = "INICIAR CAIXA DE TEXTO"
			TweenService:Create(toggleBtn, TweenInfo.new(0.25), {BackgroundColor3 = Color3.fromRGB(40, 175, 95)}):Play()
		end
		refreshStatus()
	end

	toggleBtn.MouseButton1Click:Connect(function()
		local o = toggleBtn.Size
		TweenService:Create(toggleBtn, TweenInfo.new(0.08), {Size = o - UDim2.fromOffset(4, 4)}):Play()
		task.wait(0.08)
		TweenService:Create(toggleBtn, TweenInfo.new(0.15, Enum.EasingStyle.Back), {Size = o}):Play()
		setBoxEnabled(not boxEnabled)
	end)
	toggleBtn.MouseEnter:Connect(function()
		TweenService:Create(ts, TweenInfo.new(0.15), {Transparency = 0.5}):Play()
	end)
	toggleBtn.MouseLeave:Connect(function()
		TweenService:Create(ts, TweenInfo.new(0.15), {Transparency = 0.8}):Play()
	end)

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
				if not d:GetAttribute("StyledV10") then styleBtn(d) end
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
		statusLbl.Text = selectedTarget.Name .. " digitou fly!\nEnviando: " .. cmd
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
	print("[VOID v10.2] OK | espadas + GUI polish + caixa")
end)
