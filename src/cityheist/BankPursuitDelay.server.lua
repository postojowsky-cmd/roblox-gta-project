-- City Heist MVP: police begins pursuit AFTER bank robbery, not during safe cracking.
-- Separate from existing Studio-only BankRobberyController / WantedSystem.
-- Bank robbery lasts 30 seconds. Wanted is deferred until success or a short timeout.
local Players = game:GetService("Players")
local ROBBERY_SECONDS = 30
local BUFFER_SECONDS = 3

local function attach(player)
    local protectedUntil = 0
    local token = 0
    local pendingWanted = 0
    local releasing = false

    local function suppress()
        if releasing or os.clock() >= protectedUntil then return end
        local current = player:GetAttribute("WantedLevel") or 0
        if current > 0 then
            pendingWanted = math.max(pendingWanted, current)
            player:SetAttribute("WantedLevel", 0)
        end
    end

    local function release(expected)
        if token ~= expected or not player.Parent then return end
        protectedUntil = 0
        releasing = true
        local wanted = math.clamp(pendingWanted, 0, 5)
        pendingWanted = 0
        if wanted > 0 then
            player:SetAttribute("WantedLevel", wanted)
        end
        releasing = false
        print("[CityHeistMVP] Koniec ochrony podczas napadu:", player.Name, "Wanted:", wanted)
    end

    player:GetAttributeChangedSignal("WantedLevel"):Connect(suppress)

    player:GetAttributeChangedSignal("WantedCrime"):Connect(function()
        token += 1
        local currentToken = token
        pendingWanted = math.max(pendingWanted, player:GetAttribute("WantedLevel") or 0, 2)
        protectedUntil = os.clock() + ROBBERY_SECONDS + BUFFER_SECONDS
        suppress()
        print("[CityHeistMVP] Napad:", player.Name, "policja ruszy po zakonczeniu.")
        task.delay(ROBBERY_SECONDS + BUFFER_SECONDS, function()
            release(currentToken)
        end)
    end)

    player:GetAttributeChangedSignal("WantedSuccess"):Connect(function()
        if os.clock() < protectedUntil then
            pendingWanted = math.max(pendingWanted, 3)
            -- Wait a moment so the player receives the reward before police pursue.
            local currentToken = token
            task.delay(2, function()
                release(currentToken)
            end)
        end
    end)
end

Players.PlayerAdded:Connect(attach)
for _, player in ipairs(Players:GetPlayers()) do attach(player) end
print("[CityHeistMVP] Bank pursuit delay enabled (30s + 3s buffer)")
