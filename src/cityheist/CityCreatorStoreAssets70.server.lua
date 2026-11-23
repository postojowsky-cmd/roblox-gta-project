-- CITY HEIST / Step 71: inspect the ONE confirmed-accessible Creator Store kit.
-- Verified in Studio logs: asset 13168370735 loads, containing 3360 parts.
-- Runs only once even if old Studio script and Rojo copy are both enabled.
-- Imported objects remain in ServerStorage; the playable map is untouched.
local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end

local ServerStorage=game:GetService("ServerStorage")
local AssetService=game:GetService("AssetService")
local Workspace=game:GetService("Workspace")

-- Set guard before any WaitForChild/yield to prevent duplicate imports.
if ServerStorage:GetAttribute("CityAssets71Loaded") then
    print("[CityAssets71] Duplicate runner skipped")
    return
end
ServerStorage:SetAttribute("CityAssets71Loaded",true)

local id=13168370735
local old=ServerStorage:FindFirstChild("CityHeistAssetStaging")
if old then old:Destroy() end
local stage=Instance.new("Folder")
stage.Name="CityHeistAssetStaging"
stage:SetAttribute("SafePreviewOnly",true)
stage:SetAttribute("CreatorStoreAssetId",id)
stage.Parent=ServerStorage
stage:SetAttribute("ImportStatus","Loading")

local ok,asset=pcall(function()
    return AssetService:LoadAssetAsync(id)
end)
if not ok or typeof(asset)~="Instance" then
    stage:SetAttribute("ImportStatus","Failed")
    warn("[CityAssets71] Model import blocked: "..tostring(asset))
    return
end

local stripped=0
for _,obj in ipairs(asset:GetDescendants()) do
    if obj:IsA("LuaSourceContainer") then
        obj:Destroy()
        stripped+=1
    end
end
asset.Name="ModernCityModularKit"
asset:SetAttribute("CreatorStoreAssetId",id)
asset:SetAttribute("ForeignScriptsRemoved",stripped)
asset.Parent=stage
stage:SetAttribute("ImportStatus","Ready")

local parts,meshes,models=0,0,0
for _,obj in ipairs(asset:GetDescendants()) do
    if obj:IsA("BasePart") then
        parts+=1
        if obj:IsA("MeshPart") then meshes+=1 end
    elseif obj:IsA("Model") then models+=1 end
end
print(string.format(
    "[CityAssets71] IMPORT OK | %d parts | %d meshes | %d models | %d foreign scripts removed",
    parts,meshes,models,stripped))

-- Print the first two levels of the actual asset hierarchy so the next
-- construction stage can reuse genuine building pieces, not guessed names.
local rows=0
local limit=45
local function inspect(parent,depth)
    if rows>=limit then return end
    local children=parent:GetChildren()
    table.sort(children,function(a,b)return a.Name<b.Name end)
    for _,obj in ipairs(children) do
        if rows>=limit then break end
        rows+=1
        local dims=""
        if obj:IsA("Model") then
            local box,size=obj:GetBoundingBox()
            dims=string.format(" [%.0fx%.0fx%.0f]",size.X,size.Y,size.Z)
        elseif obj:IsA("BasePart") then
            dims=string.format(" [%.0fx%.0fx%.0f]",obj.Size.X,obj.Size.Y,obj.Size.Z)
        end
        print("[CityAssets71] "..string.rep("  ",depth)..
            obj.Name.." <"..obj.ClassName..">"..dims)
        if depth<1 then inspect(obj,depth+1) end
    end
end
inspect(asset,0)
print("[CityAssets71] Inspection ready. No live city or road geometry changed.")
