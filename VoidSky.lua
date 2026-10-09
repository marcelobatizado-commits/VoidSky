-- ============================================================
-- VOID ULTRA v11 SUPER
-- AntiVoid/God: verde=ON vermelho=OFF
-- Caixa de texto: comeca DESLIGADA
-- Ligar caixa = abre lista de players (sem precisar martelo)
-- INICIAR principal = liga caixa sozinha
-- So reage a ;fly / ;fly me / ;fly nome
-- ============================================================

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local ok, err = pcall(function()
	local src = game:HttpGet("https://raw.githubusercontent.com/marcelobatizado-commits/VoidSky/cb4f59bfa58fa2d06c44f8269f946b8492e7ad43/VoidSky.lua")
	src = string.gsub(src, "%-100000", "-500000")
	src = string.gsub(src, "10000000", "15000000")
	src = string.gsub(src, "HEIGHT_TRIGGER = 100", "HEIGHT_TRIGGER = 30")
	src = string.gsub(src, "v9%.0", "v11")
	src = string.gsub(src, "VOID ULTRA v9", "VOID ULTRA v11")

	-- espadas
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
	do
		local a = string.find(src, "local function getAnyTool", 1, true)
		local b = string.find(src, "local function forcePosition", 1, true)
		if a and b and b > a then
			src = string.sub(src, 1, a - 1) .. newGet .. "\n\n" .. string.sub(src, b)
		end
	end

	-- tryGrab melhorado
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
		if hrp then pcall(function()
			local char = player.Character
			if char then char:PivotTo(shopCF) end
			hrp.CFrame = shopCF
			hrp.AssemblyLinearVelocity = Vector3.zero
		end) end
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
		end
	end

	-- CharacterAdded
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
		end
	end

	local fn, cErr = loadstring(src)
	if not fn then error("Compile: " .. tostring(cErr)) end
	fn()
end)

if not ok then
	warn("[VOID v11] ERRO: " .. tostring(err))
	print("[VOID v11] ERRO: " .. tostring(err))
	return
end

print("[VOID v11] base OK")

-- ============================================================
-- ADDON v11
-- ============================================================
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

	for _, n in ipairs({"UnflyLabel", "UnflyBox", "UnflyStatus", "UnflyToggle", "V11PickList"}) do
		local o = content:FindFirstChild(n) or main:FindFirstChild(n) or gui:FindFirstChild(n)
		if o then o:Destroy() end
	end

	pcall(function()
		main.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
		main.Size = UDim2.fromOffset(320, 460)
		local stroke = main:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", main)
		stroke.Color = Color3.fromRGB(120, 100, 255)
		stroke.Thickness = 1.8
	end)

	local GREEN = Color3.fromRGB(40, 180, 95)
	local RED = Color3.fromRGB(210, 50, 60)
	local GREEN_H = Color3.fromRGB(60, 210, 120)
	local RED_H = Color3.fromRGB(240, 80, 90)

	-- ===== cores Anti Void / God Mode =====
	local function syncToggleColors()
		for _, b in ipairs(content:GetDescendants()) do
			if b:IsA("TextButton") then
				local up = string.upper(b.Text or "")
				if up:find("ANTI VOID") or up:find("GOD MODE") then
					if up:find("OFF") or up:find("DESATIV") then
						b.BackgroundColor3 = RED
					else
						b.BackgroundColor3 = GREEN
					end
				end
			end
		end
	end

	-- hook nos toggles pra atualizar cor depois do click
	for _, b in ipairs(content:GetDescendants()) do
		if b:IsA("TextButton") then
			local up = string.upper(b.Text or "")
			if (up:find("ANTI VOID") or up:find("GOD MODE")) and not b:GetAttribute("V11Color") then
				b:SetAttribute("V11Color", true)
				b.MouseButton1Click:Connect(function()
					task.defer(function()
						task.wait(0.05)
						syncToggleColors()
					end)
				end)
				b:GetPropertyChangedSignal("Text"):Connect(syncToggleColors)
			end
		end
	end
	syncToggleColors()
	-- re-sync periodico leve
	task.spawn(function()
		while gui.Parent do
			syncToggleColors()
			task.wait(0.5)
		end
	end)

	-- ===== estado caixa =====
	local selectedTarget = nil
	local boxEnabled = false -- COMECA DESLIGADA
	local lastSent = 0

	local label = Instance.new("TextLabel")
	label.Name = "UnflyLabel"
	label.Size = UDim2.new(1, -24, 0, 14)
	label.Position = UDim2.fromOffset(12, 116)
	label.BackgroundTransparency = 1
	label.Text = "Comando no chat (so quando alvo digitar fly):"
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
	local bpad = Instance.new("UIPadding", box)
	bpad.PaddingLeft = UDim.new(0, 12)

	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Name = "UnflyToggle"
	toggleBtn.Size = UDim2.new(1, -24, 0, 36)
	toggleBtn.Position = UDim2.fromOffset(12, 172)
	toggleBtn.BackgroundColor3 = GREEN -- desligada = verde INICIAR
	toggleBtn.Text = "INICIAR CAIXA DE TEXTO"
	toggleBtn.TextColor3 = Color3.new(1, 1, 1)
	toggleBtn.TextSize = 13
	toggleBtn.Font = Enum.Font.GothamBold
	toggleBtn.BorderSizePixel = 0
	toggleBtn.AutoButtonColor = false
	toggleBtn.ZIndex = 6
	toggleBtn.Parent = content
	Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 10)

	local statusLbl = Instance.new("TextLabel")
	statusLbl.Name = "UnflyStatus"
	statusLbl.Size = UDim2.new(1, -24, 0, 32)
	statusLbl.Position = UDim2.fromOffset(12, 214)
	statusLbl.BackgroundTransparency = 1
	statusLbl.Text = "Caixa: DESLIGADA | Alvo: ninguem\nClique INICIAR CAIXA ou INICIAR principal"
	statusLbl.TextColor3 = Color3.fromRGB(255, 140, 140)
	statusLbl.TextSize = 11
	statusLbl.Font = Enum.Font.Gotham
	statusLbl.TextXAlignment = Enum.TextXAlignment.Left
	statusLbl.TextYAlignment = Enum.TextYAlignment.Top
	statusLbl.ZIndex = 6
	statusLbl.Parent = content

	local function refreshStatus()
		local alvo = selectedTarget and selectedTarget.Name or "ninguem"
		if boxEnabled then
			statusLbl.Text = "Caixa: LIGADA | Alvo: " .. alvo .. "\nSo ;fly / ;fly me / ;fly nome"
			statusLbl.TextColor3 = Color3.fromRGB(120, 210, 150)
		else
			statusLbl.Text = "Caixa: DESLIGADA | Alvo: " .. alvo .. "\nNao envia nada no chat"
			statusLbl.TextColor3 = Color3.fromRGB(255, 140, 140)
		end
	end

	-- ===== lista de players (so pra caixa, sem martelo) =====
	local pickGui = Instance.new("Frame")
	pickGui.Name = "V11PickList"
	pickGui.Size = UDim2.fromOffset(0, 0)
	pickGui.Position = UDim2.new(0.5, 0, 0.5, 0)
	pickGui.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
	pickGui.BorderSizePixel = 0
	pickGui.Visible = false
	pickGui.ZIndex = 20
	pickGui.ClipsDescendants = true
	pickGui.Parent = gui
	Instance.new("UICorner", pickGui).CornerRadius = UDim.new(0, 14)
	local pStroke = Instance.new("UIStroke", pickGui)
	pStroke.Color = Color3.fromRGB(120, 100, 255)
	pStroke.Thickness = 1.5

	local pTitle = Instance.new("TextLabel")
	pTitle.Size = UDim2.new(1, -50, 0, 40)
	pTitle.Position = UDim2.fromOffset(14, 0)
	pTitle.BackgroundTransparency = 1
	pTitle.Text = "Alvo da caixa de texto"
	pTitle.TextColor3 = Color3.fromRGB(235, 235, 250)
	pTitle.TextSize = 15
	pTitle.Font = Enum.Font.GothamBold
	pTitle.TextXAlignment = Enum.TextXAlignment.Left
	pTitle.ZIndex = 21
	pTitle.Parent = pickGui

	local pClose = Instance.new("TextButton")
	pClose.Size = UDim2.fromOffset(28, 28)
	pClose.Position = UDim2.new(1, -36, 0, 6)
	pClose.BackgroundColor3 = RED
	pClose.Text = "X"
	pClose.TextColor3 = Color3.new(1,1,1)
	pClose.TextSize = 14
	pClose.Font = Enum.Font.GothamBold
	pClose.BorderSizePixel = 0
	pClose.ZIndex = 21
	pClose.Parent = pickGui
	Instance.new("UICorner", pClose).CornerRadius = UDim.new(0, 7)

	local pScroll = Instance.new("ScrollingFrame")
	pScroll.Size = UDim2.new(1, -20, 1, -50)
	pScroll.Position = UDim2.fromOffset(10, 42)
	pScroll.BackgroundTransparency = 1
	pScroll.BorderSizePixel = 0
	pScroll.ScrollBarThickness = 4
	pScroll.ZIndex = 21
	pScroll.Parent = pickGui
	local listLayout = Instance.new("UIListLayout", pScroll)
	listLayout.Padding = UDim.new(0, 6)

	local function closePick()
		local t = TweenService:Create(pickGui, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.fromOffset(0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)
		})
		t:Play()
		t.Completed:Wait()
		pickGui.Visible = false
	end

	local function setTarget(plr)
		if not plr or plr == player then return end
		selectedTarget = plr
		local t = box.Text or ""
		if t == "" or t == ";unfly " or t == ";unfly" then
			box.Text = ";unfly " .. plr.Name
		end
		refreshStatus()
		print("[VOID v11] Alvo caixa: " .. plr.Name)
	end

	local function openPick()
		for _, c in ipairs(pScroll:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
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
				btn.ZIndex = 22
				btn.Parent = pScroll
				Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
				btn.MouseButton1Click:Connect(function()
					setTarget(plr)
					closePick()
				end)
				btn.MouseEnter:Connect(function()
					TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(50, 55, 90)}):Play()
				end)
				btn.MouseLeave:Connect(function()
					TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(30, 32, 48)}):Play()
				end)
				y = y + 42
			end
		end
		pScroll.CanvasSize = UDim2.new(0, 0, 0, math.max(y, 40))
		pickGui.Visible = true
		pickGui.Size = UDim2.fromOffset(0, 0)
		pickGui.Position = UDim2.new(0.5, 0, 0.5, 0)
		TweenService:Create(pickGui, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
			Size = UDim2.fromOffset(260, 320),
			Position = UDim2.new(0.5, -130, 0.5, -160)
		}):Play()
	end

	pClose.MouseButton1Click:Connect(closePick)

	local function setBoxEnabled(on, openList)
		boxEnabled = on
		if on then
			toggleBtn.Text = "PARAR CAIXA DE TEXTO"
			TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = RED}):Play()
			if openList then openPick() end
		else
			toggleBtn.Text = "INICIAR CAIXA DE TEXTO"
			TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = GREEN}):Play()
		end
		refreshStatus()
	end

	-- clique no botao da caixa
	toggleBtn.MouseButton1Click:Connect(function()
		if not boxEnabled then
			-- LIGAR: ativa + abre lista pra escolher alvo (sem martelo)
			setBoxEnabled(true, true)
		else
			-- PARAR
			setBoxEnabled(false, false)
		end
	end)

	-- ===== hooks INICIAR principal / lista martelo =====
	local function forceAntiVoidOn()
		pcall(function() workspace.FallenPartsDestroyHeight = 0/0 end)
		for _, b in ipairs(content:GetDescendants()) do
			if b:IsA("TextButton") then
				local txt = string.upper(b.Text or "")
				if txt:find("ANTI VOID") and (txt:find("OFF") or txt:find("DESATIV")) then
					pcall(function() b.MouseButton1Click:Fire() end)
				end
				if txt:find("GOD MODE") and (txt:find("OFF") or txt:find("DESATIV")) then
					pcall(function() b.MouseButton1Click:Fire() end)
				end
			end
		end
		task.defer(syncToggleColors)
	end

	RunService.Heartbeat:Connect(function()
		if gui.Parent then pcall(function() workspace.FallenPartsDestroyHeight = 0/0 end) end
	end)

	local function hookButtons()
		for _, d in ipairs(gui:GetDescendants()) do
			if d:IsA("TextButton") then
				local txt, up = d.Text or "", string.upper(d.Text or "")
				local plr = Players:FindFirstChild(txt)
				if plr and plr ~= player and not d:GetAttribute("V11Hook") then
					d:SetAttribute("V11Hook", true)
					d.MouseButton1Click:Connect(function() setTarget(plr) end)
				end
				if (up == "CONFIRMAR" or up == "CONFIRM") and not d:GetAttribute("V11Confirm") then
					d:SetAttribute("V11Confirm", true)
					d.MouseButton1Click:Connect(function()
						task.wait(0.05)
						forceAntiVoidOn()
						-- ao confirmar martelo, liga a caixa sozinha
						if not boxEnabled then setBoxEnabled(true, false) end
					end)
				end
				if (up == "INICIAR" or up == "START") and not d:GetAttribute("V11Start") then
					d:SetAttribute("V11Start", true)
					d.MouseButton1Click:Connect(function()
						forceAntiVoidOn()
						task.delay(0.3, forceAntiVoidOn)
						-- INICIAR principal liga a caixa sozinha
						if not boxEnabled then setBoxEnabled(true, false) end
					end)
				end
			end
		end
	end
	hookButtons()
	gui.DescendantAdded:Connect(function() task.defer(hookButtons) end)

	-- ===== chat: SO fly =====
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
				if ev and ev:FindFirstChild("SayMessageRequest") then
					ev.SayMessageRequest:FireServer(msg, "All")
					sent = true
				end
			end)
		end
		return sent
	end

	local function isFlyMsg(text)
		if not text then return false end
		local t = string.lower(tostring(text)):gsub("<[^>]+>", "")
		t = t:gsub("^%s+", ""):gsub("%s+$", "")
		-- ;fly | ;fly me | ;fly Nome | :fly | /fly | fly | fly me | fly Nome
		if t:match("^;?%s*fly%s*$") then return true end
		if t:match("^;?%s*fly%s+") then return true end
		if t:match("^:?%s*fly") then return true end
		if t:match("^/%s*fly") then return true end
		if t:find("fly%s+me") then return true end
		return false
	end

	local function onChatted(speaker, message)
		if not boxEnabled then return end
		if not selectedTarget then return end
		if not speaker or speaker == player then return end
		if speaker.UserId ~= selectedTarget.UserId then return end
		if not isFlyMsg(message) then return end -- SO FLY, nao qualquer msg

		local cmd = box.Text
		if not cmd or cmd:gsub("%s", "") == "" or cmd == ";unfly" or cmd == ";unfly " then
			cmd = ";unfly " .. speaker.Name
		end

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

	-- comeca DESLIGADA
	setBoxEnabled(false, false)
	syncToggleColors()
	print("[VOID v11 SUPER] OK | caixa OFF | AntiVoid cores | lista ao ligar caixa")
end)
