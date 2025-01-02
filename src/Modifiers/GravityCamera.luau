--!strict

local transitionRate: number = 0.15
local upCFrame: CFrame = CFrame.identity
local targetUpVector: Vector3 = upCFrame.YVector

local twistCFrame: CFrame = CFrame.identity
local spinPart: BasePart = workspace.Terrain
local prevSpinPart: BasePart = spinPart
local prevSpinCFrame: CFrame = spinPart.CFrame

--

local function fromToRotation(fromUnit: Vector3, toUnit: Vector3, backupAxis: Vector3)
	local dot, cross = fromUnit:Dot(toUnit), fromUnit:Cross(toUnit)
	if dot < -0.99999 then
		return CFrame.fromAxisAngle(backupAxis, math.pi)
	end
	return CFrame.new(0, 0, 0, cross.X, cross.Y, cross.Z, 1 + dot)
end

local function swingTwistDecomposition(inputCF: CFrame, relativeUnitAxis: Vector3)
	local axis, theta = inputCF:ToAxisAngle()
	local w, v = math.cos(theta / 2), math.sin(theta / 2) * axis

	local proj = v:Dot(relativeUnitAxis) * relativeUnitAxis
	local twist = CFrame.new(0, 0, 0, proj.X, proj.Y, proj.Z, w)

	local swing = inputCF * twist:Inverse()

	return swing, twist
end

local function calculateUpStep(_dt: number)
	local axis = workspace.CurrentCamera.CFrame.RightVector

	local sphericalArc = fromToRotation(upCFrame.YVector, targetUpVector, axis)
	local transitionCF = CFrame.identity:Lerp(sphericalArc, transitionRate)

	upCFrame = transitionCF * upCFrame
end

local function calculateSpinStep(_dt: number, inVehicle: boolean)
	if inVehicle then
		twistCFrame = CFrame.identity
	elseif spinPart == prevSpinPart then
		local rotation = spinPart.CFrame - spinPart.CFrame.Position
		local prevRotation = prevSpinCFrame - prevSpinCFrame.Position

		local delta = prevRotation:ToObjectSpace(rotation)
		local spinAxis = delta:VectorToObjectSpace(prevRotation:VectorToObjectSpace(upCFrame.YVector))

		local _swing, twist = swingTwistDecomposition(delta, spinAxis)
		local deltaAxis, _deltaTheta = delta:ToAxisAngle()
		local _twistAxis, twistTheta = twist:ToAxisAngle()

		local theta = math.sign(deltaAxis:Dot(spinAxis)) * twistTheta
		twistCFrame = CFrame.fromEulerAnglesYXZ(0, theta, 0)
	end

	prevSpinPart = spinPart
	prevSpinCFrame = spinPart.CFrame
end

--

return function(PlayerModule)
	------------
	local cameraUtils = require(PlayerModule.CameraModule.CameraUtils) :: any

	function cameraUtils.getAngleBetweenXZVectors(v1: Vector3, v2: Vector3): number
		v1 = upCFrame:VectorToObjectSpace(v1)
		v2 = upCFrame:VectorToObjectSpace(v2)

		return math.atan2(v2.X * v1.Z - v2.Z * v1.X, v2.X * v1.X + v2.Z * v1.Z)
	end

	------------
	local poppercam = require(PlayerModule.CameraModule.Poppercam) :: any
	local zoomController = require(PlayerModule.CameraModule.ZoomController) :: any

	function poppercam:Update(
		renderDt: number,
		desiredCameraCFrame: CFrame,
		desiredCameraFocus: CFrame,
		_cameraController: any
	)
		local rotatedFocus = desiredCameraFocus * (desiredCameraCFrame - desiredCameraCFrame.Position)
		local extrapolation = self.focusExtrapolator:Step(renderDt, rotatedFocus)
		local zoom = zoomController.Update(renderDt, rotatedFocus, extrapolation)
		return rotatedFocus * CFrame.new(0, 0, zoom), desiredCameraFocus
	end

	------------
	local baseCamera = require(PlayerModule.CameraModule.BaseCamera) :: any

	local max_y = math.rad(80)
	local min_y = math.rad(-80)

	function baseCamera:CalculateNewLookCFrameFromArg(suppliedLookVector: Vector3?, rotateInput: Vector2): CFrame
		local currLookVector: Vector3 = suppliedLookVector or self:GetCameraLookVector()
		currLookVector = upCFrame:VectorToObjectSpace(currLookVector)

		local currPitchAngle = math.asin(currLookVector.Y)
		local yTheta = math.clamp(rotateInput.Y, -max_y + currPitchAngle, -min_y + currPitchAngle)
		local constrainedRotateInput = Vector2.new(rotateInput.X, yTheta)
		local startCFrame = CFrame.new(Vector3.zero, currLookVector)
		local newLookCFrame = CFrame.Angles(0, -constrainedRotateInput.X, 0)
			* startCFrame
			* CFrame.Angles(-constrainedRotateInput.Y, 0, 0)

		return newLookCFrame
	end

	------------
	local vehicleCameraCore = require(PlayerModule.CameraModule.VehicleCamera.VehicleCameraCore) :: any
	local setTransform = vehicleCameraCore.setTransform

	function vehicleCameraCore:setTransform(transform: CFrame)
		transform = upCFrame:ToObjectSpace(transform.Rotation) + transform.Position
		return setTransform(self, transform)
	end

	------------
	local cameraObject = require(PlayerModule.CameraModule) :: any
	local cameraInput = require(PlayerModule.CameraModule.CameraInput) :: any

	function cameraObject:GetUpVector(): Vector3
		return upCFrame.YVector
	end

	function cameraObject:GetUpCFrame(): CFrame
		return upCFrame
	end

	function cameraObject:SetUpCFrame(cframe: CFrame)
		upCFrame = cframe
		targetUpVector = cframe.YVector
	end

	function cameraObject:GetTargetUpVector(): Vector3
		return targetUpVector
	end

	function cameraObject:SetTargetUpVector(target: Vector3)
		targetUpVector = target
	end

	function cameraObject:GetSpinPart(): BasePart
		return spinPart
	end

	function cameraObject:SetSpinPart(part: BasePart)
		spinPart = part
	end

	function cameraObject:SetTransitionRate(rate: number)
		transitionRate = rate
	end

	function cameraObject:GetTransitionRate(): number
		return transitionRate
	end

	function cameraObject:Update(dt: number)
		if self.activeCameraController then
			self.activeCameraController:UpdateMouseBehavior()

			local newCameraCFrame, newCameraFocus = self.activeCameraController:Update(dt)
			local lockOffset = self.activeCameraController:GetIsMouseLocked()
					and self.activeCameraController:GetMouseLockOffset()
				or Vector3.new(0, 0, 0)

			calculateUpStep(dt)
			calculateSpinStep(dt, self:ShouldUseVehicleCamera())

			local fixedCameraFocus = CFrame.new(newCameraFocus.Position) -- fixes an issue with vehicle cameras
			local camRotation = upCFrame * twistCFrame * fixedCameraFocus:ToObjectSpace(newCameraCFrame)
			local adjustedLockOffset = -newCameraCFrame:VectorToWorldSpace(lockOffset)
				+ camRotation:VectorToWorldSpace(lockOffset)

			newCameraFocus = fixedCameraFocus + adjustedLockOffset
			newCameraCFrame = newCameraFocus * camRotation

			if self.activeOcclusionModule then
				newCameraCFrame, newCameraFocus = self.activeOcclusionModule:Update(dt, newCameraCFrame, newCameraFocus)
			end

			-- Here is where the new CFrame and Focus are set for this render frame
			local currentCamera = game.Workspace.CurrentCamera :: Camera
			currentCamera.CFrame = newCameraCFrame
			currentCamera.Focus = newCameraFocus

			-- fixes issue with follow camera
			self.activeCameraController.lastCameraTransform = newCameraCFrame
			self.activeCameraController.lastCameraFocus = newCameraFocus

			-- Update to character local transparency as needed based on camera-to-subject distance
			if self.activeTransparencyController then
				self.activeTransparencyController:Update(dt)
			end

			if cameraInput.getInputEnabled() then
				cameraInput.resetInputForFrameEnd()
			end
		end
	end
end
