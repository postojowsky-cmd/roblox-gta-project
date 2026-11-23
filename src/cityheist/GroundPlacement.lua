-- City Heist: bezpieczne ustawianie pojazdu względem PhysicsSupport.
-- Nie modyfikuje oryginału w ServerStorage ani sterownika jazdy.
local GroundPlacement = {}

function GroundPlacement.place(car: Model, groundPosition: Vector3, clearance: number?)
    assert(car and car:IsA("Model"), "Oczekiwano modelu samochodu")
    local support = car:FindFirstChild("PhysicsSupport")
    assert(support and support:IsA("BasePart"), "Brak PhysicsSupport")
    local gap = clearance or 0.3
    assert(gap >= 0, "Odstęp nie może być ujemny")

    -- Zachowujemy obrót i wzajemne położenie wszystkich części.
    local pivot = car:GetPivot()
    local supportBottom = support.Position.Y - support.Size.Y / 2
    local targetBottom = groundPosition.Y + gap
    local dy = targetBottom - supportBottom
    local dx = groundPosition.X - pivot.Position.X
    local dz = groundPosition.Z - pivot.Position.Z
    car:PivotTo(CFrame.new(dx, dy, dz) * pivot)
    return car
end

return GroundPlacement
