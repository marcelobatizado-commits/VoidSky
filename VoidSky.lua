-- VOID ULTRA v9.2 - loader simples (funciona no Delta)
local ok, err = pcall(function()
	local src = game:HttpGet("https://raw.githubusercontent.com/marcelobatizado-commits/VoidSky/cb4f59bfa58fa2d06c44f8269f946b8492e7ad43/VoidSky.lua")

	-- Void Y = -500000
	src = string.gsub(src, "%-100000", "-500000")
	-- Ceu Y = 15000000
	src = string.gsub(src, "10000000", "15000000")
	-- Trigger Y >= 30
	src = string.gsub(src, "HEIGHT_TRIGGER = 100", "HEIGHT_TRIGGER = 30")
	-- Versao
	src = string.gsub(src, "v9%.0", "v9.2")

	local fn, compileErr = loadstring(src)
	if not fn then
		error("Compile error: " .. tostring(compileErr))
	end
	fn()
end)

if not ok then
	warn("[VOID ULTRA] ERRO: " .. tostring(err))
	print("[VOID ULTRA] ERRO: " .. tostring(err))
else
	print("[VOID ULTRA] v9.2 OK | Void=-500000 | Sky=15M | Trigger=30")
end
