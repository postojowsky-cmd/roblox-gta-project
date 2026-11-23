-- City Heist: jednorazowa instalacja osobnego Saaba do jazdy.
-- Uruchamiaj install() tylko z Command Bar w trybie Edit.
-- Model wystawowy i oryginalny prototyp pozostaja nietkniete.
local ServerStorage = game:GetService("ServerStorage")
local Fix = require(script.Parent:WaitForChild("SaabVisualFix"))

local Installer = {}
Installer.SOURCE = "Saab_9_3_Turbo_X_Driveable"
Installer.TARGET = "Saab_9_3_Turbo_X_Ready"

function Installer.install()
    assert(not game:GetService("RunService"):IsRunning(),
        "Uruchom instalacje w Edit, nie podczas Play")
    local folder = ServerStorage:WaitForChild("CityHeistVehicles")
    local source = assert(folder:FindFirstChild(Installer.SOURCE), "Nie znaleziono prototypu Saaba")
    assert(source:IsA("Model"), "Prototyp nie jest modelem")
    if folder:FindFirstChild(Installer.TARGET) then
        warn("[SaabInstaller] Docelowy model juz istnieje. Niczego nie nadpisano.")
        return folder[Installer.TARGET], false
    end
    local copy = source:Clone()
    copy.Name = Installer.TARGET
    local ok, count, removed = pcall(function()
        return Fix.raiseBody(copy, 1.71623)
    end)
    if not ok then
        copy:Destroy()
        error("[SaabInstaller] Blad przygotowania kopii: " .. tostring(count))
    end
    copy.Parent = folder
    print(("[SaabInstaller] Utworzono %s | czesci: %d | usuniete spawy: %d"):format(
        Installer.TARGET, count, removed))
    print("[SaabInstaller] Zapisz gre (Ctrl+S / Publish), aby zachowac model.")
    return copy, true
end

return Installer
