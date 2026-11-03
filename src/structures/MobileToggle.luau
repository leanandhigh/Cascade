--[[
	Round, draggable button that shows / hides the window on phones and tablets.
	Shows the window's logo; tap to toggle, drag to move (a tap that moved more than a few
	pixels counts as a drag, same as Obsidian's mobile buttons).
]]

return function(self, onTap: () -> ())
	--// Imports
	local creator = require("@modules/creator")
	local services = require("@modules/services")
	local icons = require("@modules/icons")

	--// References
	local create = creator.Create
	local userInputService = services.UserInputService

	--// Constants
	local SIZE = 52
	local DRAG_THRESHOLD = 8

	--// Variables
	local theme = self.Theme
	local structures = {}

	structures.Body = create("ImageButton")({
		Name = "MobileToggle",
		Active = true,
		AnchorPoint = Vector2.new(1, 0),
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -14, 0, 74),
		Size = UDim2.fromOffset(SIZE, SIZE),
		ZIndex = 60,

		__dynamicKeys = {
			BackgroundColor3 = theme.Controls.Card.Overlay[1],
			BackgroundTransparency = theme.Controls.Card.Overlay[2],
		},

		create("UICorner")({
			CornerRadius = UDim.new(1, 0),
		}),

		create("UIStroke")({
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = 1.5,

			__dynamicKeys = {
				Color = theme.Controls.ViewBorder[1],
				Transparency = theme.Controls.ViewBorder[2],
			},
		}),

		create("ImageLabel")({
			Name = "Logo",
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.5),
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromOffset(SIZE - 12, SIZE - 12),
			ZIndex = 61,

			create("UICorner")({
				CornerRadius = UDim.new(1, 0),
			}),
		}),
	})

	structures.Logo = structures.Body:FindFirstChild("Logo") :: ImageLabel

	-- Your logo image fills the circle; glyphs (Lucide / symbols) are smaller and accent-tinted
	structures.SetLogo = function(logo)
		local value = logo ~= nil and logo or "menu"
		local isGlyph = icons.IsGlyph(value) or logo == nil

		icons.Apply(structures.Logo, value, require("@modules/symbols").line3Horizontal)

		structures.Logo.Size = isGlyph and UDim2.fromOffset(24, 24) or UDim2.fromOffset(SIZE - 12, SIZE - 12)
		structures.Logo.ImageColor3 = isGlyph and theme.Controls.Selection[1].Value or Color3.new(1, 1, 1)
	end

	-- Left or right edge of the screen
	structures.SetSide = function(side: string?)
		if side == "Left" then
			structures.Body.AnchorPoint = Vector2.new(0, 0)
			structures.Body.Position = UDim2.new(0, 14, 0, 74)
		else
			structures.Body.AnchorPoint = Vector2.new(1, 0)
			structures.Body.Position = UDim2.new(1, -14, 0, 74)
		end
	end

	--// Tap vs drag
	local dragInput = nil
	local inputStart = nil
	local positionStart = nil
	local moved = false

	structures.Body.InputBegan:Connect(function(input)
		if
			input.UserInputType ~= Enum.UserInputType.Touch
			and input.UserInputType ~= Enum.UserInputType.MouseButton1
		then
			return
		end

		dragInput = input
		inputStart = input.Position
		positionStart = structures.Body.Position
		moved = false

		local connection
		connection = input.Changed:Connect(function()
			if input.UserInputState ~= Enum.UserInputState.End then
				return
			end

			connection:Disconnect()

			if dragInput == input then
				dragInput = nil

				if not moved then
					onTap()
				end
			end
		end)
	end)

	userInputService.InputChanged:Connect(function(input)
		if not dragInput or not inputStart or not positionStart then
			return
		end

		if
			input.UserInputType ~= Enum.UserInputType.Touch
			and input.UserInputType ~= Enum.UserInputType.MouseMovement
		then
			return
		end

		local delta = input.Position - inputStart

		if not moved and math.abs(delta.X) + math.abs(delta.Y) < DRAG_THRESHOLD then
			return
		end

		moved = true
		-- Placed by the player: overlays (eg. the farm HUD) stop moving it out of their way
		structures.Body:SetAttribute("UserMoved", true)
		structures.Body.Position = UDim2.new(
			positionStart.X.Scale,
			positionStart.X.Offset + delta.X,
			positionStart.Y.Scale,
			positionStart.Y.Offset + delta.Y
		)
	end)

	return structures
end
