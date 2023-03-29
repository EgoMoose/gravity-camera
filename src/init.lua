--!strict

local PlayerModulePackage = require(script.Packages.PlayerModule)

local module = {}
local patched = PlayerModulePackage.getCopy(true)
local modifiers = require(patched.Modifiers)

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