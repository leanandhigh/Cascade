return function(object, minScale)
	--// Imports
	local creator = require("@modules/creator")

	--// References
	local create = creator.Create

	--// Variables
	local structures = {}

	--// UI
	structures.Handles = create("Folder")({
		Name = "Handles",
		Parent = object,

		create("Frame")({
			Name = "E",
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 0, 81),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.new(0, 6, 1, 0),
			ZIndex = 8,

			create("UIDragDetector")({
				Name = "UIDragDetector",
				ActivatedCursorIcon = "rbxassetid://122180269146343",
				CursorIcon = "rbxassetid://122180269146343",
				ResponseStyle = Enum.UIDragDetectorResponseStyle.CustomOffset,
				SelectionModeDragSpeed = UDim2.new(),
				SelectionModeRotateSpeed = 0,
			}),
		}),

		create("Frame")({
			Name = "N",
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundColor3 = Color3.fromRGB(255, 0, 81),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0),
			Size = UDim2.new(1, 0, 0, 6),
			ZIndex = 8,

			create("UIDragDetector")({
				Name = "UIDragDetector",
				ActivatedCursorIcon = "rbxassetid://109321922977357",
				CursorIcon = "rbxassetid://109321922977357",
				ResponseStyle = Enum.UIDragDetectorResponseStyle.CustomOffset,
				SelectionModeDragSpeed = UDim2.new(),
				SelectionModeRotateSpeed = 0,
			}),
		}),

		create("Frame")({
			Name = "NE",
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = Color3.fromRGB(255, 0, 81),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.fromOffset(10, 10),
			ZIndex = 9,

			create("UIDragDetector")({
				Name = "UIDragDetector",
				ActivatedCursorIcon = "rbxassetid://78578587100983",
				CursorIcon = "rbxassetid://78578587100983",
				ResponseStyle = Enum.UIDragDetectorResponseStyle.CustomOffset,
				SelectionModeDragSpeed = UDim2.new(),
				SelectionModeRotateSpeed = 0,
			}),
		}),

		create("Frame")({
			Name = "NW",
			BackgroundColor3 = Color3.fromRGB(255, 0, 81),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(10, 10),
			ZIndex = 9,

			create("UIDragDetector")({
				Name = "UIDragDetector",
				ActivatedCursorIcon = "rbxassetid://127507239458439",
				CursorIcon = "rbxassetid://127507239458439",
				ResponseStyle = Enum.UIDragDetectorResponseStyle.CustomOffset,
				SelectionModeDragSpeed = UDim2.new(),
				SelectionModeRotateSpeed = 0,
			}),
		}),

		create("Frame")({
			Name = "S",
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundColor3 = Color3.fromRGB(255, 0, 81),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 1),
			Size = UDim2.new(1, 0, 0, 6),
			ZIndex = 8,

			create("UIDragDetector")({
				Name = "UIDragDetector",
				ActivatedCursorIcon = "rbxassetid://109321922977357",
				CursorIcon = "rbxassetid://109321922977357",
				ResponseStyle = Enum.UIDragDetectorResponseStyle.CustomOffset,
				SelectionModeDragSpeed = UDim2.new(),
				SelectionModeRotateSpeed = 0,
			}),
		}),

		create("Frame")({
			Name = "SE",
			AnchorPoint = Vector2.new(1, 1),
			BackgroundColor3 = Color3.fromRGB(255, 0, 81),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(1, 1),
			Size = UDim2.fromOffset(10, 10),
			ZIndex = 9,

			create("UIDragDetector")({
				Name = "UIDragDetector",
				ActivatedCursorIcon = "rbxassetid://127507239458439",
				CursorIcon = "rbxassetid://127507239458439",
				ResponseStyle = Enum.UIDragDetectorResponseStyle.CustomOffset,
				SelectionModeDragSpeed = UDim2.new(),
				SelectionModeRotateSpeed = 0,
			}),
		}),

		create("Frame")({
			Name = "SW",
			AnchorPoint = Vector2.new(0, 1),
			BackgroundColor3 = Color3.fromRGB(255, 0, 81),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.fromOffset(10, 10),
			ZIndex = 9,

			create("UIDragDetector")({
				Name = "UIDragDetector",
				ActivatedCursorIcon = "rbxassetid://78578587100983",
				CursorIcon = "rbxassetid://78578587100983",
				ResponseStyle = Enum.UIDragDetectorResponseStyle.CustomOffset,
				SelectionModeDragSpeed = UDim2.new(),
				SelectionModeRotateSpeed = 0,
			}),
		}),

		create("Frame")({
			Name = "W",
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 0, 81),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0, 0.5),
			Size = UDim2.new(0, 6, 1, 0),
			ZIndex = 8,

			create("UIDragDetector")({
				Name = "UIDragDetector",
				ActivatedCursorIcon = "rbxassetid://122180269146343",
				CursorIcon = "rbxassetid://122180269146343",
				ResponseStyle = Enum.UIDragDetectorResponseStyle.CustomOffset,
				SelectionModeDragSpeed = UDim2.new(),
				SelectionModeRotateSpeed = 0,
			}),
		}),
	}) :: Folder

	--// Initialize
	minScale = minScale or Vector2.new(0, 0)

	structures.N = structures.Handles:FindFirstChild("N"):FindFirstChild("UIDragDetector")
	structures.S = structures.Handles:FindFirstChild("S"):FindFirstChild("UIDragDetector")
	structures.W = structures.Handles:FindFirstChild("W"):FindFirstChild("UIDragDetector")
	structures.E = structures.Handles:FindFirstChild("E"):FindFirstChild("UIDragDetector")
	structures.NE = structures.Handles:FindFirstChild("NE"):FindFirstChild("UIDragDetector")
	structures.SE = structures.Handles:FindFirstChild("SE"):FindFirstChild("UIDragDetector")
	structures.NW = structures.Handles:FindFirstChild("NW"):FindFirstChild("UIDragDetector")
	structures.SW = structures.Handles:FindFirstChild("SW"):FindFirstChild("UIDragDetector")

	local dragStartPosition
	local dragStartSize
	local resizeHandler = {}

	resizeHandler.__index = resizeHandler

	local function resizeObject(delta: Vector2, handleName: string)
		local sizeFactor = Vector2.zero

		if string.find(handleName, "N") then
			sizeFactor += Vector2.new(0, -1)
		end
		if string.find(handleName, "S") then
			sizeFactor += Vector2.new(0, 1)
		end
		if string.find(handleName, "W") then
			sizeFactor += Vector2.new(-1, 0)
		end
		if string.find(handleName, "E") then
			sizeFactor += Vector2.new(1, 0)
		end

		-- `delta` is in screen pixels; the window's offsets (Size and Position, the UIScale sits on
		-- the full-screen frame above it) get multiplied by its UIScale (0.8 on mobile).
		local scale = require("@modules/utility").GetScale(object)

		if scale < 0.05 then
			return
		end

		local sizeDelta = Vector2.new(
			(sizeFactor.X ~= 0) and (delta.X * sizeFactor.X / scale) or 0,
			(sizeFactor.Y ~= 0) and (delta.Y * sizeFactor.Y / scale) or 0
		)

		local newSize = dragStartSize + sizeDelta
		newSize = Vector2.new(math.max(minScale.X, newSize.X), math.max(minScale.Y, newSize.Y))

		-- Never larger than the screen (phones are small)
		local camera = workspace.CurrentCamera

		if camera then
			local viewport = camera.ViewportSize / scale
			newSize = Vector2.new(
				math.max(minScale.X, math.min(newSize.X, viewport.X - 16)),
				math.max(minScale.Y, math.min(newSize.Y, viewport.Y - 16))
			)
		end

		-- Keep the opposite edge still (the window is centre-anchored)
		local sizeChange = newSize - dragStartSize
		local centerCompensation = Vector2.new(
			sizeFactor.X < 0 and -sizeChange.X * 0.5 or sizeChange.X * 0.5,
			sizeFactor.Y < 0 and -sizeChange.Y * 0.5 or sizeChange.Y * 0.5
		)
		local newPositionOffset = dragStartPosition + centerCompensation

		object.Size = UDim2.fromOffset(math.floor(newSize.X + 0.5), math.floor(newSize.Y + 0.5))
		object.Position = UDim2.new(
			object.Position.X.Scale,
			newPositionOffset.X,
			object.Position.Y.Scale,
			newPositionOffset.Y
		)
	end

	local dragStartInput

	local function addHandle(handle, handleName: string)
		handle.DragStart:Connect(function(inputPosition: Vector2?)
			-- The window's own offsets, not AbsoluteSize (which includes the UIScale and made the
			-- window jump smaller on mobile the moment a handle was grabbed)
			dragStartSize = Vector2.new(object.Size.X.Offset, object.Size.Y.Offset)
			dragStartPosition = Vector2.new(object.Position.X.Offset, object.Position.Y.Offset)
			dragStartInput = inputPosition
		end)

		handle.DragContinue:Connect(function(inputPosition: Vector2?)
			if not dragStartSize then
				return
			end

			local delta

			if inputPosition and dragStartInput then
				delta = inputPosition - dragStartInput
			else
				delta = Vector2.new(handle.DragUDim2.X.Offset, handle.DragUDim2.Y.Offset)
			end

			resizeObject(delta, handleName)
		end)

		handle.DragEnd:Connect(function()
			dragStartSize = nil
			dragStartInput = nil
		end)
	end

	function resizeHandler.CreateClient()
		addHandle(structures.NW, "NW")
		addHandle(structures.NE, "NE")
		addHandle(structures.SW, "SW")
		addHandle(structures.SE, "SE")

		addHandle(structures.E, "E")
		addHandle(structures.W, "W")

		addHandle(structures.S, "S")
		addHandle(structures.N, "N")
	end

	function resizeHandler.SetEnabled(state: boolean)
		for i, v in pairs(structures) do
			if v:IsA("UIDragDetector") then
				v.Enabled = state
			end
		end
	end

	return resizeHandler
end
