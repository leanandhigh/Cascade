--// Imports
local creator = require("@modules/creator")

--// Types
type DropdownMenuStructureConfig = {
	Name: string?,
}

return function(self, config: DropdownMenuStructureConfig?)
	--// Variables
	local create = creator.Create

	config = config or {}

	local theme = self.Theme.Controls.MenuButton
	local structures = {}

	structures.Container = create("ScreenGui")({
		Name = "Container",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ScreenInsets = Enum.ScreenInsets.None,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 201,
		OnTopOfCoreBlur = true,

		create("CanvasGroup")({
			Name = "MenuBody",
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			GroupTransparency = 1,
			Size = UDim2.fromScale(1, 1),

			create("ScrollingFrame")({
				Name = config.Name or "DropdownMenu",
				AutomaticSize = Enum.AutomaticSize.XY,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.new(),
				ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0),
				ScrollBarImageTransparency = 0.5,
				ScrollBarThickness = 3,

				__dynamicKeys = {
					BackgroundColor3 = theme.MenuBackground[1],
					BackgroundTransparency = theme.MenuBackground[2],
					ScrollBarImageColor3 = self.Theme.Controls.ScrollBar[1],
					ScrollBarImageTransparency = self.Theme.Controls.ScrollBar[2],
				},

				create("UICorner")({
					Name = "UICorner",
					CornerRadius = UDim.new(0, 6),
				}),

				create("UIStroke")({
					Name = "UIStroke",
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Transparency = 0.9,
				}),

				create("UIPadding")({
					Name = "UIPadding",
					PaddingBottom = UDim.new(0, 5),
					PaddingLeft = UDim.new(0, 5),
					PaddingRight = UDim.new(0, 5),
					PaddingTop = UDim.new(0, 5),
				}),

				create("UIListLayout")({
					Name = "UIListLayout",
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 1),
				}),
			}),
		}),
	}) :: ScreenGui

	structures.Body = structures.Container:FindFirstChild("MenuBody") :: CanvasGroup
	structures.Menu = structures.Body:FindFirstChild(config.Name or "DropdownMenu") :: ScrollingFrame

	--// Public Methods
	-- Row: [tick] [image] name. `icon` (optional) is an asset id / rbxthumb / Lucide name.
	function structures.Item(name: string?, index: number, showsCheckmark: boolean?, icon: any?): TextButton
		local item = nil
		item = create("TextButton")({
			Name = "Item",
			Size = UDim2.fromScale(1, 0),
			AutoButtonColor = false,
			AutomaticSize = Enum.AutomaticSize.XY,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			Selectable = false,
			Text = "",
			LayoutOrder = index,
			Parent = structures.Menu,

			__dynamicKeys = {
				BackgroundColor3 = self.Theme.Controls.SelectionFocused[1],
			},
			__contextKeys = {
				BackgroundTransparency = function()
					if not item then
						return
					end
					return item.GuiState == Enum.GuiState.Hover and self.Theme.Controls.SelectionFocused[2].Value or 1
				end,
			},

			create("UIPadding")({
				Name = "UIPadding",
				PaddingBottom = UDim.new(0, 3),
				PaddingLeft = UDim.new(0, 7),
				PaddingRight = UDim.new(0, 12),
				PaddingTop = UDim.new(0, 3),
			}),

			create("UIListLayout")({
				Name = "UIListLayout",
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 2),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

			create("TextLabel")({
				Name = "Label",
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxassetid://12187365364"),
				LayoutOrder = 2,
				RichText = true,
				Text = name or "",
				TextColor3 = Color3.fromRGB(0, 0, 0),
				TextSize = 15,
				TextTransparency = 0.15,
				TextTruncate = Enum.TextTruncate.AtEnd,

				__dynamicKeys = {
					TextColor3 = self.Theme.Text.Primary[1],
					TextTransparency = self.Theme.Text.Primary[2],
				},
			}),

			create("UICorner")({
				Name = "UICorner",
				CornerRadius = UDim.new(0, 5),
			}),
		}) :: TextButton

		if icon ~= nil then
			local icons = require("@modules/icons")
			local isGlyph = icons.IsGlyph(icon)
			local image = create("ImageLabel")({
				Name = "Icon",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				LayoutOrder = 1,
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromOffset(18, 18),
				Parent = item.__instance,

				create("UICorner")({
					CornerRadius = UDim.new(0, 4),
				}),
			}).__instance :: ImageLabel

			icons.Apply(image, icon, nil, 16)
			image:SetAttribute("Glyph", isGlyph)
			image.ImageColor3 = isGlyph and self.Theme.Text.Primary[1].Value or Color3.new(1, 1, 1)

			-- a little room between the image and the name
			item.__instance:FindFirstChildOfClass("UIListLayout").Padding = UDim.new(0, 6)
		end

		if showsCheckmark then
			create("ImageLabel")({
				Name = "Checkmark",
				LayoutOrder = 0, -- tick first, then the image, then the name
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Image = "rbxassetid://127464789357538",
				ImageColor3 = Color3.fromRGB(0, 0, 0),
				ImageTransparency = 1,
				Size = UDim2.fromOffset(16, 16),
				Visible = false,
				Parent = item.__instance,

				__dynamicKeys = {
					ImageColor3 = self.Theme.Text.Primary[1],
					ImageTransparency = self.Theme.Text.Primary[2],
				},
			})

			create("Frame")({
				Name = "CheckmarkRepl",
				LayoutOrder = 0,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Size = UDim2.fromOffset(16, 16),
				Visible = true,
				Parent = item.__instance,
			})
		end

		return item.__instance
	end

	--// Publish
	return structures
end
