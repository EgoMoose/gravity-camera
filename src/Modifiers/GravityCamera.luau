--!strict

local GravityCamera = require(script.GravityCamera.Value) :: any

local gravityCamera = GravityCamera.new()

return function(PlayerModule)
	------------
	local cameraUtils = require(PlayerModule.CameraModule.CameraUtils) :: any

	function cameraUtils.getAngleBetweenXZVectors(v1: Vector3, v2: Vector3): number
		local upCFrame = gravityCamera:GetUpCFrame()

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
		currLookVector = gravityCamera:GetUpCFrame():VectorToObjectSpace(currLookVector)

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
		transform = gravityCamera:GetUpCFrame():ToObjectSpace(transform.Rotation) + transform.Position
		return setTransform(self, transform)
	end

	------------
	local cameraObject = require(PlayerModule.CameraModule) :: any
	local cameraInput = require(PlayerModule.CameraModule.CameraInput) :: any

	function cameraObject:GetUpVector(): Vector3
		return gravityCamera:GetUpVector()
	end

	function cameraObject:GetUpCFrame(): CFrame
		return gravityCamera:GetUpCFrame()
	end

	function cameraObject:SetUpCFrame(cframe: CFrame)
		gravityCamera:SetUpCFrame(cframe)
	end

	function cameraObject:GetTargetUpVector(): Vector3
		return gravityCamera:GetTargetUpVector()
	end

	function cameraObject:SetTargetUpVector(target: Vector3)
		gravityCamera:SetTargetUpVector(target)
	end

	function cameraObject:GetSpinPart(): BasePart
		return gravityCamera:GetSpinPart()
	end

	function cameraObject:SetSpinPart(part: BasePart)
		gravityCamera:SetSpinPart(part)
	end

	function cameraObject:SetTransitionRate(rate: number)
		gravityCamera:SetTransitionRate(rate)
	end

	function cameraObject:GetTransitionRate(): number
		return gravityCamera:GetTransitionRate()
	end

	function cameraObject:Update(dt: number)
		if self.activeCameraController then
			self.activeCameraController:UpdateMouseBehavior()

			local newCameraCFrame, newCameraFocus = self.activeCameraController:Update(dt)
			local lockOffset = self.activeCameraController:GetIsMouseLocked()
					and self.activeCameraController:GetMouseLockOffset()
				or Vector3.new(0, 0, 0)

			gravityCamera:Step(dt, self:ShouldUseVehicleCamera())

			local fixedCameraFocus = CFrame.new(newCameraFocus.Position) -- fixes an issue with vehicle cameras
			local camRotation = gravityCamera:GetCFrame() * fixedCameraFocus:ToObjectSpace(newCameraCFrame)
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
