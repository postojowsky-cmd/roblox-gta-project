-- City Heist MVP: non-invasive bank/wanted integration audit.
-- Does not modify robbery, economy, police or garage systems.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local SSS = game:GetService("ServerScriptService")

local PREFIX = "[CityHeistMVP]"
local function log(...)
    print(PREFIX, ...)
end
local function checkBank(index)
    local city = Workspace:FindFirstChild("CityBlockout")
    local locations = city and city:FindFirstChild("GameplayLocations")
    local bank = locations and locations:FindFirstChild("Bank_" .. index)
    local interior = bank and bank:FindFirstChild("GeneratedInterior")
    local setup = interior and interior:FindFirstChild("RobberySetup")
    local safe = setup and setup:FindFirstChild("RobberySafe")
    local prompt = safe and safe:FindFirstChild("RobberyPrompt")
    if not (safe and safe:IsA("BasePart") and prompt and prompt:IsA("ProximityPrompt")) then
        warn(PREFIX, "Bank_" .. index .. " nie ma kompletnego sejfu/promptu")
        return
    end
    log("Bank_" .. index, "gotowy; prompt:", prompt.Enabled, "czas przytrzymania:", prompt.HoldDuration)
    prompt.Triggered:Connect(function(player)
        log("Proba napadu:", player.Name, "Bank_" .. index)
    end)
end

for _, name in ipairs({"BankRobberyController", "BankAlarmEffects", "WantedSystem", "PoliceChaseSystem", "CityHeistEconomy"}) do
    local scriptObj = SSS:FindFirstChild(name)
    if scriptObj and scriptObj:IsA("Script") and scriptObj.Enabled then
        log(name, "wlaczony")
    else
        warn(PREFIX, name, "brak lub wylaczony")
    end
end
for _, name in ipairs({"BankRobberyEvent", "WantedEvent", "PoliceArrestEvent"}) do
    if RS:FindFirstChild(name) then log(name, "OK")
    else warn(PREFIX, "Brak RemoteEvent:", name) end
end
for i = 1, 3 do checkBank(i) end

local function observe(player)
    local function changed(attribute)
        log(player.Name, attribute, tostring(player:GetAttribute(attribute)))
    end
    for _, attribute in ipairs({"WantedLevel", "WantedCrime", "WantedSuccess"}) do
        player:GetAttributeChangedSignal(attribute):Connect(function()
            changed(attribute)
        end)
    end
    task.spawn(function()
        local stats = player:WaitForChild("leaderstats", 20)
        local money = stats and stats:WaitForChild("Money", 20)
        if not money then warn(PREFIX, player.Name, "Brak leaderstats.Money"); return end
        local previous = money.Value
        money:GetPropertyChangedSignal("Value"):Connect(function()
            local current = money.Value
            log(player.Name, "Money", previous, "->", current, "roznica", current - previous)
            previous = current
        end)
    end)
end
Players.PlayerAdded:Connect(observe)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(observe, player) end
log("Audyt gotowy. Przetestuj napad w Play; logi pokaza przebieg.")
