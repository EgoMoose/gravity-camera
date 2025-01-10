--!strict

local GravityCamera = {}
GravityCamera.__index = GravityCamera

function GravityCamera.new(): typeof(setmetatable({}, GravityCamera))
	local upCFrame = CFrame.identity
	local spinPart = workspace.Terrain :: BasePart

	local self = setmetatable({
		upCFrame = upCFrame,
		targetUpVector = upCFrame.YVector,
		twistCFrame = CFrame.identity,
		spinPart = spinPart,
		prevSpinPart = spinPart,
		prevSpinCFrame = spinPart.CFrame,
		transitionRate = 0.15,
	}, GravityCamera)

	return self
end

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

function GravityCamera:calculateUpStep(_dt: number)
	local axis = workspace.CurrentCamera.CFrame.RightVector

	local sphericalArc = fromToRotation(self.upCFrame.YVector, self.targetUpVector, axis)
	local transitionCF = CFrame.identity:Lerp(sphericalArc, self.transitionRate)

	self.upCFrame = transitionCF * self.upCFrame
end

function GravityCamera:calculateSpinStep(_dt: number, inVehicle: boolean?)
	local spinPart = self.spinPart
	local prevSpinPart = self.prevSpinPart
	local prevSpinCFrame = self.prevSpinCFrame

	if inVehicle then
		self.twistCFrame = CFrame.identity
	elseif spinPart == prevSpinPart then
		local rotation = spinPart.CFrame.Rotation
		local prevRotation = prevSpinCFrame.Rotation

		local delta = prevRotation:ToObjectSpace(rotation)
		local spinAxis = delta:VectorToObjectSpace(prevRotation:VectorToObjectSpace(self.upCFrame.YVector))

		local _swing, twist = swingTwistDecomposition(delta, spinAxis)
		local deltaAxis, _deltaTheta = delta:ToAxisAngle()
		local _twistAxis, twistTheta = twist:ToAxisAngle()

		local theta = math.sign(deltaAxis:Dot(spinAxis)) * twistTheta
		self.twistCFrame = CFrame.fromEulerAnglesYXZ(0, theta, 0)
	end

	self.prevSpinPart = spinPart
	self.prevSpinCFrame = spinPart.CFrame
end

function GravityCamera:Step(dt: number, inVehicle: boolean?)
	self:calculateUpStep(dt)
	self:calculateSpinStep(dt, inVehicle)
end

function GravityCamera:GetCFrame(): CFrame
	return self.upCFrame * self.twistCFrame
end

function GravityCamera:GetUpVector(): Vector3
	return self.upCFrame.YVector
end

function GravityCamera:GetUpCFrame(): CFrame
	return self.upCFrame
end

function GravityCamera:SetUpCFrame(cframe: CFrame)
	self.upCFrame = cframe
	self.targetUpVector = cframe.YVector
end

function GravityCamera:GetTargetUpVector(): Vector3
	return self.targetUpVector
end

function GravityCamera:SetTargetUpVector(target: Vector3)
	self.targetUpVector = target
end

function GravityCamera:GetSpinPart(): BasePart
	return self.spinPart
end

function GravityCamera:SetSpinPart(part: BasePart)
	self.spinPart = part
end

function GravityCamera:SetTransitionRate(rate: number)
	self.transitionRate = rate
end

function GravityCamera:GetTransitionRate(): number
	return self.transitionRate
end

return GravityCamera
