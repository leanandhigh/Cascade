--[[
	Sidebar user card (bottom-left of the window).

	[ avatar ]  Display name          [ gear ]
	            Account / key timer
]]

return function(self)
	--// Imports
	local creator = require("@modules/creator")
	local symbols = require("@modules/symbols")

	--// References
	local create = creator.Create

	--// Variables
	local structures = {}

	--// UI
	structures.Body = create("Frame")({
		Name = "Profile",
		AnchorPoint = Vector2.new(0, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 62),

		create("UIPadding")({
			Name = "UIPadding",
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 6),
		}),

		create("Frame")({
			Name = "Card",
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),

			__dynamicKeys = {
				BackgroundColor3 = self.Theme.Controls.Card.Fill[1],
				BackgroundTransparency = self.Theme.Controls.Card.Fill[2],
			},

			create("UICorner")({
				CornerRadius = UDim.new(0, 8),
			}),

			create("UIStroke")({
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,

				__dynamicKeys = {
					Color = self.Theme.Controls.ViewBorder[1],
					Transparency = self.Theme.Controls.ViewBorder[2],
				},
			}),

			create("UIPadding")({
				PaddingLeft = UDim.new(0, 7),
				PaddingRight = UDim.new(0, 6),
			}),

			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalFlex = Enum.UIFlexAlignment.None,
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

			create("Frame")({
				Name = "AvatarHolder",
				BorderSizePixel = 0,
				Size = UDim2.fromOffset(30, 30),

				__dynamicKeys = {
					BackgroundColor3 = self.Theme.Controls.Card.Hover[1],
					BackgroundTransparency = self.Theme.Controls.Card.Hover[2],
				},

				create("UICorner")({
					CornerRadius = UDim.new(1, 0),
				}),

				create("ImageLabel")({
					Name = "Avatar",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Size = UDim2.fromScale(1, 1),
					ScaleType = Enum.ScaleType.Crop,

					create("UICorner")({
						CornerRadius = UDim.new(1, 0),
					}),
				}),

				create("ImageLabel")({
					Name = "Placeholder",
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Image = symbols.personFill or symbols.person,
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromOffset(16, 16),
					Visible = false,

					__dynamicKeys = {
						ImageColor3 = self.Theme.Text.Secondary[1],
						ImageTransparency = self.Theme.Text.Secondary[2],
					},
				}),
			}),

			create("Frame")({
				Name = "Info",
				BackgroundTransparency = 1,
				LayoutOrder = 1,
				Size = UDim2.new(1, -68, 1, 0),

				create("UIListLayout")({
					Padding = UDim.new(0, 1),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),

				create("TextLabel")({
					Name = "DisplayName",
					BackgroundTransparency = 1,
					FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
					Size = UDim2.new(1, 0, 0, 16),
					Text = "Player",
					TextSize = 14,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,

					__dynamicKeys = {
						TextColor3 = self.Theme.Text.Primary[1],
						TextTransparency = self.Theme.Text.Primary[2],
					},
				}),

				create("TextLabel")({
					Name = "Subtitle",
					BackgroundTransparency = 1,
					FontFace = Font.new("rbxassetid://12187365364"),
					LayoutOrder = 1,
					RichText = true,
					Size = UDim2.new(1, 0, 0, 14),
					Text = "Account",
					TextSize = 12,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,

					__dynamicKeys = {
						TextColor3 = self.Theme.Text.Secondary[1],
						TextTransparency = self.Theme.Text.Secondary[2],
					},
				}),
			}),

			create("ImageButton")({
				Name = "Settings",
				AutoButtonColor = false,
				BorderSizePixel = 0,
				LayoutOrder = 2,
				Size = UDim2.fromOffset(22, 22),

				__dynamicKeys = {
					BackgroundColor3 = self.Theme.Controls.Card.Hover[1],
				},

				create("UICorner")({
					CornerRadius = UDim.new(0, 6),
				}),

				create("ImageLabel")({
					Name = "Icon",
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Image = symbols.gearshapeFill,
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromOffset(15, 15),

					__dynamicKeys = {
						ImageColor3 = self.Theme.Text.Secondary[1],
						ImageTransparency = self.Theme.Text.Secondary[2],
					},
				}),
			}),
		}),
	})

	--// Initialize
	structures.Card = structures.Body:FindFirstChild("Card") :: Frame
	structures.AvatarHolder = structures.Card:FindFirstChild("AvatarHolder") :: Frame
	structures.Avatar = structures.AvatarHolder:FindFirstChild("Avatar") :: ImageLabel
	structures.Placeholder = structures.AvatarHolder:FindFirstChild("Placeholder") :: ImageLabel
	structures.Info = structures.Card:FindFirstChild("Info") :: Frame
	structures.DisplayName = structures.Info:FindFirstChild("DisplayName") :: TextLabel
	structures.Subtitle = structures.Info:FindFirstChild("Subtitle") :: TextLabel
	structures.Settings = structures.Card:FindFirstChild("Settings") :: ImageButton

	structures.Settings.BackgroundTransparency = 1

	structures.Settings.MouseEnter:Connect(function()
		structures.Settings.BackgroundTransparency = self.Theme.Controls.Card.Hover[2].Value
	end)
	structures.Settings.MouseLeave:Connect(function()
		structures.Settings.BackgroundTransparency = 1
	end)

	return structures
end
