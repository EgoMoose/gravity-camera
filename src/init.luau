--!strict

local RunService = game:GetService("RunService")

if RunService:IsClient() then
	local GravityCamera = require(script.GravityCamera)

	local module = {}

	module.new = GravityCamera.new

	return module
end

local Packages = script.Parent
local PlayerModulePackage = require(Packages.PlayerModule)

local module = {}
local patched = PlayerModulePackage.getCopy(true) :: any
local modifiers = require(patched.Modifiers) :: any

-- Adjustments

-- necessary so that modifiers have access after they are re-paranted
local gravityCameraRef = Instance.new("ObjectValue")
gravityCameraRef.Name = "GravityCamera"
gravityCameraRef.Value = script.GravityCamera
gravityCameraRef.Parent = script.Modifiers.GravityCamera

for _, modifier in script.Modifiers:GetChildren() do
	modifiers.add(modifier)
end

-- Public

function module.get(): ModuleScript
	return patched
end

function module.getCopy(): ModuleScript
	return module.get():Clone()
end

module.replace = PlayerModulePackage.replace

return module
