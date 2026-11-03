--[[
	Makes a GuiObject draggable by a handle.

	draggable(handle, target, function() return enabled end)
]]

--// Imports
local services = require("@modules/services")

--// References
local userInputService = services.UserInputService

return function(handle: GuiObject, target: GuiObject, isEnabled: (() -> boolean)?)
	local dragging = false
	local inputStart: Vector3? = nil
	local positionStart: UDim2? = nil

	handle.InputBegan:Connect(function(input)
		if isEnabled and not isEnabled() then
			return
		end

		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		dragging = true
		inputStart = input.Position
		positionStart = target.Position

		local connection
		connection = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				connection:Disconnect()
			end
		end)
	end)

	userInputService.InputChanged:Connect(function(input)
		if not dragging or not inputStart or not positionStart then
			return
		end

		if
			input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		local delta = input.Position - inputStart

		target.Position = UDim2.new(
			positionStart.X.Scale,
			positionStart.X.Offset + delta.X,
			positionStart.Y.Scale,
			positionStart.Y.Offset + delta.Y
		)
	end)
end
