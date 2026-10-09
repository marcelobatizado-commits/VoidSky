-- VOID ULTRA v9.3 - loader + auto unfly no chat
local ok, err = pcall(function()
	local src = game:HttpGet("https://raw.githubusercontent.com/marcelobatizado-commits/VoidSky/cb4f59bfa58fa2d06c44f8269f946b8492e7ad43/VoidSky.lua")

	src = string.gsub(src, "%-100000", "-500000")
	src = string.gsub(src, "10000000", "15000000")
	src = string.gsub(src, "HEIGHT_TRIGGER = 100", "HEIGHT_TRIGGER = 30")
	src = string.gsub(src, "v9%.0", "v9.3")

	local fn, compileErr = loadstring(src)
	if not fn then
		error("Compile error: " .. tostring(compileErr))
	end
	fn()
end)

if not ok then
	warn("[VOID ULTRA] ERRO: " .. tostring(err))
	print("[VOID ULTRA] ERRO: " .. tostring(err))
	return
end

print("[VOID ULTRA] v9.3 OK | carregando auto-unfly...")

-- ============================================================
-- AUTO UNFLY: caixa de texto + escuta chat do alvo
-- ============================================================
task.spawn(function()
	local Players = game:GetService("Players")
	local TextChatService = game:GetService("TextChatService")
	local player = Players.LocalPlayer

	local gui = player:WaitForChild("PlayerGui"):WaitForChild("VoidSkyUltra", 15)
	if not gui then
		warn("[VOID ULTRA] GUI nao encontrada pro auto-unfly")
		return
	end

	local main = gui:FindFirstChildOfClass("Frame")
	if not main then return end
	local content = main:FindFirstChild("Frame") or main:FindFirstChildWhichIsA("Frame")
	-- content e o frame abaixo do titleBar
	for _, c in ipairs(main:GetChildren()) do
		if c:IsA("Frame") and c.Position.Y.Offset >= 40 then
			content = c
			break
		end
	end
	if not content then content = main end

	-- Aumenta altura do painel pra caber a caixa
	pcall(function()
		if main.Size.Y.Offset < 360 then
			main.Size = UDim2.fromOffset(main.Size.X.Offset, 370)
		end
	end)

	-- Label
	local label = Instance.new("TextLabel")
	label.Name = "UnflyLabel"
	label.Size = UDim2.new(1, -24, 0, 16)
	label.Position = UDim2.fromOffset(12, 122)
	label.BackgroundTransparency = 1
	label.Text = "Cmd unfly (auto no chat se alvo der fly):"
	label.TextColor3 = Color3.fromRGB(160, 165, 190)
	label.TextSize = 11
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = content

	-- Caixa de texto
	local box = Instance.new("TextBox")
	box.Name = "UnflyBox"
	box.Size = UDim2.new(1, -24, 0, 32)
	box.Position = UDim2.fromOffset(12, 140)
	box.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
	box.Text = ";unfly "
	box.PlaceholderText = ";unfly NomeDoAmigo"
	box.TextColor3 = Color3.fromRGB(230, 230, 255)
	box.PlaceholderColor3 = Color3.fromRGB(100, 105, 130)
	box.TextSize = 13
	box.Font = Enum.Font.Gotham
	box.ClearTextOnFocus = false
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.Parent = content
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
	local pad = Instance.new("UIPadding", box)
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)

	-- Status pequeno
	local unflyStatus = Instance.new("TextLabel")
	unflyStatus.Name = "UnflyStatus"
	unflyStatus.Size = UDim2.new(1, -24, 0, 14)
	unflyStatus.Position = UDim2.fromOffset(12, 174)
	unflyStatus.BackgroundTransparency = 1
	unflyStatus.Text = "Aguardando alguem digitar fly no chat..."
	unflyStatus.TextColor3 = Color3.fromRGB(120, 130, 160)
	unflyStatus.TextSize = 10
	unflyStatus.Font = Enum.Font.Gotham
	unflyStatus.TextXAlignment = Enum.TextXAlignment.Left
	unflyStatus.Parent = content

	-- Empurra botoes de baixo se existirem (INICIAR/PARAR)
	for _, b in ipairs(content:GetChildren()) do
		if b:IsA("TextButton") then
			local t = string.upper(b.Text or "")
			if t:find("INICIAR") or t:find("PARAR") or t:find("START") or t:find("STOP") then
				-- deixa no fundo
			end
		end
	end

	local lastSent = 0
	local COOLDOWN = 1.2

	local function sendChat(msg)
		if not msg or msg == "" or msg == ";unfly " then return false end
		msg = msg:gsub("^%s+", ""):gsub("%s+$", "")
		if #msg < 3 then return false end
		if tick() - lastSent < COOLDOWN then return false end
		lastSent = tick()

		local sent = false
		-- TextChat (chat novo)
		pcall(function()
			local channels = TextChatService:FindFirstChild("TextChannels")
			if channels then
				local ch = channels:FindFirstChild("RBXGeneral") or channels:FindFirstChild("RBXSystem")
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
		-- Chat legado
		if not sent then
			pcall(function()
				local ev = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
				if ev and ev:FindFirstChild("SayMessageRequest") then
					ev.SayMessageRequest:FireServer(msg, "All")
					sent = true
				end
			end)
		end
		-- StarterGui fallback
		if not sent then
			pcall(function()
				game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {Text = ""})
			end)
			pcall(function()
				local Players = game:GetService("Players")
				-- alguns executors
				if getconnections then end
			end)
		end
		return sent
	end

	local function isFlyMsg(text)
		if not text then return false end
		local t = string.lower(text)
		-- ;fly / ; Fly / fly nome / :fly etc
		if t:find(";%s*fly") then return true end
		if t:find(":%s*fly") then return true end
		if t:find("^%s*fly%s*") then return true end
		if t:find("%sfly%s+me") then return true end
		if t:find("hd%s*admin.*fly") then return true end
		return false
	end

	local function nameInCommand(speakerName)
		local cmd = box.Text or ""
		if cmd == "" then return true end -- se vazio, nao filtra
		-- se o comando tem o nome, so reage a esse player
		local lowerCmd = string.lower(cmd)
		local lowerName = string.lower(speakerName or "")
		if lowerCmd:find(";unfly") or lowerCmd:find("unfly") then
			-- se depois de unfly tem nome, confere
			local after = lowerCmd:match("unfly%s+(.+)")
			if after and #after > 1 then
				return lowerName:find(after:gsub("%s+", ""), 1, true) ~= nil
					or after:find(lowerName, 1, true) ~= nil
			end
		end
		return true
	end

	local function onPlayerChatted(speaker, message)
		if speaker == player then return end
		if not isFlyMsg(message) then return end
		if not nameInCommand(speaker.Name) then return end

		local cmd = box.Text
		if not cmd or cmd == "" or cmd == ";unfly " then
			cmd = ";unfly " .. speaker.Name
			box.Text = cmd
		end

		unflyStatus.Text = "Fly detectado de " .. speaker.Name .. " -> enviando..."
		unflyStatus.TextColor3 = Color3.fromRGB(255, 200, 80)

		task.defer(function()
			local okSend = sendChat(cmd)
			if okSend then
				unflyStatus.Text = "Enviado: " .. cmd
				unflyStatus.TextColor3 = Color3.fromRGB(100, 255, 140)
			else
				unflyStatus.Text = "Falha ao enviar chat (tente de novo)"
				unflyStatus.TextColor3 = Color3.fromRGB(255, 100, 100)
			end
		end)
	end

	-- Escuta chat legado (Chatted)
	local function hookPlayer(plr)
		if plr == player then return end
		pcall(function()
			plr.Chatted:Connect(function(msg)
				onPlayerChatted(plr, msg)
			end)
		end)
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		hookPlayer(plr)
	end
	Players.PlayerAdded:Connect(hookPlayer)

	-- Escuta TextChat novo
	pcall(function()
		TextChatService.MessageReceived:Connect(function(message)
			local source = message.TextSource
			if not source then return end
			local plr = Players:GetPlayerByUserId(source.UserId)
			if not plr or plr == player then return end
			onPlayerChatted(plr, message.Text or "")
		end)
	end)

	print("[VOID ULTRA] Auto-unfly ativo | escreva ;unfly Nome na caixa")
end)
