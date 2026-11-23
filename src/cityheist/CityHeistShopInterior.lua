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
    -- Solid glass storefront: only the central doorway is passable.
    for _,x in ipairs({-19.5,19.5}) do
        make(room,"StorefrontGlass",Vector3.new(19,22,0.35),at(x,11,-30.25),
            Color3.fromRGB(141,210,229),Enum.Material.Glass,true,0.58)
        for _,y in ipairs({0.5,12,22}) do
            make(room,"WindowCrossbar",Vector3.new(19,0.3,0.6),at(x,y,-30.4),trim)
        end
    end
    for _,x in ipairs({-29,-10,10,29}) do
        make(room,"WindowMullion",Vector3.new(0.35,22,0.7),at(x,11,-30.45),trim)
    end
    make(room,"GlassDoorOpen",Vector3.new(5,12,0.25),
        at(6,6,-27)*CFrame.Angles(0,math.rad(80),0),
        Color3.fromRGB(150,215,235),Enum.Material.Glass,false,0.6)
    -- Entrance: double open glass leaves, door hardware and threshold.
    make(room,"EntranceThreshold",Vector3.new(12,0.18,3),at(0,0.13,-29),
        Color3.fromRGB(105,110,115),Enum.Material.Metal)
    make(room,"EntranceTopFrame",Vector3.new(13,0.4,0.8),at(0,13.8,-30.3),trim)
    for _,x in ipairs({-6,6}) do
        make(room,"EntranceSideFrame",Vector3.new(0.4,14,0.8),at(x,7,-30.3),trim)
    end
    make(room,"DoorLeafLeft",Vector3.new(5,12,0.2),
        at(-6.5,6,-27)*CFrame.Angles(0,math.rad(-75),0),
        Color3.fromRGB(158,221,235),Enum.Material.Glass,false,0.5)
    make(room,"DoorHandleLeft",Vector3.new(0.25,1.6,0.25),
        at(-4.8,6,-27.2),Color3.fromRGB(200,205,210),Enum.Material.Metal,false)
    -- Interior tile on top of existing foundation.
    make(room,"TileFloor",Vector3.new(62,0.15,58),at(0,0.075,0),
        Color3.fromRGB(101,111,118),Enum.Material.Slate)
    -- Checkout near the front right; aisle from the front door stays clear.
    -- Counter along the side wall, rotated to face the customer aisle.
    make(room,"CheckoutCounter",Vector3.new(4,3.4,13),at(24,1.7,-15),trim)
    make(room,"CheckoutTop",Vector3.new(4.6,0.3,13.5),at(24,3.55,-15),
        Color3.fromRGB(139,146,146))
    make(room,"CashRegister",Vector3.new(2.2,1.2,2.5),
        at(23.5,4.3,-19)*CFrame.Angles(0,math.rad(-90),0),
        Color3.fromRGB(28,34,40))
    make(room,"CardTerminal",Vector3.new(0.7,0.6,1),
        at(21.5,4.2,-17),Color3.fromRGB(37,48,60))
    local checkout=make(room,"CheckoutInteraction",Vector3.new(1.5,1.5,1.5),
        at(20.8,4,-18),Color3.fromRGB(0,190,140),Enum.Material.Neon,false,1)
    local prompt=Instance.new("ProximityPrompt")
    prompt.Name="OpenShop";prompt.ActionText="Kup produkty"
    prompt.ObjectText="Kasa sklepu "..index;prompt.MaxActivationDistance=9
    prompt.HoldDuration=0.3;prompt.RequiresLineOfSight=false;prompt.Parent=checkout
    -- Finishing details: cashier sign, ceiling accents, aisle headers.
    textSign(room,"CheckoutSign","KASA",at(24,11,-29.5),Vector3.new(9,2,0.2))
    for _,z in ipairs({-18,-2,14}) do
        make(room,"CeilingAccent",Vector3.new(59,0.3,0.6),at(0,22.6,z),
            Color3.fromRGB(56,80,88),Enum.Material.Metal,false)
    end
    for _,x in ipairs({-13,5}) do
        make(room,"AisleHeader",Vector3.new(10,2,0.4),at(x,7,17),
            Color3.fromRGB(35,112,98),Enum.Material.SmoothPlastic,false)
    end
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
    make(room,"StockroomPartitionLeft",Vector3.new(44,23,0.6),
        at(-10,11.5,20),wall)
    make(room,"StockroomPartitionRight",Vector3.new(9,23,0.6),
        at(27.5,11.5,20),wall)
    -- 12-stud-wide walk-through opening at x=17, with full-height header.
    make(room,"StockroomDoorHeader",Vector3.new(12,12,0.6),
        at(17,17,20),wall)
    for _,x in ipairs({11,23}) do
        make(room,"StockroomDoorFrame",Vector3.new(0.4,11,0.9),
            at(x,5.5,19.7),trim)
    end
    textSign(room,"StockroomSign","ZAPLECZE",at(17,12.5,19.5),Vector3.new(10,2,0.2))
    -- Backroom storage shelves with two levels of stock.
    for _,x in ipairs({-24,-13}) do
        for _,y in ipairs({2,5}) do
            make(room,"StorageRack",Vector3.new(8,0.45,3),
                at(x,y,25),Color3.fromRGB(112,90,65),Enum.Material.Wood)
            for k=1,3 do
                make(room,"StorageBox",Vector3.new(1.8,1.7,2),
                    at(x-3+k*2,y+1,25),
                    Color3.fromRGB(150+k*8,115+k*6,70),Enum.Material.Wood)
            end
        end
    end
    -- Manager's desk and an open laptop.
    make(room,"OfficeDesk",Vector3.new(9,0.55,3.2),
        at(5,3.3,25),Color3.fromRGB(106,74,53),Enum.Material.Wood)
    for _,x in ipairs({1.3,8.7}) do
        make(room,"DeskLeg",Vector3.new(0.6,3,0.6),
            at(x,1.5,25),Color3.fromRGB(56,61,68),Enum.Material.Metal)
    end
    make(room,"LaptopBase",Vector3.new(2.8,0.18,1.9),
        at(5,3.75,25),Color3.fromRGB(36,42,49),Enum.Material.Metal)
    local screen=make(room,"LaptopScreen",Vector3.new(2.8,1.9,0.15),
        at(5,4.8,25.9)*CFrame.Angles(math.rad(-12),0,0),
        Color3.fromRGB(25,31,38),Enum.Material.Metal)
    local display=Instance.new("SurfaceGui")
    display.Face=Enum.NormalId.Front;display.Parent=screen
    local text=Instance.new("TextLabel")
    text.Size=UDim2.fromScale(1,1);text.BackgroundColor3=Color3.fromRGB(20,49,62)
    text.TextColor3=Color3.fromRGB(95,235,198)
    text.Text="STOCK MANAGER";text.TextScaled=true;text.Font=Enum.Font.Code;text.Parent=display
    make(room,"OfficeChair",Vector3.new(3,0.6,3),at(5,1.6,21.7),
        Color3.fromRGB(42,47,55))
    make(room,"OfficeChairBack",Vector3.new(3,3,0.5),at(5,3,20.3),
        Color3.fromRGB(42,47,55))
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
