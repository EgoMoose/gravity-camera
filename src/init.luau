--!strict

local Packages = script.Parent
local PlayerModulePackage = require(Packages.PlayerModule)

local module = {}
local patched = PlayerModulePackage.getCopy(true) :: any
local modifiers = require(patched.Modifiers) :: any

-- Adjustments

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
