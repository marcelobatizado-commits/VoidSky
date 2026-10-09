-- ============================================================
-- VOID ULTRA v12 SUPER
-- fly + fly2 | unfly + unfly2
-- Void Y=-1500000 | Ceu Y=16000000
-- Anti-void + anti-ceu fortes
-- UI liquid glass + animacoes
-- ============================================================

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local ok, err = pcall(function()
	local src = game:HttpGet("https://raw.githubusercontent.com/marcelobatizado-commits/VoidSky/cb4f59bfa58fa2d06c44f8269f946b8492e7ad43/VoidSky.lua")

	-- Void -1.5M | Ceu 16M
	src = string.gsub(src, "%-100000", "-1500000")
	src = string.gsub(src, "10000000", "16000000")
	src = string.gsub(src, "HEIGHT_TRIGGER = 100", "HEIGHT_TRIGGER = 30")
	src = string.gsub(src, "v9%.0", "v12")
	src = string.gsub(src, "VOID ULTRA v9", "VOID ULTRA v12")

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

	-- anti void/ceu mais forte no applyHoldProtect
	src = string.gsub(src,
		"hum:SetStateEnabled%(Enum%.HumanoidStateType%.Swimming, false%)",
		[[hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
		hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
		hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)]]
	)

	-- tryGrab
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
	warn("[VOID v12] ERRO: " .. tostring(err))
	print("[VOID v12] ERRO: " .. tostring(err))
	return
end

print("[VOID v12] base OK")

-- ============================================================
-- ADDON v12 - liquid glass + fly/fly2 + caixa
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

	for _, n in ipairs({"UnflyLabel", "UnflyBox", "UnflyStatus", "UnflyToggle", "V11PickList", "V12PickList", "GlassShade"}) do
		local o = content:FindFirstChild(n) or main:FindFirstChild(n) or gui:FindFirstChild(n)
		if o then o:Destroy() end
	end

	local GREEN = Color3.fromRGB(48, 200, 120)
	local RED = Color3.fromRGB(230, 70, 80)
	local GLASS = Color3.fromRGB(28, 30, 48)
	local GLASS2 = Color3.fromRGB(40, 42, 68)

	-- liquid glass main
	pcall(function()
		main.BackgroundColor3 = Color3.fromRGB(18, 18, 30)
		main.BackgroundTransparency = 0.08
		main.Size = UDim2.fromOffset(330, 470)
		local corner = main:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", main)
		corner.CornerRadius = UDim.new(0, 18)
		local stroke = main:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", main)
		stroke.Color = Color3.fromRGB(180, 190, 255)
		stroke.Thickness = 1.4
		stroke.Transparency = 0.35
		task.spawn(function()
			while main.Parent do
				TweenService:Create(stroke, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					Transparency = 0.55, Color = Color3.fromRGB(140, 160, 255)
				}):Play()
				task.wait(1.4)
				TweenService:Create(stroke, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					Transparency = 0.25, Color = Color3.fromRGB(200, 180, 255)
				}):Play()
				task.wait(1.4)
			end
		end)
	end)

	local function glassBtn(b, isOn)
		if not b or not b:IsA("TextButton") then return end
		b.AutoButtonColor = false
		b.Font = Enum.Font.GothamBold
		b.TextSize = 13
		local c = b:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", b)
		c.CornerRadius = UDim.new(0, 12)
		local s = b:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", b)
		s.Thickness = 1.1
		s.Color = Color3.fromRGB(255, 255, 255)
		s.Transparency = 0.75
		if isOn == true then
			b.BackgroundColor3 = GREEN
		elseif isOn == false then
			b.BackgroundColor3 = RED
		end
		b.BackgroundTransparency = 0.12
		if b:GetAttribute("GlassAnim") then return end
		b:SetAttribute("GlassAnim", true)
		local baseSize = b.Size
		b.MouseEnter:Connect(function()
			TweenService:Create(b, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
				BackgroundTransparency = 0,
				Size = baseSize + UDim2.fromOffset(0, 2)
			}):Play()
			TweenService:Create(s, TweenInfo.new(0.18), {Transparency = 0.45}):Play()
		end)
		b.MouseLeave:Connect(function()
			TweenService:Create(b, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
				BackgroundTransparency = 0.12,
				Size = baseSize
			}):Play()
			TweenService:Create(s, TweenInfo.new(0.18), {Transparency = 0.75}):Play()
		end)
		b.MouseButton1Down:Connect(function()
			TweenService:Create(b, TweenInfo.new(0.08), {Size = baseSize - UDim2.fromOffset(3, 3)}):Play()
		end)
		b.MouseButton1Up:Connect(function()
			TweenService:Create(b, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Size = baseSize}):Play()
		end)
	end

	local function syncToggleColors()
		for _, b in ipairs(content:GetDescendants()) do
			if b:IsA("TextButton") then
				local up = string.upper(b.Text or "")
				if up:find("ANTI VOID") or up:find("GOD MODE") then
					local on = not (up:find("OFF") or up:find("DESATIV"))
					b.BackgroundColor3 = on and GREEN or RED
					b.BackgroundTransparency = 0.12
					glassBtn(b, on)
				elseif up:find("INICIAR") and not up:find("CAIXA") then
					glassBtn(b, true)
				elseif up:find("PARAR") and not up:find("CAIXA") then
					glassBtn(b, false)
				else
					glassBtn(b, nil)
				end
			end
		end
	end

	for _, b in ipairs(content:GetDescendants()) do
		if b:IsA("TextButton") then
			local up = string.upper(b.Text or "")
			if (up:find("ANTI VOID") or up:find("GOD MODE")) and not b:GetAttribute("V12Color") then
				b:SetAttribute("V12Color", true)
				b.MouseButton1Click:Connect(function() task.defer(function() task.wait(0.05) syncToggleColors() end) end)
				b:GetPropertyChangedSignal("Text"):Connect(syncToggleColors)
			end
		end
	end
	syncToggleColors()
	task.spawn(function()
		while gui.Parent do syncToggleColors() task.wait(0.6) end
	end)

	-- anti void/ceu extra forte no addon
	RunService.Heartbeat:Connect(function()
		if not gui.Parent then return end
		pcall(function() workspace.FallenPartsDestroyHeight = 0/0 end)
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
			end)
		end
		-- anti ceu: se muito alto, segura health/state
		if root and (root.Position.Y > 500000 or root.Position.Y < -1000) then
			if hum then pcall(function() hum.Health = hum.MaxHealth end) end
		end
	end)

	-- ===== caixa =====
	local selectedTarget = nil
	local boxEnabled = false
	local lastSent = 0

	local label = Instance.new("TextLabel")
	label.Name = "UnflyLabel"
	label.Size = UDim2.new(1, -24, 0, 14)
	label.Position = UDim2.fromOffset(12, 114)
	label.BackgroundTransparency = 1
	label.Text = "Comando (fly -> unfly | fly2 -> unfly2):"
	label.TextColor3 = Color3.fromRGB(180, 185, 220)
	label.TextSize = 11
	label.Font = Enum.Font.GothamMedium
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 6
	label.Parent = content

	local box = Instance.new("TextBox")
	box.Name = "UnflyBox"
	box.Size = UDim2.new(1, -24, 0, 34)
	box.Position = UDim2.fromOffset(12, 130)
	box.BackgroundColor3 = GLASS
	box.BackgroundTransparency = 0.15
	box.Text = ";unfly "
	box.PlaceholderText = ";unfly Nome  |  ;unfly2 Nome"
	box.TextColor3 = Color3.fromRGB(245, 245, 255)
	box.PlaceholderColor3 = Color3.fromRGB(120, 125, 160)
	box.TextSize = 13
	box.Font = Enum.Font.Gotham
	box.ClearTextOnFocus = false
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.ZIndex = 6
	box.Parent = content
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 12)
	local boxStroke = Instance.new("UIStroke", box)
	boxStroke.Color = Color3.fromRGB(160, 170, 255)
	boxStroke.Thickness = 1.2
	boxStroke.Transparency = 0.4
	local boxPad = Instance.new("UIPadding", box)
	boxPad.PaddingLeft = UDim.new(0, 12)
	box.Focused:Connect(function()
		TweenService:Create(boxStroke, TweenInfo.new(0.2), {Transparency = 0.1, Color = Color3.fromRGB(190, 180, 255)}):Play()
		TweenService:Create(box, TweenInfo.new(0.2), {BackgroundTransparency = 0.05}):Play()
	end)
	box.FocusLost:Connect(function()
		TweenService:Create(boxStroke, TweenInfo.new(0.2), {Transparency = 0.4, Color = Color3.fromRGB(160, 170, 255)}):Play()
		TweenService:Create(box, TweenInfo.new(0.2), {BackgroundTransparency = 0.15}):Play()
	end)

	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Name = "UnflyToggle"
	toggleBtn.Size = UDim2.new(1, -24, 0, 36)
	toggleBtn.Position = UDim2.fromOffset(12, 170)
	toggleBtn.BackgroundColor3 = GREEN
	toggleBtn.BackgroundTransparency = 0.12
	toggleBtn.Text = "INICIAR CAIXA DE TEXTO"
	toggleBtn.TextColor3 = Color3.new(1, 1, 1)
	toggleBtn.TextSize = 13
	toggleBtn.Font = Enum.Font.GothamBold
	toggleBtn.BorderSizePixel = 0
	toggleBtn.AutoButtonColor = false
	toggleBtn.ZIndex = 6
	toggleBtn.Parent = content
	Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 12)
	glassBtn(toggleBtn, true)

	local statusLbl = Instance.new("TextLabel")
	statusLbl.Name = "UnflyStatus"
	statusLbl.Size = UDim2.new(1, -24, 0, 34)
	statusLbl.Position = UDim2.fromOffset(12, 212)
	statusLbl.BackgroundTransparency = 1
	statusLbl.Text = "Caixa: DESLIGADA | Alvo: ninguem\nfly/fly2 -> unfly/unfly2"
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
			statusLbl.Text = "Caixa: LIGADA | Alvo: " .. alvo .. "\n;fly->;unfly  |  ;fly2->;unfly2"
			statusLbl.TextColor3 = Color3.fromRGB(120, 220, 160)
		else
			statusLbl.Text = "Caixa: DESLIGADA | Alvo: " .. alvo .. "\nNao envia nada"
			statusLbl.TextColor3 = Color3.fromRGB(255, 140, 140)
		end
	end

	-- lista
	local pickGui = Instance.new("Frame")
	pickGui.Name = "V12PickList"
	pickGui.Size = UDim2.fromOffset(0, 0)
	pickGui.Position = UDim2.new(0.5, 0, 0.5, 0)
	pickGui.BackgroundColor3 = Color3.fromRGB(16, 16, 28)
	pickGui.BackgroundTransparency = 0.05
	pickGui.BorderSizePixel = 0
	pickGui.Visible = false
	pickGui.ZIndex = 30
	pickGui.ClipsDescendants = true
	pickGui.Parent = gui
	Instance.new("UICorner", pickGui).CornerRadius = UDim.new(0, 18)
	local ps = Instance.new("UIStroke", pickGui)
	ps.Color = Color3.fromRGB(180, 180, 255)
	ps.Thickness = 1.3
	ps.Transparency = 0.3

	local pTitle = Instance.new("TextLabel")
	pTitle.Size = UDim2.new(1, -50, 0, 40)
	pTitle.Position = UDim2.fromOffset(14, 0)
	pTitle.BackgroundTransparency = 1
	pTitle.Text = "Alvo da caixa"
	pTitle.TextColor3 = Color3.fromRGB(235, 235, 255)
	pTitle.TextSize = 15
	pTitle.Font = Enum.Font.GothamBold
	pTitle.TextXAlignment = Enum.TextXAlignment.Left
	pTitle.ZIndex = 31
	pTitle.Parent = pickGui

	local pClose = Instance.new("TextButton")
	pClose.Size = UDim2.fromOffset(28, 28)
	pClose.Position = UDim2.new(1, -36, 0, 6)
	pClose.BackgroundColor3 = RED
	pClose.BackgroundTransparency = 0.1
	pClose.Text = "X"
	pClose.TextColor3 = Color3.new(1,1,1)
	pClose.Font = Enum.Font.GothamBold
	pClose.TextSize = 14
	pClose.BorderSizePixel = 0
	pClose.ZIndex = 31
	pClose.Parent = pickGui
	Instance.new("UICorner", pClose).CornerRadius = UDim.new(0, 8)

	local pScroll = Instance.new("ScrollingFrame")
	pScroll.Size = UDim2.new(1, -20, 1, -50)
	pScroll.Position = UDim2.fromOffset(10, 42)
	pScroll.BackgroundTransparency = 1
	pScroll.BorderSizePixel = 0
	pScroll.ScrollBarThickness = 4
	pScroll.ZIndex = 31
	pScroll.Parent = pickGui
	Instance.new("UIListLayout", pScroll).Padding = UDim.new(0, 6)

	local function closePick()
		local t = TweenService:Create(pickGui, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.fromOffset(0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)
		})
		t:Play() t.Completed:Wait()
		pickGui.Visible = false
	end

	local function setTarget(plr)
		if not plr or plr == player then return end
		selectedTarget = plr
		-- padrao: ;unfly Nome (unfly2 e automatico no fly2)
		box.Text = ";unfly " .. plr.Name
		refreshStatus()
	end

	local function openPick()
		for _, c in ipairs(pScroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		local y = 0
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player then
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1, -4, 0, 36)
				btn.BackgroundColor3 = GLASS2
				btn.BackgroundTransparency = 0.15
				btn.Text = plr.Name
				btn.TextColor3 = Color3.new(1,1,1)
				btn.TextSize = 14
				btn.Font = Enum.Font.Gotham
				btn.BorderSizePixel = 0
				btn.AutoButtonColor = false
				btn.ZIndex = 32
				btn.Parent = pScroll
				Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
				btn.MouseButton1Click:Connect(function() setTarget(plr) closePick() end)
				btn.MouseEnter:Connect(function()
					TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(60, 65, 110)}):Play()
				end)
				btn.MouseLeave:Connect(function()
					TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundTransparency = 0.15, BackgroundColor3 = GLASS2}):Play()
				end)
				y = y + 42
			end
		end
		pScroll.CanvasSize = UDim2.new(0, 0, 0, math.max(y, 40))
		pickGui.Visible = true
		pickGui.Size = UDim2.fromOffset(0, 0)
		pickGui.Position = UDim2.new(0.5, 0, 0.5, 0)
		TweenService:Create(pickGui, TweenInfo.new(0.35, Enum.EasingStyle.Back), {
			Size = UDim2.fromOffset(270, 340),
			Position = UDim2.new(0.5, -135, 0.5, -170)
		}):Play()
	end

	pClose.MouseButton1Click:Connect(closePick)

	local function setBoxEnabled(on, openList)
		boxEnabled = on
		if on then
			toggleBtn.Text = "PARAR CAIXA DE TEXTO"
			TweenService:Create(toggleBtn, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {BackgroundColor3 = RED}):Play()
			if openList then openPick() end
		else
			toggleBtn.Text = "INICIAR CAIXA DE TEXTO"
			TweenService:Create(toggleBtn, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {BackgroundColor3 = GREEN}):Play()
		end
		refreshStatus()
	end

	toggleBtn.MouseButton1Click:Connect(function()
		if not boxEnabled then setBoxEnabled(true, true) else setBoxEnabled(false, false) end
	end)

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

	local function hookButtons()
		for _, d in ipairs(gui:GetDescendants()) do
			if d:IsA("TextButton") then
				local txt, up = d.Text or "", string.upper(d.Text or "")
				local plr = Players:FindFirstChild(txt)
				if plr and plr ~= player and not d:GetAttribute("V12Hook") then
					d:SetAttribute("V12Hook", true)
					d.MouseButton1Click:Connect(function() setTarget(plr) end)
				end
				if (up == "CONFIRMAR" or up == "CONFIRM") and not d:GetAttribute("V12Confirm") then
					d:SetAttribute("V12Confirm", true)
					d.MouseButton1Click:Connect(function()
						task.wait(0.05) forceAntiVoidOn()
						if not boxEnabled then setBoxEnabled(true, false) end
					end)
				end
				if (up == "INICIAR" or up == "START") and not up:find("CAIXA") and not d:GetAttribute("V12Start") then
					d:SetAttribute("V12Start", true)
					d.MouseButton1Click:Connect(function()
						forceAntiVoidOn()
						task.delay(0.3, forceAntiVoidOn)
						if not boxEnabled then setBoxEnabled(true, false) end
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
				if ev and ev:FindFirstChild("SayMessageRequest") then
					ev.SayMessageRequest:FireServer(msg, "All") sent = true
				end
			end)
		end
		return sent
	end

	-- detecta fly ou fly2 (nao qualquer msg)
	local function parseFly(text)
		if not text then return nil end
		local t = string.lower(tostring(text)):gsub("<[^>]+>", "")
		t = t:gsub("^%s+", ""):gsub("%s+$", "")
		-- fly2 primeiro (senao fly pega fly2)
		if t:find("fly2") or t:match("fly%s*2") then
			if t:find(";%s*fly2") or t:find(":%s*fly2") or t:find("/fly2") or t:match("^fly2") or t:find("fly2%s+me") or t:match("fly%s*2") then
				return 2
			end
		end
		if t:find(";%s*fly") or t:find(":%s*fly") or t:find("/fly") or t:match("^fly%s*$") or t:match("^fly%s+") or t:find("fly%s+me") then
			return 1
		end
		return nil
	end

	local function onChatted(speaker, message)
		if not boxEnabled or not selectedTarget then return end
		if not speaker or speaker == player then return end
		if speaker.UserId ~= selectedTarget.UserId then return end
		local kind = parseFly(message)
		if not kind then return end

		local name = speaker.Name
		local cmd
		if kind == 2 then
			cmd = ";unfly2 " .. name
		else
			-- usa a caixa se tiver ;unfly, senao monta
			local t = box.Text or ""
			if t:find("unfly2") then
				cmd = ";unfly " .. name
			elseif t:gsub("%s", "") ~= "" and t ~= ";unfly" and t ~= ";unfly " then
				-- se a caixa tem comando custom de unfly, usa
				if t:lower():find("unfly") and not t:lower():find("unfly2") then
					cmd = t
					if not cmd:lower():find(name:lower()) then cmd = ";unfly " .. name end
				else
					cmd = ";unfly " .. name
				end
			else
				cmd = ";unfly " .. name
			end
		end

		statusLbl.Text = name .. " usou fly" .. (kind == 2 and "2" or "") .. "!\nEnviando: " .. cmd
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

	setBoxEnabled(false, false)
	syncToggleColors()
	print("[VOID v12] SUPER OK | void -1.5M | ceu 16M | fly+fly2 | liquid glass")
end)
