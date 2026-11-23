-- City Heist shops v3: walk-in convenience stores attached to existing shop facades.
-- No teleportation; checkout interaction only. Non-destructive to original buildings.
local Builder={}
local function make(parent,name,size,cf,color,material,collide,transparency)
    local p=Instance.new("Part")
    p.Name=name;p.Size=size;p.CFrame=cf;p.Anchored=true
    p.Color=color;p.Material=material or Enum.Material.SmoothPlastic
    p.CanCollide=collide~=false;p.Transparency=transparency or 0;p.Parent=parent
    return p
end
local function textSign(parent,name,text,cf,size)
    local p=make(parent,name,size,cf,Color3.fromRGB(25,45,55),Enum.Material.SmoothPlastic,false)
    local gui=Instance.new("SurfaceGui");gui.Face=Enum.NormalId.Front;gui.Parent=p
    local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1)
    t.BackgroundTransparency=1;t.Text=text;t.TextScaled=true;t.Font=Enum.Font.GothamBold
    t.TextColor3=Color3.fromRGB(245,245,245);t.Parent=gui
end
function Builder.build(shop,index)
    local body=shop:FindFirstChild("BuildingBody")
    local entrance=shop:FindFirstChild("EntranceDoor")
    local foundation=shop:FindFirstChild("Foundation")
    if not (body and body:IsA("BasePart") and entrance and entrance:IsA("BasePart") and foundation and foundation:IsA("BasePart")) then
        error("Missing original BuildingBody / EntranceDoor / Foundation in Shop_"..index)
    end
    local old=shop:FindFirstChild("CityHeistShopTerminal")
    if old then old:Destroy() end
    local portal=shop:FindFirstChild("CityHeistShopEntrance")
    if portal then portal:Destroy() end
    local previous=shop:FindFirstChild("CityHeistFittedInterior")
    if previous then previous:Destroy() end
    local room=Instance.new("Model");room.Name="CityHeistFittedInterior";room.Parent=shop
    -- Use the REAL building footprint, not its bounding box or a separate building.
    local floorY=foundation.Position.Y+foundation.Size.Y/2
    local cf=body.CFrame
    local function at(x,y,z)
        return cf*CFrame.new(x,floorY-body.Position.Y+y,z)
    end
    -- The original solid body prevents entry: replace its collision with fitted walls.
    body.Transparency=1;body.CanCollide=false;body.CanTouch=false
    entrance.Transparency=1;entrance.CanCollide=false;entrance.CanTouch=false
    local wall=Color3.fromRGB(205,211,216)
    local trim=Color3.fromRGB(39,51,59)
    make(room,"LeftWall",Vector3.new(1,23,60),at(-32,11.5,0),wall)
    make(room,"RightWall",Vector3.new(1,23,60),at(32,11.5,0),wall)
    make(room,"RearWall",Vector3.new(65,23,1),at(0,11.5,29.5),wall)
    -- Existing windows remain visible; center opening matches original EntranceDoor.
    for _,x in ipairs({-28,28}) do
        make(room,"FrontEdge",Vector3.new(9,23,0.6),at(x,11.5,-30),wall)
    end
    for _,x in ipairs({-10,10}) do
        make(room,"FrontPillar",Vector3.new(7,23,0.6),at(x,11.5,-30),wall)
    end
    make(room,"EntranceHeader",Vector3.new(13,9,0.6),at(0,18.5,-30),wall)
    make(room,"GlassDoorOpen",Vector3.new(5,12,0.25),
        at(6,6,-27)*CFrame.Angles(0,math.rad(80),0),
        Color3.fromRGB(150,215,235),Enum.Material.Glass,false,0.6)
    -- Interior tile on top of existing foundation.
    make(room,"TileFloor",Vector3.new(62,0.15,58),at(0,0.075,0),
        Color3.fromRGB(101,111,118),Enum.Material.Slate)
    -- Checkout near the front right; aisle from the front door stays clear.
    make(room,"CheckoutCounter",Vector3.new(13,3.4,4),at(21,1.7,-20),trim)
    make(room,"CheckoutTop",Vector3.new(13.5,0.3,4.5),at(21,3.55,-20),
        Color3.fromRGB(126,135,139))
    make(room,"CashRegister",Vector3.new(2.5,1.2,2),at(20,4.3,-20),
        Color3.fromRGB(28,34,40))
    local checkout=make(room,"CheckoutInteraction",Vector3.new(2,2,2),
        at(20,4,-23),Color3.fromRGB(0,190,140),Enum.Material.Neon,false,1)
    local prompt=Instance.new("ProximityPrompt")
    prompt.Name="OpenShop";prompt.ActionText="Kup produkty"
    prompt.ObjectText="Kasa sklepu "..index;prompt.MaxActivationDistance=9
    prompt.HoldDuration=0.3;prompt.RequiresLineOfSight=false;prompt.Parent=checkout
    -- Two aisles, product packages and refrigerators.
    for _,x in ipairs({-13,5}) do
        for _,z in ipairs({-8,3,14}) do
            make(room,"ShelfBase",Vector3.new(10,0.5,3),at(x,0.7,z),
                Color3.fromRGB(95,74,58),Enum.Material.Wood)
            for _,y in ipairs({2.5,5}) do
                make(room,"Shelf",Vector3.new(10,0.3,3),at(x,y,z),
                    Color3.fromRGB(118,87,62),Enum.Material.Wood)
                for k=1,7 do
                    make(room,"Product",Vector3.new(0.8,1.4,1),
                        at(x-4.6+k*1.15,y+0.85,z),
                        Color3.fromRGB(35+k*25,60+k*17,190-k*17))
                end
            end
        end
    end
    for _,z in ipairs({-20,-12,-4,4}) do
        make(room,"Fridge",Vector3.new(3,9,6),at(-28,4.5,z),
            Color3.fromRGB(49,72,87),Enum.Material.Metal)
        make(room,"FridgeGlass",Vector3.new(0.2,7,5),at(-26.4,4.5,z),
            Color3.fromRGB(145,211,231),Enum.Material.Glass,false,0.5)
    end
    -- Stockroom across the rear, with a physical opening at x=16.
    make(room,"StockroomPartitionLeft",Vector3.new(44,15,0.6),
        at(-10,7.5,20),wall)
    make(room,"StockroomPartitionRight",Vector3.new(9,15,0.6),
        at(27.5,7.5,20),wall)
    make(room,"StockroomDoorHeader",Vector3.new(12,8,0.6),
        at(17,19,20),wall)
    textSign(room,"StockroomSign","ZAPLECZE",at(17,13,19.5),Vector3.new(10,2,0.2))
    for _,x in ipairs({-23,-10,3}) do
        make(room,"StorageRack",Vector3.new(8,4,3),at(x,2.2,25),
            Color3.fromRGB(112,90,65),Enum.Material.Wood)
        make(room,"StorageBoxes",Vector3.new(4,3,2),at(x,5.7,25),
            Color3.fromRGB(167,126,75),Enum.Material.Wood)
    end
    local safe=make(room,"FutureRobberySafe",Vector3.new(3,4,3),
        at(26,2,25),Color3.fromRGB(68,76,83),Enum.Material.Metal)
    safe:SetAttribute("FutureShopRobbery",true)
    for _,z in ipairs({-19,-4,12,25}) do
        local lamp=make(room,"CeilingLight",Vector3.new(12,0.3,2),
            at(0,22.2,z),Color3.fromRGB(255,249,221),Enum.Material.Neon,false)
        local light=Instance.new("SurfaceLight");light.Face=Enum.NormalId.Bottom
        light.Brightness=2;light.Range=25;light.Parent=lamp
    end
    print("[CityHeistShop] Shop_"..index.." fitted to original building; walk-in entrance ready")
    return checkout
end
return Builder
