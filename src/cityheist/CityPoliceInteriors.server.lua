-- CITY HEIST / CityPoliceInteriors v1
-- Creates walk-in interiors for the two ORIGINAL police station buildings.
-- Does not alter PoliceChaseSystem, WantedSystem, arrest handling or roads.
local W=game:GetService("Workspace")
local city=W:WaitForChild("CityBlockout",30)
local locations=city and city:WaitForChild("GameplayLocations",30)
if not locations then return end

local function part(parent,name,size,cf,color,material,collidable,transparency)
    local p=Instance.new("Part")
    p.Name=name;p.Anchored=true;p.Size=size;p.CFrame=cf;p.Color=color
    p.Material=material or Enum.Material.SmoothPlastic
    p.CanCollide=collidable~=false;p.Transparency=transparency or 0
    p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
    p.Parent=parent
    return p
end
local function sign(parent,name,caption,cf,w)
    local p=part(parent,name,Vector3.new(w,2,.25),cf,
        Color3.fromRGB(30,53,70),nil,false)
    local s=Instance.new("SurfaceGui");s.Face=Enum.NormalId.Front;s.Parent=p
    local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1)
    t.BackgroundTransparency=1;t.Text=caption;t.TextScaled=true
    t.TextColor3=Color3.fromRGB(246,249,253)
    t.Font=Enum.Font.GothamBold;t.Parent=s
end
local function findBase(model,name)
    local p=model:FindFirstChild(name,true)
    return p and p:IsA("BasePart") and p or nil
end
local function build(model,index)
    local body=findBase(model,"BuildingBody")
    local entrance=findBase(model,"EntranceDoor")
    local foundation=findBase(model,"Foundation")
    if not (body and entrance and foundation) then
        warn("[PoliceInterior] Police_"..index..
            " missing original body, entrance or foundation; no model altered")
        return
    end
    if math.min(body.Size.X,body.Size.Z)<22 then
        warn("[PoliceInterior] Police_"..index.." footprint too small; skipped")
        return
    end
    -- Rotate logical +X / -Z layout so -Z is ALWAYS the real existing door.
    local localDoor=body.CFrame:PointToObjectSpace(entrance.Position)
    local yaw
    if math.abs(localDoor.X)>math.abs(localDoor.Z) then
        yaw=localDoor.X>0 and -math.pi/2 or math.pi/2
    else
        yaw=localDoor.Z>0 and math.pi or 0
    end
    local width=math.abs(yaw)==math.pi/2 and body.Size.Z or body.Size.X
    local depth=math.abs(yaw)==math.pi/2 and body.Size.X or body.Size.Z
    local floorY=foundation.Position.Y+foundation.Size.Y/2
    local shell=body.CFrame*CFrame.Angles(0,yaw,0)
    local at=function(x,y,z)
        return shell*CFrame.new(x,floorY-body.Position.Y+y,z)
    end
    local old=model:FindFirstChild("CityHeistPoliceInterior")
    if old then old:Destroy() end
    local interior=Instance.new("Model")
    interior.Name="CityHeistPoliceInterior"
    interior.Parent=model
    local dark=Color3.fromRGB(31,48,65)
    local wall=Color3.fromRGB(203,213,222)
    local tile=Color3.fromRGB(113,123,132)
    local metal=Color3.fromRGB(55,66,77)
    local hw=width/2
    local hd=depth/2
    local doorWidth=math.clamp(entrance.Size.X,7,11)
    local doorHalf=doorWidth/2+1
    local height=math.clamp(body.Size.Y,17,25)
    -- Only now replace the known solid placeholder, keeping original model parts.
    body.Transparency=1;body.CanCollide=false;body.CanTouch=false
    entrance.Transparency=1;entrance.CanCollide=false;entrance.CanTouch=false
    part(interior,"Floor",Vector3.new(width-.7,.22,depth-.7),
        at(0,.13,0),tile,Enum.Material.Slate)
    part(interior,"LeftWall",Vector3.new(.8,height,depth),
        at(-hw,height/2,0),wall)
    part(interior,"RightWall",Vector3.new(.8,height,depth),
        at(hw,height/2,0),wall)
    part(interior,"BackWall",Vector3.new(width,height,.8),
        at(0,height/2,hd),wall)
    local sideWidth=hw-doorHalf
    for _,s in ipairs({-1,1}) do
        part(interior,"StorefrontSolid",Vector3.new(sideWidth,height,.65),
            at(s*(doorHalf+sideWidth/2),height/2,-hd),wall)
    end
    part(interior,"DoorHeader",Vector3.new(doorHalf*2,height-12,.65),
        at(0,12+(height-12)/2,-hd),wall)
    for _,s in ipairs({-1,1}) do
        part(interior,"DoorFrame",Vector3.new(.4,12,1.1),
            at(s*doorHalf,6,-hd),dark,Enum.Material.Metal)
    end
    part(interior,"Threshold",Vector3.new(doorHalf*2-.5,.22,3),
        at(0,.12,-hd+.9),metal,Enum.Material.Metal)
    sign(interior,"PoliceSign","POLICJA",at(0,height-2,-hd-.52),math.min(20,width*.5))
    -- Divided accessible zone: front reception and rear interview/holding cells.
    local partitionZ=math.min(6,depth*.16)
    local wallSpan=hw-6
    for _,s in ipairs({-1,1}) do
        part(interior,"InteriorPartition",Vector3.new(wallSpan,.75 and height-1 or height,.6),
            at(s*(6+wallSpan/2),(height-1)/2,partitionZ),wall)
    end
    part(interior,"RearDoorHeader",Vector3.new(12,height-11,.6),
        at(0,11+(height-11)/2,partitionZ),wall)
    sign(interior,"RearSign","POKOJE SLUZBOWE",at(0,13,partitionZ-.5),11)
    -- Reception desk to the side, never across the centerline entrance.
    local deskX=-math.max(7,width*.25)
    part(interior,"ReceptionDesk",Vector3.new(math.min(12,width*.30),3.5,3.6),
        at(deskX,1.75,-hd+11),dark,Enum.Material.Wood)
    part(interior,"ReceptionTop",Vector3.new(math.min(12,width*.30)+.7,.25,4),
        at(deskX,3.65,-hd+11),Color3.fromRGB(133,143,151))
    part(interior,"DeskMonitor",Vector3.new(2.5,2,.25),
        at(deskX,5,-hd+12),Color3.fromRGB(27,36,47),Enum.Material.Metal)
    part(interior,"DeskKeyboard",Vector3.new(2.8,.14,1),
        at(deskX,3.9,-hd+10),Color3.fromRGB(37,43,49))
    -- Waiting chairs opposite the reception.
    local chairX=math.max(7,width*.26)
    for i=1,3 do
        local z=-hd+8+i*3.5
        part(interior,"WaitingSeat",Vector3.new(3,.55,2.8),
            at(chairX,2,z),dark)
        part(interior,"WaitingBack",Vector3.new(3,3,.45),
            at(chairX,3.2,z+1.4),dark)
    end
    -- Back office: desks on the left, evidence racks and lockers on right.
    local backZ=partitionZ+(hd-partitionZ)*.52
    part(interior,"OfficeDesk",Vector3.new(8,.7,3.5),
        at(-hw+8,3,backZ),Color3.fromRGB(107,85,69),Enum.Material.Wood)
    part(interior,"OfficeMonitor",Vector3.new(2.8,2,.2),
        at(-hw+8,4.4,backZ),metal,Enum.Material.Metal)
    for i=1,3 do
        part(interior,"EvidenceLocker",Vector3.new(2.7,7,3),
            at(hw-4.5,3.5,partitionZ+4+i*4),
            Color3.fromRGB(88,103,115),Enum.Material.Metal)
    end
    -- Accessible cells are visually suggested at back; doors are OPEN.
    local cellWidth=math.max(6,math.min(11,width*.18))
    for i=1,2 do
        local x=(i==1 and -1 or 1)*math.min(hw-7,cellWidth+2)
        local z=hd-5
        part(interior,"CellRearWall",Vector3.new(cellWidth,10,.5),
            at(x,5,z+3),metal,Enum.Material.Metal)
        for _,side in ipairs({-1,1}) do
            part(interior,"CellSide",Vector3.new(.4,10,7),
                at(x+side*cellWidth/2,5,z),metal,Enum.Material.Metal)
        end
        part(interior,"CellBed",Vector3.new(3,1,5),
            at(x,1,z+1),Color3.fromRGB(88,110,125))
        sign(interior,"CellSign","CELA "..i,at(x,11,z-3),math.min(cellWidth-1,7))
    end
    -- Safe roof: existing facades remain; broad solid cover provides indoor feel.
    part(interior,"Ceiling",Vector3.new(width,.6,depth),at(0,height-.3,0),wall)
    for _,z in ipairs({-hd+12,0,hd-9}) do
        local lightPart=part(interior,"CeilingLight",Vector3.new(9,.25,2),
            at(0,height-.74,z),Color3.fromRGB(251,247,225),Enum.Material.Neon,false)
        local light=Instance.new("SurfaceLight")
        light.Face=Enum.NormalId.Bottom;light.Range=25;light.Brightness=2
        light.Parent=lightPart
    end
    print("[PoliceInterior] Police_"..index..
        " entrance, reception, office and cells generated inside original building")
end

-- Existing police mechanics are separate scripts in ServerScriptService.
-- Build after city layout has had time to place the buildings.
task.wait(5)
for i=1,2 do
    local station=locations:FindFirstChild("Police_"..i)
    if station and station:IsA("Model") then
        local ok,err=pcall(build,station,i)
        if not ok then warn("[PoliceInterior] Police_"..i..": "..tostring(err)) end
    end
end
