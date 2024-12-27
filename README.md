# gravity-camera
Modifications to the standard roblox player module to allow custom up vectors and spinning in sync with base parts.

Adds the following functions to the CameraModule:

```Lua
-- returns what the camera currently considers to be the up vector at any given moment
CameraModule:GetUpVector(): Vector3

-- returns what the camera currently considers to be the up vector and cframe at any given moment
CameraModule:GetUpOrientation(): (Vector3, CFrame)

-- sets the up vector and cframe
CameraModule:SetUpOrientation(upVector: Vector3, upCFrame: CFrame)

-- by default this is Vector3.new(0, 1, 0)
CameraModule:GetTargetUpVector(): Vector3

CameraModule:SetTargetUpVector(target: Vector3)

CameraModule:GetSpinPart(): BasePart

-- matches the camera to spin with this part
-- for example, your camera spins with a merry go round
-- by default this is workspace.Terrain
CameraModule:SetSpinPart(part: BasePart)

CameraModule:GetTransitionRate(): number

-- defines how the camera up vector should smoothly interpolate between it's current value and the target
-- for example, instantaneous jumps would be 1
-- by default this is 0.15
CameraModule:SetTransitionRate(rate: number)
```
