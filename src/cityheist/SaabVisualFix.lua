-- CITY HEIST: eksperymentalna korekta wygladu Saaba.
-- Zmienia TYLKO klon, nigdy model z ServerStorage.
local Fix = {}

function Fix.raiseBody(car: Model, deltaY: number)
    assert(car and car:IsA("Model"), "Wymagany Model")
    assert(deltaY > 0 and deltaY < 4, "Nieprawidlowa korekta")
    local body = car:FindFirstChild("SaabBody")
    local chassis = car:FindFirstChild("Chassis")
    assert(body and chassis and chassis:IsA("BasePart"), "Brak SaabBody/Chassis")

    local bodyParts = {}
    for _, inst in ipairs(body:GetDescendants()) do
        if inst:IsA("BasePart") then
            table.insert(bodyParts, inst)
        end
    end
    assert(#bodyParts > 0, "Brak czesci nadwozia")

    -- Usuwamy wylacznie spawy laczace karoserie z podwoziem;
    -- wewnetrzne spawy karoserii zostaja zachowane.
    local removed = 0
    for _, inst in ipairs(car:GetDescendants()) do
        if inst:IsA("WeldConstraint") then
            local a, b = inst.Part0, inst.Part1
            if (a == chassis and b and b:IsDescendantOf(body))
                or (b == chassis and a and a:IsDescendantOf(body)) then
                inst:Destroy()
                removed += 1
            end
        end
    end

    for _, part in ipairs(bodyParts) do
        part.CFrame = part.CFrame + Vector3.new(0, deltaY, 0)
        part.Anchored = false
        part.CanCollide = false
        part.Massless = true

        local weld = Instance.new("WeldConstraint")
        weld.Name = "SaabBodyTestWeld"
        weld.Part0 = chassis
        weld.Part1 = part
        weld.Parent = part
    end
    return #bodyParts, removed
end

return Fix
