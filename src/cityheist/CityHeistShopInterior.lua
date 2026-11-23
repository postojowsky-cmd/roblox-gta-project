-- MVP shop interiors: instanced rooms with safe entry/exit teleport.
-- Original exterior buildings are not modified or moved.
local Builder = {}
local function part(parent,name,size,cf,color,material,collide)
    local p=Instance.new("Part")
    p.Name=name;p.Size=size;p.CFrame=cf;p.Anchored=true
    p.Color=color;p.Material=material or Enum.Material.SmoothPlastic
    p.CanCollide=collide~=false;p.Parent=parent
    return p
end
local function prompt(parent,name,action,object)
    local p=Instance.new("ProximityPrompt")
    p.Name=name;p.ActionText=action;p.ObjectText=object
    p.HoldDuration=0.3;p.MaxActivationDistance=10
    p.RequiresLineOfSight=false;p.Parent=parent
    return p
end
local function sign(parent,text,cf,size)
    local anchor=part(parent,"Sign",size,cf,Color3.fromRGB(24,38,50),Enum.Material.SmoothPlastic,false)
    local gui=Instance.new("SurfaceGui");gui.Face=Enum.NormalId.Front;gui.Parent=anchor
    local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1)
    label.BackgroundTransparency=1;label.Text=text;label.TextScaled=true
    label.Font=Enum.Font.GothamBold;label.TextColor3=Color3.fromRGB(240,245,255);label.Parent=gui
end
function Builder.build(shop,index)
    local old=shop:FindFirstChild("CityHeistShopTerminal")
    if old then old:Destroy() end
    local previous=workspace:FindFirstChild("CityHeistShopInteriors")
    if not previous then
        previous=Instance.new("Folder");previous.Name="CityHeistShopInteriors";previous.Parent=workspace
    end
    local existing=previous:FindFirstChild("Interior_"..index)
    if existing then existing:Destroy() end
    local room=Instance.new("Model");room.Name="Interior_"..index;room.Parent=previous
    local base=Vector3.new(index*170,650,0)
    local function at(x,y,z) return CFrame.new(base+Vector3.new(x,y,z)) end
    local wall=Color3.fromRGB(210,215,218)
    local floor=Color3.fromRGB(75,83,90)
    part(room,"Floor",Vector3.new(36,1,46),at(0,0,0),floor,Enum.Material.Concrete)
    part(room,"Ceiling",Vector3.new(36,1,46),at(0,15,0),wall)
    part(room,"LeftWall",Vector3.new(1,15,46),at(-18,7.5,0),wall)
    part(room,"RightWall",Vector3.new(1,15,46),at(18,7.5,0),wall)
    part(room,"FrontWall",Vector3.new(36,15,1),at(0,7.5,23),wall)
    part(room,"BackWall",Vector3.new(36,15,1),at(0,7.5,-23),wall)
    -- Partition with a door-sized opening at x=10 to access the stockroom.
    part(room,"StockroomPartitionLeft",Vector3.new(24,13,1),at(-6,6.5,-8),wall)
    part(room,"StockroomPartitionRight",Vector3.new(7,13,1),at(14.5,6.5,-8),wall)
    part(room,"StockroomDoorHeader",Vector3.new(5,4,1),at(10,11,-8),wall)
    sign(room,"ZAPLECZE",at(10,12,-7.4),Vector3.new(8,2,0.2))
    for _,x in ipairs({-12,-5,2}) do
        for _,z in ipairs({4,11}) do
            part(room,"Shelf",Vector3.new(5,0.6,2),at(x,3,z),Color3.fromRGB(105,76,49),Enum.Material.Wood)
            part(room,"ShelfTop",Vector3.new(5,0.6,2),at(x,6,z),Color3.fromRGB(105,76,49),Enum.Material.Wood)
            for k=1,3 do
                part(room,"Product",Vector3.new(0.8,1.5,0.8),at(x-2+k*1.1,4.1,z),Color3.fromRGB(50+k*35,110,180-k*30),Enum.Material.SmoothPlastic)
            end
        end
    end
    part(room,"Counter",Vector3.new(10,4,3),at(9,2,16),Color3.fromRGB(62,68,76))
    part(room,"CounterTop",Vector3.new(10.5,0.4,3.4),at(9,4.2,16),Color3.fromRGB(30,35,42))
    part(room,"CashRegister",Vector3.new(2,1.3,1.8),at(9,5.1,16),Color3.fromRGB(35,40,45))
    local checkout=part(room,"CheckoutInteraction",Vector3.new(2,1,2),at(9,5.6,17),Color3.fromRGB(30,200,145),Enum.Material.Neon,false)
    checkout.Transparency=1
    prompt(checkout,"OpenShop","Kup produkty","Kasa sklepu "..index)
    sign(room,"SKLEP "..index,at(0,12,22.3),Vector3.new(13,2,0.2))
    for _,x in ipairs({-9,5,12}) do
        part(room,"StockShelf",Vector3.new(4,4,2),at(x,2.5,-17),Color3.fromRGB(108,91,72),Enum.Material.Wood)
        part(room,"StockBox",Vector3.new(2,2,2),at(x,5.5,-17),Color3.fromRGB(168,128,74),Enum.Material.Wood)
    end
    local cash=part(room,"StockroomCashSafe",Vector3.new(3,3,2),at(-13,2,-20),Color3.fromRGB(70,78,90),Enum.Material.Metal)
    cash:SetAttribute("FutureShopRobbery",true)
    -- Original shops may have sealed facades. A portal ensures access without destructive edits.
    local exteriorCF,exteriorSize=shop:GetBoundingBox()
    local entry=part(shop,"CityHeistShopEntrance",Vector3.new(3,5,2),
        exteriorCF*CFrame.new(0,-exteriorSize.Y/2+3,-exteriorSize.Z/2-4),
        Color3.fromRGB(30,175,155),Enum.Material.Neon,false)
    entry.Transparency=0.25
    local entryPrompt=prompt(entry,"EnterShop","Wejdz do sklepu","Sklep "..index)
    local exit=part(room,"Exit",Vector3.new(4,5,1),at(0,3,21),Color3.fromRGB(30,175,155),Enum.Material.Neon,false)
    local exitPrompt=prompt(exit,"LeaveShop","Wyjdz na zewnatrz","Wyjscie")
    local function teleport(player,position)
        local char=player.Character
        local root=char and char:FindFirstChild("HumanoidRootPart")
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if not root or not hum or hum.Health<=0 then return end
        root.AssemblyLinearVelocity=Vector3.zero
        root.AssemblyAngularVelocity=Vector3.zero
        char:PivotTo(CFrame.new(position))
    end
    entryPrompt.Triggered:Connect(function(player)
        teleport(player,base+Vector3.new(0,3,15))
    end)
    exitPrompt.Triggered:Connect(function(player)
        local p=entry.Position
        teleport(player,p+Vector3.new(0,1,-5))
    end)
    return checkout
end
return Builder
