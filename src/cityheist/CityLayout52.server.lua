-- City Heist step 52: distribute existing gameplay buildings around the city.
-- Runs only in Studio Play sessions; no destructive editing to saved Studio map.
-- Whole models move via PivotTo so interiors, prompts and robbery systems stay intact.
local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end
local workspace=game:GetService("Workspace")
local city=workspace:WaitForChild("CityBlockout",20)
local locations=city and city:WaitForChild("GameplayLocations",20)
if not locations then warn("[CityLayout52] Missing GameplayLocations");return end
local names={"Bank_1","Bank_2","Bank_3","Shop_1","Shop_2","Shop_3","Shop_4","Police_1","Police_2","Dealership_1","Dealership_2"}
local models={}
for _,name in ipairs(names) do
    local model=locations:FindFirstChild(name)
    if model and model:IsA("Model") then
        models[name]=model
    else
        warn("[CityLayout52] Missing model: "..name)
    end
end
local sum=Vector3.zero
local count=0
for _,model in pairs(models) do sum+=model:GetPivot().Position;count+=1 end
if count==0 then return end
local center=sum/count
-- Spread across four sectors, keeping banks and shops separated.
local targets={
    Bank_1=Vector2.new(-490,-420),
    Bank_2=Vector2.new(520,-380),
    Bank_3=Vector2.new(430,470),
    Shop_1=Vector2.new(-220,-490),
    Shop_2=Vector2.new(260,-130),
    Shop_3=Vector2.new(-450,200),
    Shop_4=Vector2.new(100,510),
    Police_1=Vector2.new(-550,500),
    Police_2=Vector2.new(570,120),
    Dealership_1=Vector2.new(-100,130),
    Dealership_2=Vector2.new(250,-520),
}
local function overlapsBuildings(candidate, model, placed)
    local cf,size=model:GetBoundingBox()
    local delta=candidate.Position-cf.Position
    local half=Vector2.new(size.X/2+12,size.Z/2+12)
    for _,item in ipairs(placed) do
        if math.abs(candidate.Position.X-item.x)<half.X+item.hx
            and math.abs(candidate.Position.Z-item.z)<half.Y+item.hz then
            return true
        end
    end
    return false
end
local placed={}
for _,name in ipairs(names) do
    local model=models[name]
    if model then
        local target=targets[name]
        local oldPivot=model:GetPivot()
        local _,bounds=model:GetBoundingBox()
        local base=Vector3.new(center.X+target.X,oldPivot.Position.Y,center.Z+target.Y)
        local chosen
        -- Check multiple nearby placements, avoiding overlaps among relocated buildings.
        for radius=0,240,60 do
            for angle=0,7 do
                local theta=angle*math.pi/4
                local p=base+Vector3.new(math.cos(theta)*radius,0,math.sin(theta)*radius)
                local candidate=CFrame.new(p)*oldPivot.Rotation
                if not overlapsBuildings(candidate,model,placed) then
                    chosen=candidate;break
                end
            end
            if chosen then break end
        end
        if chosen then
            model:PivotTo(chosen)
            model:SetAttribute("CityLayout52Moved",true)
            local newCF,newSize=model:GetBoundingBox()
            table.insert(placed,{x=newCF.Position.X,z=newCF.Position.Z,hx=newSize.X/2+12,hz=newSize.Z/2+12})
            print(string.format("[CityLayout52] %s relocated to X %.0f Z %.0f",name,newCF.Position.X,newCF.Position.Z))
        else
            warn("[CityLayout52] Could not find safe separation for "..name)
        end
    end
end
print("[CityLayout52] Distribution complete: "..#placed.." buildings. Studio Play only; original saved map unchanged.")
