-- City Heist Asset Import Test / Step 70.
-- Safe, reversible Studio-only asset staging. Does NOT rebuild live city.
-- Uses real Roblox Creator Store model IDs, no user-created substitute geometry.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local Workspace = game:GetService("Workspace")
local AssetService = game:GetService("AssetService")
local ServerStorage = game:GetService("ServerStorage")
local city = Workspace:WaitForChild("CityBlockout",30)
if not city then return end

local catalog = {
    {id=13168370735, label="ModernCityModularKit", role="building kit"},
    {id=1028186805, label="PoliceStationExample", role="police station"},
    {id=95798439683690, label="UrbanCityPack", role="roads and city props"},
}
local old=ServerStorage:FindFirstChild("CityHeistAssetStaging")
if old then old:Destroy() end
local staging=Instance.new("Folder")
staging.Name="CityHeistAssetStaging"
staging.Parent=ServerStorage
staging:SetAttribute("SafePreviewOnly",true)

local function removeExecutableCode(root)
    local removed=0
    for _,desc in ipairs(root:GetDescendants()) do
        if desc:IsA("LuaSourceContainer") then
            desc:Destroy()
            removed+=1
        end
    end
    return removed
end
local function summarize(root)
    local parts=0
    local meshes=0
    local models=0
    for _,p in ipairs(root:GetDescendants()) do
        if p:IsA("BasePart") then
            parts+=1
            if p:IsA("MeshPart") then meshes+=1 end
        elseif p:IsA("Model") then
            models+=1
        end
    end
    return parts,meshes,models
end
for _,item in ipairs(catalog) do
    -- AssetService:LoadAssetAsync may require Game Settings > Security >
    -- Allow Loading Third Party Assets. A failed load leaves the map unchanged.
    local ok,loaded=pcall(function()
        return AssetService:LoadAssetAsync(item.id)
    end)
    if not ok or typeof(loaded)~="Instance" then
        warn(string.format("[CityAssets70] FAILED %s (%d): %s",
            item.label,item.id,tostring(loaded)))
    else
        loaded.Name=item.label
        loaded:SetAttribute("CreatorStoreAssetId",item.id)
        loaded:SetAttribute("Role",item.role)
        loaded:SetAttribute("UnverifiedAsset",true)
        local scripts=removeExecutableCode(loaded)
        local parts,meshes,models=summarize(loaded)
        loaded.Parent=staging
        print(string.format(
            "[CityAssets70] STAGED %s (%d): %d parts / %d meshes / %d models; %d foreign scripts removed",
            item.label,item.id,parts,meshes,models,scripts))
    end
end
print(string.format(
    "[CityAssets70] Staging completed (%d/%d assets). Browse ServerStorage.CityHeistAssetStaging; current map unchanged.",
    #staging:GetChildren(),#catalog))
