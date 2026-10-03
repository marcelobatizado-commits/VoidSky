-- Void Ultra v9.2
-- Void Y=-500000 | Céu Y=15000000 | Trigger Y>=30
-- Martelo some: tenta 5s → TP até martelo → volta pra posição

local src = game:HttpGet("https://raw.githubusercontent.com/marcelobatizado-commits/VoidSky/cb4f59bfa58fa2d06c44f8269f946b8492e7ad43/VoidSky.lua")

-- Config
src = src:gsub("local POS_VOID = CFrame%.new%(0, %-100000, 0%)", "local POS_VOID = CFrame.new(0, -500000, 0)")
src = src:gsub("local POS_SKY%s*=%s*CFrame%.new%(0,%s*10000000,%s*0%)", "local POS_SKY  = CFrame.new(0, 15000000, 0)")
src = src:gsub("local HEIGHT_TRIGGER%s*=%s*100", "local HEIGHT_TRIGGER = 30")
src = src:gsub("v9%.0", "v9.2")

-- Anti-void mais forte (protege em qualquer altura baixa)
src = src:gsub("root%.Position%.Y < %-200", "root.Position.Y < 100")

-- Recover: ao TP pro martelo, guarda posicao e volta (startHammerRecover ja chama moveTo)
-- Reforca o tryGrabWithTimeout pra voltar sempre
src = src:gsub(
	"return findTool%(%) ~= nil\nend\n\nlocal function startHammerRecover",
	[[if savedHold then end
	return findTool() ~= nil
end

local function startHammerRecover]]
)

-- Patch tryGrabWithTimeout: salvar hold antes do TP
src = src:gsub(
	"local function tryGrabWithTimeout%(%)\n\tlocal t0 = tick%(%)",
	"local function tryGrabWithTimeout()\n\tlocal savedHoldCF = currentHoldCF\n\tlocal t0 = tick()"
)

-- Depois de pegar com sucesso no timeout loop do shop, volta
src = src:gsub(
	"if tryGrabOnce%(%) then return true end\n\t\t\ttask%.wait%(0%.25%)",
	"if tryGrabOnce() then\n\t\t\t\tif savedHoldCF and running then task.wait(0.15) moveTo(savedHoldCF) end\n\t\t\t\treturn true\n\t\t\tend\n\t\t\ttask.wait(0.25)"
)

loadstring(src)()
print("\u2705 VOID ULTRA v9.2 | Void Y=-500000 | Sky=15M | Trigger=30 | Recover 5s+TP+volta")
