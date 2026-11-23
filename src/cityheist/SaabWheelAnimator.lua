-- CITY HEIST: animacja czterech kol w testowym klonie Saaba.
-- Nie dotyka oryginalu w ServerStorage. Nie zmienia napedu LinearVelocity.
local RunService = game:GetService("RunService")
local WheelAnimator = {}

local NAMES = {"FL", "FR", "RL", "RR"}

function WheelAnimator.attach(car: Model)
    local chassis = assert(car:FindFirstChild("Chassis"), "Brak Chassis")
    local seat = assert(car:FindFirstChild("DriverSeat"), "Brak DriverSeat")
    local body = assert(car:FindFirstChild("SaabBody"), "Brak SaabBody")
    local wheels = {}

    for _, name in ipairs(NAMES) do
        local root = body:FindFirstChild(name)
        assert(root and root:IsA("BasePart"), "Brak kola " .. name)

        local members = {[root] = true}
        local parts = {root}
        for _, child in ipairs(root:GetDescendants()) do
            if child:IsA("BasePart") then
                members[child] = true
                table.insert(parts, child)
            end
        end

        -- Po SaabVisualFix kazda czesc kola ma spaw do Chassis.
        -- Usuwamy tylko spawy dotykajace czesci tego kola.
        for _, joint in ipairs(car:GetDescendants()) do
            if joint:IsA("WeldConstraint") then
                if (joint.Part0 and members[joint.Part0])
                    or (joint.Part1 and members[joint.Part1]) then
                    joint:Destroy()
                end
            end
        end

        local offsets = {}
        for _, part in ipairs(parts) do
            offsets[part] = root.CFrame:ToObjectSpace(part.CFrame)
            part.Anchored = false
            part.CanCollide = false
            part.Massless = true
        end
        for _, part in ipairs(parts) do
            if part ~= root then
                part.CFrame = root.CFrame * offsets[part]
                local weld = Instance.new("WeldConstraint")
                weld.Name = "WheelVisualWeld"
                weld.Part0 = root
                weld.Part1 = part
                weld.Parent = root
            end
        end

        local motor = Instance.new("Motor6D")
        motor.Name = "WheelSpin_" .. name
        motor.Part0 = chassis
        motor.Part1 = root
        motor.C0 = chassis.CFrame:ToObjectSpace(root.CFrame)
        motor.C1 = CFrame.identity
        motor.Parent = chassis

        table.insert(wheels, {
            name = name,
            motor = motor,
            base = motor.C0,
            radius = math.max(root.Size.Y / 2, 0.5),
            front = name == "FL" or name == "FR",
            angle = 0,
        })
    end

    local connection
    connection = RunService.Heartbeat:Connect(function(dt)
        if not car.Parent or not chassis.Parent then
            connection:Disconnect()
            return
        end
        local forward = chassis.CFrame.LookVector
        local speed = chassis.AssemblyLinearVelocity:Dot(forward)
        local steer = math.clamp(seat.SteerFloat, -1, 1)
        for _, wheel in ipairs(wheels) do
            wheel.angle = (wheel.angle + speed * dt / wheel.radius) % (2 * math.pi)
            local turn = wheel.front and (-steer * 0.35) or 0
            wheel.motor.C0 = wheel.base
                * CFrame.Angles(0, turn, 0)
                * CFrame.Angles(wheel.angle, 0, 0)
        end
    end)
    print("[SaabWheelAnimator] Animacja aktywna dla FL FR RL RR")
end

return WheelAnimator
