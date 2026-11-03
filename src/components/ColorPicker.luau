--[[
	ColorPicker
	A colour swatch that opens a picker: saturation / brightness square, hue bar, optional
	transparency bar, hex and RGB fields, copy / paste. Works with mouse and touch.

	row:Right():ColorPicker({
		Flag = "EspColor",               -- saved in configs (Color3)
		Value = Color3.fromRGB(0, 255, 140),
		Transparency = 0,                -- optional: adds a transparency bar (0 = solid)
		Title = "ESP color",             -- optional title in the picker
		ValueChanged = function(self, color: Color3, transparency: number?) end,
	})

	Layout and math follow Obsidian's colour picker (saturation map 4155801252, hue gradient,
	cursor at (saturation, 1 - brightness)).
]]

local types = require("@types")

--// Constants
local SATURATION_MAP = "rbxassetid://4155801252"
local CHECKER = "rbxassetid://139785960036434"
local MAP_SIZE = 180
local BAR_WIDTH = 16

-- Shared between every picker (Copy on one, Paste on another)
local copied = nil

local hueSequence = (function()
	local keypoints = {}

	for step = 0, 10 do
		table.insert(keypoints, ColorSequenceKeypoint.new(step / 10, Color3.fromHSV(step / 10, 1, 1)))
	end

	return ColorSequence.new(keypoints)
end)()

return function(self, properties: types.ColorPickerProperties): types.ColorPicker
	--// Imports
	local creator = require("@modules/creator")
	local binder = require("@modules/binder")
	local services = require("@modules/services")
	local utility = require("@modules/utility")

	--// References
	local create = creator.Create
	local userInputService = services.UserInputService
	local tweenService = services.TweenService
	local workspace = services.Workspace

	--// Variables
	local parent = self.__container or self.__instance or self
	local theme = self.Theme
	local font = "rbxassetid://12187365364"
	local structures = {}

	properties = properties or {}
	properties.Value = typeof(properties.Value) == "Color3" and properties.Value or Color3.new(1, 1, 1)

	local hasTransparency = typeof(properties.Transparency) == "number"
	local hue, saturation, brightness = properties.Value:ToHSV()
	local transparency = hasTransparency and properties.Transparency or 0
	local open = false
	local token = 0
	local object

	--// Swatch (sits in the row)
	structures.Body = create("TextButton")({
		Name = "ColorPicker",
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(38, 22),
		Text = "",
		Parent = parent,

		create("UICorner")({
			CornerRadius = UDim.new(0, 6),
		}),

		create("UIStroke")({
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,

			__dynamicKeys = {
				Color = theme.Controls.ViewBorder[1],
				Transparency = theme.Controls.ViewBorder[2],
			},
		}),

		-- Checkerboard shows through when the colour is transparent
		create("ImageLabel")({
			Name = "Checker",
			BackgroundTransparency = 1,
			Image = CHECKER,
			ImageTransparency = 1,
			ScaleType = Enum.ScaleType.Tile,
			Size = UDim2.fromScale(1, 1),
			TileSize = UDim2.fromOffset(8, 8),
			ZIndex = 0,

			create("UICorner")({
				CornerRadius = UDim.new(0, 6),
			}),
		}),
	})

	--// Picker panel (own ScreenGui so it's never clipped by the window)
	structures.Container = create("ScreenGui")({
		Name = "ColorPickerPanel",
		DisplayOrder = 203,
		Enabled = false,
		IgnoreGuiInset = true,
		OnTopOfCoreBlur = true,
		ResetOnSpawn = false,
		ScreenInsets = Enum.ScreenInsets.None,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})

	local panelWidth = MAP_SIZE + 8 + BAR_WIDTH + (hasTransparency and (8 + BAR_WIDTH) or 0) + 24

	structures.Panel = create("CanvasGroup")({
		Name = "Panel",
		AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		Size = UDim2.fromOffset(panelWidth, 0),
		Parent = structures.Container.__instance,

		__dynamicKeys = {
			BackgroundColor3 = theme.Controls.MenuButton.MenuBackground[1],
			BackgroundTransparency = theme.Controls.MenuButton.MenuBackground[2],
		},

		create("UICorner")({
			CornerRadius = UDim.new(0, 10),
		}),

		create("UIStroke")({
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,

			__dynamicKeys = {
				Color = theme.Controls.ViewBorder[1],
				Transparency = theme.Controls.ViewBorder[2],
			},
		}),

		create("UIPadding")({
			PaddingBottom = UDim.new(0, 12),
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
			PaddingTop = UDim.new(0, 12),
		}),

		create("UIListLayout")({
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),

		create("TextLabel")({
			Name = "Title",
			BackgroundTransparency = 1,
			FontFace = Font.new(font, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
			Size = UDim2.new(1, 0, 0, 16),
			Text = properties.Title or "",
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			Visible = properties.Title ~= nil,

			__dynamicKeys = {
				TextColor3 = theme.Text.Primary[1],
				TextTransparency = theme.Text.Primary[2],
			},
		}),

		create("Frame")({
			Name = "Pickers",
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, MAP_SIZE),

			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			-- Saturation (x) / brightness (y)
			create("ImageButton")({
				Name = "Map",
				AutoButtonColor = false,
				BorderSizePixel = 0,
				Image = SATURATION_MAP,
				Size = UDim2.fromOffset(MAP_SIZE, MAP_SIZE),

				create("UICorner")({
					CornerRadius = UDim.new(0, 6),
				}),

				create("Frame")({
					Name = "Cursor",
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.new(1, 1, 1),
					BorderSizePixel = 0,
					Size = UDim2.fromOffset(12, 12),
					ZIndex = 3,

					create("UICorner")({
						CornerRadius = UDim.new(1, 0),
					}),

					create("UIStroke")({
						Color = Color3.new(0, 0, 0),
						Thickness = 1.5,
						Transparency = 0.4,
					}),
				}),
			}),

			-- Hue
			create("ImageButton")({
				Name = "Hue",
				AutoButtonColor = false,
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				LayoutOrder = 1,
				Size = UDim2.fromOffset(BAR_WIDTH, MAP_SIZE),

				create("UICorner")({
					CornerRadius = UDim.new(0, 5),
				}),

				create("UIGradient")({
					Color = hueSequence,
					Rotation = 90,
				}),

				create("Frame")({
					Name = "Cursor",
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.new(1, 1, 1),
					BorderSizePixel = 0,
					Position = UDim2.fromScale(0.5, 0),
					Size = UDim2.new(1, 4, 0, 4),
					ZIndex = 3,

					create("UICorner")({
						CornerRadius = UDim.new(1, 0),
					}),

					create("UIStroke")({
						Color = Color3.new(0, 0, 0),
						Transparency = 0.4,
					}),
				}),
			}),

			-- Transparency (only when Transparency was given)
			create("ImageButton")({
				Name = "Alpha",
				AutoButtonColor = false,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Image = CHECKER,
				LayoutOrder = 2,
				ScaleType = Enum.ScaleType.Tile,
				Size = UDim2.fromOffset(BAR_WIDTH, MAP_SIZE),
				TileSize = UDim2.fromOffset(8, 8),
				Visible = hasTransparency,

				create("UICorner")({
					CornerRadius = UDim.new(0, 5),
				}),

				create("Frame")({
					Name = "Fill",
					BorderSizePixel = 0,
					Size = UDim2.fromScale(1, 1),

					create("UICorner")({
						CornerRadius = UDim.new(0, 5),
					}),

					create("UIGradient")({
						Rotation = 90,
						Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 0),
							NumberSequenceKeypoint.new(1, 1),
						}),
					}),
				}),

				create("Frame")({
					Name = "Cursor",
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.new(1, 1, 1),
					BorderSizePixel = 0,
					Position = UDim2.fromScale(0.5, 0),
					Size = UDim2.new(1, 4, 0, 4),
					ZIndex = 3,

					create("UICorner")({
						CornerRadius = UDim.new(1, 0),
					}),

					create("UIStroke")({
						Color = Color3.new(0, 0, 0),
						Transparency = 0.4,
					}),
				}),
			}),
		}),

		-- Hex + RGB fields
		create("Frame")({
			Name = "Fields",
			BackgroundTransparency = 1,
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 28),

			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalFlex = Enum.UIFlexAlignment.Fill,
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		}),

		-- Copy / paste between pickers
		create("Frame")({
			Name = "Actions",
			BackgroundTransparency = 1,
			LayoutOrder = 3,
			Size = UDim2.new(1, 0, 0, 26),

			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalFlex = Enum.UIFlexAlignment.Fill,
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		}),
	})

	utility.ProtectUI(structures.Container.__instance)

	local panel = structures.Panel.__instance
	local pickers = panel:FindFirstChild("Pickers")
	local map = pickers:FindFirstChild("Map") :: ImageButton
	local mapCursor = map:FindFirstChild("Cursor") :: Frame
	local hueBar = pickers:FindFirstChild("Hue") :: ImageButton
	local hueCursor = hueBar:FindFirstChild("Cursor") :: Frame
	local alphaBar = pickers:FindFirstChild("Alpha") :: ImageButton
	local alphaFill = alphaBar:FindFirstChild("Fill") :: Frame
	local alphaCursor = alphaBar:FindFirstChild("Cursor") :: Frame
	local checker = structures.Body:FindFirstChild("Checker") :: ImageLabel

	structures.Map = map
	structures.HueBar = hueBar
	structures.AlphaBar = alphaBar

	local function field(name: string, order: number)
		return create("TextBox")({
			Name = name,
			BorderSizePixel = 0,
			ClearTextOnFocus = false,
			FontFace = Font.new(font),
			LayoutOrder = order,
			Size = UDim2.new(0.5, 0, 1, 0),
			Text = "",
			TextSize = 13,
			Parent = panel:FindFirstChild("Fields"),

			__dynamicKeys = {
				BackgroundColor3 = theme.Controls.Card.Fill[1],
				BackgroundTransparency = theme.Controls.Card.Fill[2],
				TextColor3 = theme.Text.Primary[1],
				TextTransparency = theme.Text.Primary[2],
			},

			create("UICorner")({
				CornerRadius = UDim.new(0, 6),
			}),

			create("UIStroke")({
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,

				__dynamicKeys = {
					Color = theme.Controls.ViewBorder[1],
					Transparency = theme.Controls.ViewBorder[2],
				},
			}),
		})
	end

	structures.HexField = field("Hex", 1)
	structures.RgbField = field("RGB", 2)

	--// Display
	local function color(): Color3
		return Color3.fromHSV(hue, saturation, brightness)
	end

	local function render()
		local current = color()

		map.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
		mapCursor.Position = UDim2.fromScale(saturation, 1 - brightness)
		hueCursor.Position = UDim2.fromScale(0.5, hue)
		alphaFill.BackgroundColor3 = current
		alphaCursor.Position = UDim2.fromScale(0.5, transparency)

		structures.Body.BackgroundColor3 = current
		structures.Body.BackgroundTransparency = transparency
		checker.ImageTransparency = transparency > 0 and 0.5 or 1

		if not structures.HexField:IsFocused() then
			structures.HexField.Text = "#" .. string.upper(current:ToHex())
		end

		if not structures.RgbField:IsFocused() then
			structures.RgbField.Text = string.format(
				"%d, %d, %d",
				math.floor(current.R * 255 + 0.5),
				math.floor(current.G * 255 + 0.5),
				math.floor(current.B * 255 + 0.5)
			)
		end
	end

	-- Push the colour picked in the panel out as the component's Value (fires ValueChanged).
	-- `fromPanel` keeps the panel's own hue / saturation: re-deriving them from the colour would
	-- make the cursor jump (eg. saturation becomes 0 when brightness is 0).
	local fromPanel = false

	local function commit()
		fromPanel = true
		object.Value = color()
		fromPanel = false
	end

	--// Dragging (mouse + touch)
	local dragging = nil

	local function updateFromInput(position)
		if dragging == map then
			local x = math.clamp((position.X - map.AbsolutePosition.X) / map.AbsoluteSize.X, 0, 1)
			local y = math.clamp((position.Y - map.AbsolutePosition.Y) / map.AbsoluteSize.Y, 0, 1)

			saturation, brightness = x, 1 - y
		elseif dragging == hueBar then
			hue = math.clamp((position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
		elseif dragging == alphaBar then
			transparency = math.clamp((position.Y - alphaBar.AbsolutePosition.Y) / alphaBar.AbsoluteSize.Y, 0, 1)
			properties.Transparency = transparency
		end

		render()
		commit()
	end

	for _, target in { map, hueBar, alphaBar } do
		target.InputBegan:Connect(function(input)
			if
				input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end

			dragging = target
			updateFromInput(input.Position)

			local connection
			connection = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					connection:Disconnect()

					if dragging == target then
						dragging = nil
					end
				end
			end)
		end)
	end

	userInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end

		if
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		then
			updateFromInput(input.Position)
		end
	end)

	userInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = nil
		end
	end)

	--// Fields
	structures.HexField.FocusLost:Connect(function()
		local ok, parsed = pcall(Color3.fromHex, (string.gsub(structures.HexField.Text, "#", "")))

		if ok and typeof(parsed) == "Color3" then
			object.Value = parsed
		else
			render()
		end
	end)

	structures.RgbField.FocusLost:Connect(function()
		local r, g, b = string.match(structures.RgbField.Text, "(%d+)%D+(%d+)%D+(%d+)")

		if r and g and b then
			object.Value = Color3.fromRGB(math.clamp(tonumber(r), 0, 255), math.clamp(tonumber(g), 0, 255), math.clamp(tonumber(b), 0, 255))
		else
			render()
		end
	end)

	--// Copy / paste
	local actionsContext = setmetatable({
		Theme = theme,
		__container = panel:FindFirstChild("Actions"),
	}, { __index = self })

	local copyButton = (actionsContext:Button({
		Label = "Copy",
		State = "Secondary",
		Pushed = function()
			copied = { color(), transparency }
		end,
	}))

	local pasteButton = (actionsContext:Button({
		Label = "Paste",
		State = "Secondary",
		Pushed = function()
			if copied then
				if hasTransparency then
					transparency = copied[2]
					properties.Transparency = transparency
				end

				object.Value = copied[1]
			end
		end,
	}))

	for _, button in { copyButton, pasteButton } do
		button.AutomaticSize = Enum.AutomaticSize.None
		button.Size = UDim2.new(0.5, -4, 0, 26)
	end

	--// Open / close
	local function position()
		local camera = workspace.CurrentCamera
		local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
		local anchor = structures.Body.__instance
		local size = panel.AbsoluteSize

		local x = anchor.AbsolutePosition.X + anchor.AbsoluteSize.X - size.X
		local y = anchor.AbsolutePosition.Y + anchor.AbsoluteSize.Y + 6

		if y + size.Y > viewport.Y - 6 then
			y = anchor.AbsolutePosition.Y - size.Y - 6
		end

		panel.Position = UDim2.fromOffset(
			math.clamp(x, 6, math.max(6, viewport.X - size.X - 6)),
			math.clamp(y, 6, math.max(6, viewport.Y - size.Y - 6))
		)
	end

	local function setOpen(value: boolean)
		if open == value then
			return
		end

		open = value
		token += 1

		local current = token

		if open then
			render()
			structures.Container.Enabled = true
			position()
			task.defer(position)
		end

		local tween = tweenService:Create(
			panel,
			TweenInfo.new(0.18, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
			{ GroupTransparency = open and 0 or 1 }
		)

		tween.Completed:Connect(function()
			if not open and current == token then
				structures.Container.Enabled = false
			end
		end)
		tween:Play()
	end

	structures.Body.MouseButton1Click:Connect(function()
		setOpen(not open)
	end)

	userInputService.InputBegan:Connect(function(input)
		if not open then
			return
		end

		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		local function inside(gui)
			local pos, size = gui.AbsolutePosition, gui.AbsoluteSize

			return input.Position.X >= pos.X
				and input.Position.X <= pos.X + size.X
				and input.Position.Y >= pos.Y
				and input.Position.Y <= pos.Y + size.Y
		end

		if not inside(panel) and not inside(structures.Body.__instance) then
			setOpen(false)
		end
	end)

	-- Close + clean up with the window / app
	structures.Body.Destroying:Connect(function()
		structures.Container:Destroy()
	end)

	--// Component
	object = binder.Wrap(properties, {
		Value = function(value: Color3)
			if typeof(value) ~= "Color3" then
				return
			end

			if not fromPanel then
				-- Keep the hue when the colour has no hue (greys) so the hue bar doesn't jump
				local h, s, v = value:ToHSV()

				if s > 0 and v > 0 then
					hue = h
				end

				saturation, brightness = s, v
			end
			properties.Value = value
			render()

			if properties.ValueChanged then
				task.spawn(properties.ValueChanged, object, value, hasTransparency and transparency or nil)
			end
		end,
		Transparency = function(value: number)
			if typeof(value) == "number" then
				transparency = math.clamp(value, 0, 1)
				properties.Transparency = transparency
				render()
			end
		end,
		Title = function(value: string?)
			local title = panel:FindFirstChild("Title")

			title.Text = value or ""
			title.Visible = value ~= nil
		end,
	}, structures.Body)

	object.Type = "ColorPicker"
	object.Theme = self.Theme
	object.Structures = structures
	object.Open = function()
		setOpen(true)
	end
	object.Close = function()
		setOpen(false)
	end

	binder.Apply(properties, object)
	render()

	return object
end
