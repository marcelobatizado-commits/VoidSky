-- VOID ULTRA v9.3.1
-- 1) Carrega script base
-- 2) Caixa de texto: voce digita a mensagem (;unfly Nome)
-- 3) So reage se a PESSOA ESCOLHIDA NA LISTA escrever fly no chat
-- 4) Ai manda no chat EXATAMENTE o texto da caixa

local ok, err = pcall(function()
	local src = game:HttpGet("https://raw.githubusercontent.com/marcelobatizado-commits/VoidSky/cb4f59bfa58fa2d06c44f8269f946b8492e7ad43/VoidSky.lua")
	src = string.gsub(src, "%-100000", "-500000")
	src = string.gsub(src, "10000000", "15000000")
	src = string.gsub(src, "HEIGHT_TRIGGER = 100", "HEIGHT_TRIGGER = 30")
	src = string.gsub(src, "v9%.0", "v9.3")
	local fn, cErr = loadstring(src)
	if not fn then error("Compile: " .. tostring(cErr)) end
	fn()
end)

if not ok then
	warn("[VOID ULTRA] ERRO: " .. tostring(err))
	print("[VOID ULTRA] ERRO: " .. tostring(err))
	return
end

print("[VOID ULTRA] v9.3.1 base OK")

task.spawn(function()
	local Players = game:GetService("Players")
	local TextChatService = game:GetService("TextChatService")
	local player = Players.LocalPlayer
	local pg = player:WaitForChild("PlayerGui")

	local gui = pg:WaitForChild("VoidSkyUltra", 20)
	if not gui then
		warn("[VOID ULTRA] GUI nao achada")
		return
	end

	local main = gui:FindFirstChildOfClass("Frame")
	if not main then return end

	local content = nil
	for _, c in ipairs(main:GetChildren()) do
		if c:IsA("Frame") and c.Name ~= "TitleBar" and c.Position.Y.Offset >= 40 then
			content = c
			break
		end
	end
	if not content then
		for _, c in ipairs(main:GetChildren()) do
			if c:IsA("Frame") and #c:GetChildren() > 3 then
				content = c
				break
			end
		end
	end
	if not content then content = main end

	-- remove versao antiga se reexecutar
	for _, n in ipairs({"UnflyLabel", "UnflyBox", "UnflyStatus"}) do
		local old = content:FindFirstChild(n) or main:FindFirstChild(n)
		if old then old:Destroy() end
	end

	pcall(function()
		main.Size = UDim2.fromOffset(math.max(main.Size.X.Offset, 300), 390)
	end)

	local label = Instance.new("TextLabel")
	label.Name = "UnflyLabel"
	label.Size = UDim2.new(1, -24, 0, 16)
	label.Position = UDim2.fromOffset(12, 118)
	label.BackgroundTransparency = 1
	label.Text = "Mensagem auto (caixa de texto):"
	label.TextColor3 = Color3.fromRGB(160, 165, 190)
	label.TextSize = 11
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 5
	label.Parent = content

	local box = Instance.new("TextBox")
	box.Name = "UnflyBox"
	box.Size = UDim2.new(1, -24, 0, 34)
	box.Position = UDim2.fromOffset(12, 136)
	box.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
	box.Text = ";unfly "
	box.PlaceholderText = "ex: ;unfly NomeDaPessoa"
	box.TextColor3 = Color3.fromRGB(240, 240, 255)
	box.PlaceholderColor3 = Color3.fromRGB(100, 105, 130)
	box.TextSize = 14
	box.Font = Enum.Font.Gotham
	box.ClearTextOnFocus = false
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.ZIndex = 5
	box.Parent = content
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
	local stroke = Instance.new("UIStroke", box)
	stroke.Color = Color3.fromRGB(90, 100, 255)
	stroke.Thickness = 1
	stroke.Transparency = 0.4
	local pad = Instance.new("UIPadding", box)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)

	local unflyStatus = Instance.new("TextLabel")
	unflyStatus.Name = "UnflyStatus"
	unflyStatus.Size = UDim2.new(1, -24, 0, 16)
	unflyStatus.Position = UDim2.fromOffset(12, 172)
	unflyStatus.BackgroundTransparency = 1
	unflyStatus.Text = "Escolha alguem na lista. Alvo: ninguem"
	unflyStatus.TextColor3 = Color3.fromRGB(120, 130, 160)
	unflyStatus.TextSize = 11
	unflyStatus.Font = Enum.Font.Gotham
	unflyStatus.TextXAlignment = Enum.TextXAlignment.Left
	unflyStatus.ZIndex = 5
	unflyStatus.Parent = content

	-- ===== pessoa escolhida na lista =====
	local selectedTarget = nil -- Player

	local function setTarget(plr)
		selectedTarget = plr
		if plr then
			unflyStatus.Text = "Alvo: " .. plr.Name .. " | se digitar fly -> manda a caixa"
			unflyStatus.TextColor3 = Color3.fromRGB(100, 255, 160)
			-- completa a caixa se estiver so ";unfly "
			local t = box.Text or ""
			if t == "" or t == ";unfly " or t == ";unfly" then
				box.Text = ";unfly " .. plr.Name
			end
		else
			unflyStatus.Text = "Escolha alguem na lista. Alvo: ninguem"
			unflyStatus.TextColor3 = Color3.fromRGB(120, 130, 160)
		end
	end

	-- Descobre alvo pelo titulo (quando inicia fica "Nome" ou com icone)
	local function scanTitle()
		for _, d in ipairs(main:GetDescendants()) do
			if d:IsA("TextLabel") and d.Text then
				local txt = d.Text
				-- titulo ativo tipo "NomeDoPlayer" depois do start
				for _, plr in ipairs(Players:GetPlayers()) do
					if plr ~= player and txt:find(plr.Name, 1, true) and not txt:find("VOID") and not txt:find("Status") then
						if txt:find("Escolha") then continue end
						-- se o texto e so o nome ou comeca com simbolo + nome
						if txt == plr.Name or txt:match("^%W*%s*" .. plr.Name) or txt:find(plr.Name) then
							if #txt < #plr.Name + 8 then
								setTarget(plr)
								return
							end
						end
					end
				end
			end
		end
	end

	-- Hook nos botoes da lista de players (nome do player + Confirmar)
	local function hookListGui()
		for _, d in ipairs(gui:GetDescendants()) do
			if d:IsA("TextButton") then
				local txt = d.Text or ""
				-- botao com nome de player
				local plr = Players:FindFirstChild(txt)
				if plr and plr ~= player then
					if not d:GetAttribute("UnflyHooked") then
						d:SetAttribute("UnflyHooked", true)
						d.MouseButton1Click:Connect(function()
							setTarget(plr)
						end)
					end
				end
				-- botao Confirmar
				if string.lower(txt) == "confirmar" or string.lower(txt) == "confirm" then
					if not d:GetAttribute("UnflyHookedConfirm") then
						d:SetAttribute("UnflyHookedConfirm", true)
						d.MouseButton1Click:Connect(function()
							task.wait(0.15)
							scanTitle()
						end)
					end
				end
			end
		end
	end

	hookListGui()
	gui.DescendantAdded:Connect(function(d)
		task.defer(hookListGui)
	end)

	-- tambem observa mudanca no titulo
	for _, d in ipairs(main:GetDescendants()) do
		if d:IsA("TextLabel") then
			d:GetPropertyChangedSignal("Text"):Connect(function()
				task.defer(scanTitle)
			end)
		end
	end

	-- ===== enviar chat =====
	local lastSent = 0
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
		local t = string.lower(tostring(text))
		-- tira tags de chat rico se tiver
		t = t:gsub("<[^>]+>", "")
		if t:find(";%s*fly") then return true end
		if t:find(":%s*fly") then return true end
		if t:find("/fly") then return true end
		if t:match("^%s*fly%s*$") then return true end
		if t:match("^%s*fly%s+") then return true end -- fly Nome
		if t:find("fly%s+me") then return true end
		return false
	end

	-- SO se for a pessoa da lista
	local function onChatted(speaker, message)
		if not speaker or speaker == player then return end
		if not selectedTarget then return end
		if speaker ~= selectedTarget and speaker.Name ~= selectedTarget.Name then return end
		if not isFlyMsg(message) then return end

		local cmd = box.Text
		if not cmd or cmd:gsub("%s", "") == "" or cmd == ";unfly" or cmd == ";unfly " then
			cmd = ";unfly " .. speaker.Name
		end

		unflyStatus.Text = selectedTarget.Name .. " digitou fly! Enviando caixa..."
		unflyStatus.TextColor3 = Color3.fromRGB(255, 200, 80)

		task.defer(function()
			local okSend = sendChat(cmd)
			if okSend then
				unflyStatus.Text = "Chat enviado: " .. cmd
				unflyStatus.TextColor3 = Color3.fromRGB(100, 255, 140)
			else
				unflyStatus.Text = "Falhou enviar no chat"
				unflyStatus.TextColor3 = Color3.fromRGB(255, 90, 90)
			end
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

	print("[VOID ULTRA] v9.3.1 auto-unfly: so pessoa da lista + texto da caixa")
end)
