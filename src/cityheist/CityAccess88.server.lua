-- CITY HEIST / STEP 88: connect the existing parking lots and fuel station
-- to the closest city roads when the corridor is clear. Add wayfinding signs.
-- Studio preview only. No edits to road meshes, garages, heist systems.
local RS=game:GetService("RunService")
if not RS:IsStudio() then return end
local W=game:GetService("Workspace")
if W:GetAttribute("CityAccess89Running") then return end
W:SetAttribute("CityAccess89Running",true)
print("[CityAccess89] START")

local city=W:WaitForChild("CityBlockout",30)
local roads=city and city:WaitForChild("Roads",30)
local ground=city and city:WaitForChild("Ground",30)
local infrastructure=W:WaitForChild("CityHeistInfrastructure86",100)
if not (city and roads and ground and infrastructure) then
    warn("[CityAccess89] No roads, ground or infrastructure; skipped")
    return
end
-- Infrastructure's folder is created before all three models are placed.
local waited=0
while waited<30 do
    local count=0
    for _,m in ipairs(infrastructure:GetChildren()) do
        if m:IsA("Model") then count+=1 end
    end
    if count>=3 then break end
    waited+=.5
    task.wait(.5)
end
local sites={}
for _,m in ipairs(infrastructure:GetChildren()) do
    if m:IsA("Model") and (m.Name=="FuelStation" or string.find(m.Name,"PublicParking_",1,true)==1) then
        table.insert(sites,m)
    end
end
table.sort(sites,function(a,b)return a.Name<b.Name end)
if #sites==0 then
    warn("[CityAccess89] No infrastructure models available; skipped")
    return
end

local prev=W:FindFirstChild("CityHeistAccess88")
if prev then prev:Destroy() end
local folder=Instance.new("Folder")
folder.Name="CityHeistAccess88"
folder:SetAttribute("StudioPreview",true)
folder.Parent=W

local blockers={}
for _,obj in ipairs({W:FindFirstChild("CityHeistPrefabCity74"),W:FindFirstChild("CityHeistInfill81"),
    W:FindFirstChild("CityHeistStreetscape79"),city:FindFirstChild("GameplayLocations"),
    city:FindFirstChild("Downtown"),city:FindFirstChild("CityLocations"),
    city:FindFirstChild("CityGarages"),city:FindFirstChild("CityDecorativeHomes"),
    W:FindFirstChild("CityPrison"),W:FindFirstChild("CityHeistGarageSpawned"),folder}) do
    if obj then table.insert(blockers,obj) end
end
local checks=OverlapParams.new()
checks.FilterType=Enum.RaycastFilterType.Include
checks.FilterDescendantsInstances=blockers
local terrainParams=RaycastParams.new()
terrainParams.FilterType=Enum.RaycastFilterType.Include
terrainParams.FilterDescendantsInstances={ground}
local function yAt(x,z)
    local hit=W:Raycast(Vector3.new(x,400,z),Vector3.new(0,-800,0),terrainParams)
    if hit and hit.Normal.Y>.85 then return hit.Position.Y end
    return nil
end
local function createPart(parent,name,size,cf,color,material,solid)
    local part=Instance.new("Part")
    part.Name=name
    part.Size=size
    part.CFrame=cf
    part.Anchored=true
    part.CanCollide=solid~=false
    part.Color=color
    part.Material=material or Enum.Material.SmoothPlastic
    part.TopSurface=Enum.SurfaceType.Smooth
    part.BottomSurface=Enum.SurfaceType.Smooth
    part.Parent=parent
    return part
end
local roadParts={}
for _,part in ipairs(roads:GetDescendants()) do
    if part:IsA("BasePart") and part.Size.X>6 and part.Size.Z>6 then
        table.insert(roadParts,part)
    end
end

local function closestRoad(position)
    local bestDist=math.huge
    local bestPoint=nil
    for _,road in ipairs(roadParts) do
        local v=road.CFrame:PointToObjectSpace(Vector3.new(position.X,road.Position.Y,position.Z))
        local clamped=Vector3.new(
            math.clamp(v.X,-road.Size.X/2,road.Size.X/2),0,
            math.clamp(v.Z,-road.Size.Z/2,road.Size.Z/2))
        local q=road.CFrame:PointToWorldSpace(clamped)
        local delta=Vector3.new(q.X-position.X,0,q.Z-position.Z)
        if delta.Magnitude<bestDist then
            bestDist=delta.Magnitude
            bestPoint=q
        end
    end
    return bestPoint,bestDist
end

local function addMarker(site,textValue,accent)
    local cf,sz=site:GetBoundingBox()
    local location=cf.Position
    local anchor=createPart(folder,"MarkerAnchor",Vector3.new(1,1,1),
        CFrame.new(location.X,cf.Position.Y+sz.Y/2+18,location.Z),
        accent,Enum.Material.Neon,false)
    anchor.Transparency=1
    anchor.CanTouch=false
    anchor.CanQuery=false
    local sign=Instance.new("BillboardGui")
    sign.Name="CityWayfinding"
    sign.Size=UDim2.fromOffset(200,52)
    sign.StudsOffsetWorldSpace=Vector3.new(0,2,0)
    sign.AlwaysOnTop=true
    sign.MaxDistance=450
    sign.Parent=anchor
    local label=Instance.new("TextLabel")
    label.Name="SiteLabel"
    label.Size=UDim2.fromScale(1,1)
    label.BackgroundColor3=Color3.fromRGB(19,32,43)
    label.BackgroundTransparency=.12
    label.TextColor3=Color3.fromRGB(255,255,255)
    label.TextScaled=true
    label.Font=Enum.Font.GothamBold
    label.Text=textValue
    label.Parent=sign
    local corner=Instance.new("UICorner")
    corner.CornerRadius=UDim.new(0,12)
    corner.Parent=label
    local outline=Instance.new("UIStroke")
    outline.Thickness=2
    outline.Color=accent
    outline.Parent=label
end

local linked=0
for _,site in ipairs(sites) do
    local name=site.Name=="FuelStation" and "STACJA PALIW" or
        string.upper(site.Name:gsub("PublicParking_","PARKING "))
    addMarker(site,name,site.Name=="FuelStation" and
        Color3.fromRGB(26,196,233) or Color3.fromRGB(255,202,67))
    local pad=site:FindFirstChild("Forecourt") or site:FindFirstChild("ParkingSurface")
    if pad and pad:IsA("BasePart") then
        local center=pad.Position
        local roadPoint,distance=closestRoad(center)
        if roadPoint and distance>1 and distance<100 then
            local toRoad=Vector3.new(roadPoint.X-center.X,0,roadPoint.Z-center.Z)
            local direction=toRoad.Unit
            -- Ray from the site center to the near edge of its rectangular pad.
            local t=math.huge
            if math.abs(direction.X)>.0001 then t=math.min(t,pad.Size.X/2/math.abs(direction.X)) end
            if math.abs(direction.Z)>.0001 then t=math.min(t,pad.Size.Z/2/math.abs(direction.Z)) end
            local a=Vector3.new(center.X,0,center.Z)+direction*(t-1.2)
            local b=Vector3.new(roadPoint.X,0,roadPoint.Z)-direction*1.2
            local span=(b-a).Magnitude
            if span>=1 and span<65 then
                local mid=(a+b)*.5
                local ya=yAt(a.X,a.Z)
                local yb=yAt(b.X,b.Z)
                local ym=yAt(mid.X,mid.Z)
                if ya and yb and ym
                    and math.abs(ya-ym)<1.4 and math.abs(yb-ym)<1.4 then
                    -- Bridge now reaches into the original pad and the roadway
                    -- (the old corridor stopped 1.2 studs short at both ends).
                    -- Width is adaptive so a wider entrance never destroys a
                    -- previously passable route when there are obstacles.
                    local targetTop=pad.Position.Y+pad.Size.Y/2
                    local top=(ym+.30+targetTop)/2
                    local pos=Vector3.new(mid.X,top-.12,mid.Z)
                    local cf=CFrame.lookAt(pos,pos+direction)
                    local drivewayLength=span+2.8
                    local chosenWidth=nil
                    for _,width in ipairs({15,12,9}) do
                        local conflicts=W:GetPartBoundsInBox(
                            cf+Vector3.new(0,1.5,0),
                            Vector3.new(width+1,3.1,span+.3),checks)
                        if #conflicts==0 then chosenWidth=width;break end
                    end
                    if chosenWidth then
                        createPart(folder,"Driveway_"..site.Name,
                            Vector3.new(chosenWidth,.24,drivewayLength),cf,
                            Color3.fromRGB(61,65,69),Enum.Material.Asphalt)
                        -- Subtle edge lines make the entrance look deliberate.
                        -- Purely visual; no raised kerb for Saab wheels.
                        for _,side in ipairs({-1,1}) do
                            local offset=cf.RightVector*(side*(chosenWidth/2-.38))
                            local marker=createPart(folder,"DrivewayEdge_"..site.Name,
                                Vector3.new(.24,.025,math.max(1,span-1)),
                                cf+offset+Vector3.new(0,.14,0),
                                Color3.fromRGB(218,221,219),
                                Enum.Material.SmoothPlastic,false)
                            marker.CanQuery=false
                        end
                        linked+=1
                        print(string.format(
                            "[CityAccess89] CONNECTED %s | %.1f studs, width %.0f, seamless pad overlap",
                            site.Name,drivewayLength,chosenWidth))
                    else
                        print("[CityAccess89] SKIPPED driveway "..site.Name.." | blocked corridor")
                    end
                else
                    print("[CityAccess89] SKIPPED driveway "..site.Name.." | uneven ground")
                end
            else
                print("[CityAccess89] SKIPPED driveway "..site.Name.." | no usable road gap")
            end
        else
            print("[CityAccess89] SKIPPED driveway "..site.Name.." | road too distant")
        end
    end
end
print(string.format("[CityAccess89] DONE: %d markers, %d refined driveway links; existing roads unchanged",
    #sites,linked))
