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
    local old=shop:FindFirstChild("CityHeistShopTerminal")
    if old then old:Destroy() end
    local portal=shop:FindFirstChild("CityHeistShopEntrance")
    if portal then portal:Destroy() end
    local interiors=workspace:FindFirstChild("CityHeistShopInteriors")
    if not interiors then
        interiors=Instance.new("Folder");interiors.Name="CityHeistShopInteriors";interiors.Parent=workspace
    end
    local existing=interiors:FindFirstChild("Interior_"..index)
    if existing then existing:Destroy() end
    local room=Instance.new("Model");room.Name="Interior_"..index;room.Parent=interiors
    local exteriorCF,extSize=shop:GetBoundingBox()
    -- Build a connected walk-in storefront extension in front of each existing building.
    -- Front faces negative local Z, no existing facade parts are removed.
    local base=exteriorCF*CFrame.new(0,-extSize.Y/2,-extSize.Z/2-19)
    local function at(x,y,z) return base*CFrame.new(x,y,z) end
    local wall=Color3.fromRGB(211,215,216)
    local tile=Color3.fromRGB(96,103,109)
    local trim=Color3.fromRGB(35,50,58)
    make(room,"ShopFloor",Vector3.new(30,1,34),at(0,-0.5,0),tile,Enum.Material.Concrete)
    make(room,"ShopRoof",Vector3.new(30,1,34),at(0,13.5,0),trim)
    make(room,"LeftWall",Vector3.new(1,13,34),at(-15,6.5,0),wall)
    make(room,"RightWall",Vector3.new(1,13,34),at(15,6.5,0),wall)
    make(room,"BackWall",Vector3.new(30,13,1),at(0,6.5,17),wall)
    -- Shopfront: central 6-stud opening, glass panes, no blocking invisible wall.
    for _,x in ipairs({-10,10}) do
        make(room,"GlassFront",Vector3.new(10,10,0.4),at(x,5,-17),
            Color3.fromRGB(135,207,222),Enum.Material.Glass,true,0.5)
    end
    make(room,"DoorFrameLeft",Vector3.new(0.5,10,0.6),at(-3,5,-17),trim)
    make(room,"DoorFrameRight",Vector3.new(0.5,10,0.6),at(3,5,-17),trim)
    make(room,"DoorHeader",Vector3.new(6,3,0.6),at(0,11.5,-17),trim)
    -- Open, non-colliding glass swing door: player walks through without pressing E.
    make(room,"OpenGlassDoor",Vector3.new(3,9,0.25),
        at(3.1,4.5,-14.8)*CFrame.Angles(0,math.rad(85),0),
        Color3.fromRGB(155,225,235),Enum.Material.Glass,false,0.55)
    textSign(room,"StoreSign","24/7 MARKET",at(0,12.5,-17.4),Vector3.new(16,2,0.3))
    -- Register near the entrance on the right.
    make(room,"Counter",Vector3.new(8,3.5,3),at(9,1.75,-9),Color3.fromRGB(70,78,85))
    make(room,"CounterTop",Vector3.new(8.5,0.35,3.3),at(9,3.7,-9),trim)
    make(room,"CashRegister",Vector3.new(2,1,1.6),at(9,4.4,-9),Color3.fromRGB(26,31,35))
    local checkout=make(room,"CheckoutInteraction",Vector3.new(2,1,2),at(9,4.7,-10),
        Color3.fromRGB(0,200,150),Enum.Material.Neon,false,1)
    local prompt=Instance.new("ProximityPrompt")
    prompt.Name="OpenShop";prompt.ActionText="Kup produkty";prompt.ObjectText="Kasa sklepu "..index
    prompt.MaxActivationDistance=10;prompt.HoldDuration=0.3
    prompt.RequiresLineOfSight=false;prompt.Parent=checkout
    -- Stock aisles: 2 shelves, wide central walkway.
    for _,x in ipairs({-8,0}) do
        for _,z in ipairs({-3,4}) do
            for _,y in ipairs({2,4.5}) do
                make(room,"DisplayShelf",Vector3.new(5,0.35,2),at(x,y,z),
                    Color3.fromRGB(123,89,58),Enum.Material.Wood)
                for k=1,4 do
                    make(room,"PackagedProduct",Vector3.new(0.65,1.1,0.75),
                        at(x-2.1+k*0.9,y+0.7,z),
                        Color3.fromRGB(35+k*42,65+k*24,180-k*30))
                end
            end
        end
    end
    -- Fridges along the left wall.
    for _,z in ipairs({-11,-6,0}) do
        make(room,"Fridge",Vector3.new(2.3,8,4),at(-12.8,4,z),
            Color3.fromRGB(55,80,95),Enum.Material.Metal)
        make(room,"FridgeGlass",Vector3.new(0.2,6.5,3.2),at(-11.55,4,z),
            Color3.fromRGB(120,195,220),Enum.Material.Glass,false,0.4)
    end
    -- Stockroom at rear, with a walk-through door opening.
    make(room,"StockPartitionLeft",Vector3.new(19,12,0.6),at(-5.5,6,9),wall)
    make(room,"StockPartitionRight",Vector3.new(5,12,0.6),at(12.5,6,9),wall)
    make(room,"StockPartitionHeader",Vector3.new(6,3,0.6),at(7,10.5,9),wall)
    textSign(room,"StockroomSign","ZAPLECZE",at(7,11,8.6),Vector3.new(7,1.5,0.2))
    for _,x in ipairs({-10,-3,4}) do
        make(room,"StockShelf",Vector3.new(4,3,2),at(x,2,14),
            Color3.fromRGB(105,87,67),Enum.Material.Wood)
        make(room,"StockBox",Vector3.new(2,2,2),at(x,4.5,14),
            Color3.fromRGB(165,122,70),Enum.Material.Wood)
    end
    local safe=make(room,"StockroomCashSafe",Vector3.new(3,3,2),at(-12,1.5,13),
        Color3.fromRGB(63,70,78),Enum.Material.Metal)
    safe:SetAttribute("FutureShopRobbery",true)
    -- Overhead lighting.
    for _,z in ipairs({-9,0,12}) do
        local fixture=make(room,"CeilingLight",Vector3.new(8,0.2,1),at(0,12.8,z),
            Color3.fromRGB(245,245,235),Enum.Material.Neon,false)
        local light=Instance.new("SurfaceLight")
        light.Face=Enum.NormalId.Bottom;light.Brightness=2;light.Range=18
        light.Angle=120;light.Parent=fixture
    end
    print("[CityHeistShop] Shop_"..index.." walk-in interior ready")
    return checkout
end
return Builder
