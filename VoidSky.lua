-- ============================================================
-- VOID ULTRA v10.0
-- Base void/ceu + anti-void auto no INICIAR
-- Caixa de texto com botao INICIAR/PARAR
-- Alvo = pessoa escolhida na lista
-- ============================================================

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- ---------- 1) CARREGA SCRIPT BASE ----------
local ok, err = pcall(function()
	local src = game:HttpGet("https://raw.githubusercontent.com/marcelobatizado-commits/VoidSky/cb4f59bfa58fa2d06c44f8269f946b8492e7ad43/VoidSky.lua")
	src = string.gsub(src, "%-100000", "-500000")
	src = string.gsub(src, "10000000", "15000000")
	src = string.gsub(src, "HEIGHT_TRIGGER = 100", "HEIGHT_TRIGGER = 30")
	src = string.gsub(src, "v9%.0", "v10.0")
	src = string.gsub(src, "VOID ULTRA v9", "VOID ULTRA v10")
	local fn, cErr = loadstring(src)
	if not fn then error("Compile: " .. tostring(cErr)) end
	fn()
end)

if not ok then
	warn("[VOID v10] ERRO base: " .. tostring(err))
	print("[VOID v10] ERRO base: " .. tostring(err))
	return
end

print("[VOID v10] base OK")

-- ---------- 2) ADDON: caixa + alvo + antivoid auto ----------
task.spawn(function()
	local pg = player:WaitForChild("PlayerGui")
	local gui = pg:WaitForChild("VoidSkyUltra", 25)
	if not gui then
		warn("[VOID v10] GUI nao encontrada")
		return
	end

	local main = gui:FindFirstChildOfClass("Frame")
	if not main then return end

	local content = nil
	for _, c in ipairs(main:GetChildren()) do
		if c:IsA("Frame") and c.Position.Y.Offset >= 40 then
			content = c
			break
		end
	end
	if not content then
		for _, c in ipairs(main:GetChildren()) do
			if c:IsA("Frame") and #c:GetChildren() > 2 then
				content = c
				break
			end
		end
	end
	if not content then content = main end

	-- limpa addon antigo
	for _, n in ipairs({"UnflyLabel", "UnflyBox", "UnflyStatus", "UnflyToggle", "V10Bar"}) do
		local o = content:FindFirstChild(n) or main:FindFirstChild(n)
		if o then o:Destroy() end
	end

	pcall(function()
		main.Size = UDim2.fromOffset(math.max(main.Size.X.Offset, 310), 430)
	end)

	-- ===== estado =====
	local selectedTarget = nil -- Player escolhido na lista
	local boxEnabled = true   -- comeca LIGADO (botao vermelho = parar)
	local lastSent = 0

	-- ===== UI =====
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
	local boxStroke = Instance.new("UIStroke", box)
	boxStroke.Color = Color3.fromRGB(90, 100, 255)
	boxStroke.Thickness = 1.2
	boxStroke.Transparency = 0.35
	local boxPad = Instance.new("UIPadding", box)
	boxPad.PaddingLeft = UDim.new(0, 10)
	boxPad.PaddingRight = UDim.new(0, 10)

	-- Botao PARAR / INICIAR caixa de texto
	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Name = "UnflyToggle"
	toggleBtn.Size = UDim2.new(1, -24, 0, 34)
	toggleBtn.Position = UDim2.fromOffset(12, 170)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(210, 50, 50) -- vermelho = ativo (pode parar)
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
	statusLbl.Text = "Caixa: LIGADA | Alvo: ninguem\nEscolha alguem na lista (INICIAR)"
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

	toggleBtn.MouseButton1Click:Connect(function()
		setBoxEnabled(not boxEnabled)
	end)

	local function setTarget(plr)
		if not plr or plr == player then return end
		selectedTarget = plr
		local t = box.Text or ""
		if t == "" or t == ";unfly " or t == ";unfly" then
			box.Text = ";unfly " .. plr.Name
		end
		refreshStatus()
		print("[VOID v10] Alvo da caixa: " .. plr.Name)
	end

	-- ===== forcar Anti-Void + God ON =====
	local function forceAntiVoidOn()
		-- protecao propria (independente do botao)
		pcall(function()
			workspace.FallenPartsDestroyHeight = 0 / 0
		end)
		pcall(function()
			if workspace.FallenPartsDestroyHeight == workspace.FallenPartsDestroyHeight then
				workspace.FallenPartsDestroyHeight = -math.huge
			end
		end)

		-- clica nos botoes se estiverem OFF
		for _, b in ipairs(content:GetDescendants()) do
			if b:IsA("TextButton") then
				local txt = string.upper(b.Text or "")
				if txt:find("ANTI VOID") and txt:find("OFF") then
					pcall(function() b.MouseButton1Click:Fire() end)
					-- fallback visual
					pcall(function()
						b.Text = "ANTI VOID: ON"
						b.BackgroundColor3 = Color3.fromRGB(40, 180, 90)
					end)
				end
				if txt:find("GOD MODE") and txt:find("OFF") then
					pcall(function() b.MouseButton1Click:Fire() end)
					pcall(function()
						b.Text = "GOD MODE: ON"
						b.BackgroundColor3 = Color3.fromRGB(40, 180, 90)
					end)
				end
			end
		end
	end

	-- loop leve de anti-void enquanto existir GUI
	local avConn = RunService.Heartbeat:Connect(function()
		if not gui.Parent then return end
		pcall(function()
			workspace.FallenPartsDestroyHeight = 0 / 0
		end)
	end)
	gui.Destroying:Connect(function()
		if avConn then avConn:Disconnect() end
	end)

	-- ===== hook lista de players =====
	local function hookButtons()
		for _, d in ipairs(gui:GetDescendants()) do
			if d:IsA("TextButton") then
				local txt = d.Text or ""
				local up = string.upper(txt)

				-- nome de player na lista
				local plr = Players:FindFirstChild(txt)
				if plr and plr ~= player and not d:GetAttribute("V10Hook") then
					d:SetAttribute("V10Hook", true)
					d.MouseButton1Click:Connect(function()
						setTarget(plr)
					end)
				end

				-- Confirmar
				if (up == "CONFIRMAR" or up == "CONFIRM") and not d:GetAttribute("V10Confirm") then
					d:SetAttribute("V10Confirm", true)
					d.MouseButton1Click:Connect(function()
						-- se ja clicou num nome, mantem; senao tenta pelo texto selecionado
						task.wait(0.05)
						forceAntiVoidOn()
						if selectedTarget then
							setTarget(selectedTarget)
						end
					end)
				end

				-- INICIAR principal -> forca antivoid
				if (up == "INICIAR" or up == "START") and not d:GetAttribute("V10Start") then
					d:SetAttribute("V10Start", true)
					d.MouseButton1Click:Connect(function()
						forceAntiVoidOn()
						task.delay(0.3, forceAntiVoidOn)
						task.delay(1, forceAntiVoidOn)
					end)
				end
			end
		end
	end

	hookButtons()
	gui.DescendantAdded:Connect(function()
		task.defer(hookButtons)
	end)

	-- detecta alvo pelo titulo quando o script base muda o texto
	local function scanTitleForTarget()
		for _, d in ipairs(main:GetDescendants()) do
			if d:IsA("TextLabel") and d.Text then
				local txt = d.Text
				for _, plr in ipairs(Players:GetPlayers()) do
					if plr ~= player and txt:find(plr.Name, 1, true) then
						if not txt:find("VOID") and not txt:find("Status") and not txt:find("Caixa") then
							if #txt <= #plr.Name + 10 then
								setTarget(plr)
								return
							end
						end
					end
				end
			end
		end
	end

	for _, d in ipairs(main:GetDescendants()) do
		if d:IsA("TextLabel") then
			d:GetPropertyChangedSignal("Text"):Connect(function()
				task.defer(scanTitleForTarget)
			end)
		end
	end

	-- ===== chat =====
	local function sendChat(msg)
		if type(msg) ~= "string" then return false end
		msg = msg:gsub("^%s+", ""):gsub("%s+$", "")
		if #msg < 2 then return false end
		if tick() - lastSent < 1.0 then return false end
		lastSent = tick()

		local sent = false
		pcall(function()
			local channels = TextChatService:FindFirstChild("TextChannels")
			if channels then
				local ch = channels:FindFirstChild("RBXGeneral")
				if not ch then
					for _, c in ipairs(channels:GetChildren()) do
						if c:IsA("TextChannel") then ch = c break end
					end
				end
				if ch then
					ch:SendAsync(msg)
					sent = true
				end
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
		if t:find(";%s*fly") then return true end
		if t:find(":%s*fly") then return true end
		if t:find("/fly") then return true end
		if t:match("^%s*fly%s*$") then return true end
		if t:match("^%s*fly%s+") then return true end
		if t:find("fly%s+me") then return true end
		return false
	end

	local function onChatted(speaker, message)
		if not boxEnabled then return end -- PARAR caixa = nao faz nada
		if not selectedTarget then return end
		if not speaker or speaker == player then return end
		if speaker.UserId ~= selectedTarget.UserId then return end
		if not isFlyMsg(message) then return end

		local cmd = box.Text
		if not cmd or cmd:gsub("%s", "") == "" or cmd == ";unfly" or cmd == ";unfly " then
			cmd = ";unfly " .. speaker.Name
		end

		statusLbl.Text = selectedTarget.Name .. " digitou fly! Enviando...\n" .. cmd
		statusLbl.TextColor3 = Color3.fromRGB(255, 200, 80)

		task.defer(function()
			local okSend = sendChat(cmd)
			if okSend then
				statusLbl.Text = "Enviado: " .. cmd .. "\nAlvo: " .. selectedTarget.Name
				statusLbl.TextColor3 = Color3.fromRGB(100, 255, 140)
			else
				statusLbl.Text = "Falha ao enviar no chat\nTente de novo"
				statusLbl.TextColor3 = Color3.fromRGB(255, 90, 90)
			end
			task.delay(2.5, refreshStatus)
		end)
	end

	local function hookPlayer(plr)
		if plr == player then return end
		pcall(function()
			plr.Chatted:Connect(function(msg)
				onChatted(plr, msg)
			end)
		end)
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

	setBoxEnabled(true) -- comeca ligado
	print("[VOID v10] pronto | caixa LIGADA | escolha alvo na lista")
end)
