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

	-- Visible corner grip (bottom-right). The edge handles are thin invisible strips that are
	-- hard to hit with a finger; this works with touch and mouse alike (same idea as Obsidian's
	-- resize button). Uses plain input events, no UIDragDetector.
	local grip = nil
	local gripEnabled = true

	function resizeHandler.CreateGrip(theme, size: number?)
		local services = require("@modules/services")
		local icons = require("@modules/icons")
		local symbols = require("@modules/symbols")
		local userInputService = services.UserInputService

		size = size or 20

		-- Like Obsidian's resize button: bottom-right corner, move-diagonal-2 icon in the text
		-- colour at half transparency, icon filling the button minus 2px.
		-- Parented to the Handles folder: the window body has a list layout, and a direct child
		-- got laid out next to the sidebar (that's why it showed up at the top).
		grip = create("ImageButton")({
			Name = "ResizeGrip",
			Active = true,
			AnchorPoint = Vector2.new(1, 1),
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -3, 1, -3),
			Size = UDim2.fromOffset(size, size),
			ZIndex = 20,
			Parent = structures.Handles.__instance or structures.Handles,

			create("ImageLabel")({
				Name = "Icon",
				BackgroundTransparency = 1,
				ImageTransparency = 0.5,
				Position = UDim2.fromOffset(2, 2),
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.new(1, -4, 1, -4),
				ZIndex = 20,

				__dynamicKeys = theme and {
					ImageColor3 = theme.Text.Primary[1],
				} or nil,
			}),
		}).__instance

		icons.Apply(grip:FindFirstChild("Icon"), "move-diagonal-2", symbols.arrowUpLeftAndArrowDownRight)

		local activeInput = nil
		local inputStart = nil

		grip.InputBegan:Connect(function(input)
			if not gripEnabled then
				return
			end

			if
				input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end

			activeInput = input
			inputStart = Vector2.new(input.Position.X, input.Position.Y)
			dragStartSize = Vector2.new(object.Size.X.Offset, object.Size.Y.Offset)
			dragStartPosition = Vector2.new(object.Position.X.Offset, object.Position.Y.Offset)

			local connection
			connection = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					connection:Disconnect()

					if activeInput == input then
						activeInput = nil
						dragStartSize = nil
					end
				end
			end)
		end)

		userInputService.InputChanged:Connect(function(input)
			if not activeInput or not inputStart or not dragStartSize then
				return
			end

			if
				input.UserInputType ~= Enum.UserInputType.MouseMovement
				and input.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end

			-- Only the finger that grabbed the grip (multi-touch: the other finger may be moving the camera)
			if input.UserInputType == Enum.UserInputType.Touch and activeInput.UserInputType == Enum.UserInputType.Touch and input ~= activeInput then
				return
			end

			resizeObject(Vector2.new(input.Position.X - inputStart.X, input.Position.Y - inputStart.Y), "SE")
		end)

		userInputService.InputEnded:Connect(function(input)
			if activeInput and (input == activeInput or input.UserInputType == Enum.UserInputType.MouseButton1) then
				activeInput = nil
				dragStartSize = nil
			end
		end)

		return grip
	end

	function resizeHandler.SetEnabled(state: boolean)
		for i, v in pairs(structures) do
			if typeof(v) == "Instance" and v:IsA("UIDragDetector") then
				v.Enabled = state
			end
		end

		gripEnabled = state

		if grip then
			grip.Visible = state
		end
	end

	return resizeHandler
end
