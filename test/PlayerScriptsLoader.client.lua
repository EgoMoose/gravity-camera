local PlayerModule = script.Parent:WaitForChild("PlayerModule")

local playerModuleObject = require(PlayerModule)
local cameraModuleObject = playerModuleObject:GetCameras()

local upVector = Vector3.new(0, 1, 0)

function cameraModuleObject:GetUpVector()
	return upVector
end

game:GetService("RunService").Heartbeat:Connect(function(_dt)
	local character = game.Players.LocalPlayer.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")

	if hrp then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {character}

		local result = workspace:Raycast(hrp.Position, hrp.CFrame.YVector * -5, params)

		if result then
			upVector = result.Normal
			cameraModuleObject:SetSpinPart(result.Instance)
		end
	end
end)