--[[
	InviteCard
	A card with an icon, title, subtitle and a pill that copies a link to the
	clipboard when clicked (Discord invites, websites, key links...).

	tab:InviteCard({
		Title = "Discord",
		Subtitle = "Click the invite to copy.",
		Invite = "https://discord.gg/xxxxxx",
	})
]]

local types = require("@types")

--// Functions
local function copyToClipboard(text: string): boolean
	-- Executor clipboard functions differ in name; try the common ones.
	local candidates = {
		setclipboard,
		toclipboard,
		set_clipboard,
		Clipboard and Clipboard.set,
		syn and syn.write_clipboard,
	}

	for _, fn in ipairs(candidates) do
		if typeof(fn) == "function" and pcall(fn, text) then
			return true
		end
	end

	return false
end

return function(self, properties: types.InviteCardProperties): types.InviteCard
	--// Imports
	local creator = require("@modules/creator")
	local binder = require("@modules/binder")
	local symbols = require("@modules/symbols")
	local icons = require("@modules/icons")

	--// References
	local create = creator.Create

	--// Variables
	local parent = self.__container or self.__instance or self
	local theme = self.Theme
	local structures = {}
	local flashToken = 0

	--// UI
	properties = properties or {}
	properties.Title = properties.Title or "Discord"
	properties.Subtitle = properties.Subtitle or "Click the invite to copy."
	properties.Invite = properties.Invite or ""
	properties.Icon = properties.Icon or "message-circle"

	structures.Body = create("Frame")({
		Name = "InviteCard",
		AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 0),
		Parent = parent,

		__dynamicKeys = {
			BackgroundColor3 = theme.Controls.View[1],
			BackgroundTransparency = theme.Controls.View[2],
		},

		create("UICorner")({
			CornerRadius = UDim.new(0, 8),
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

		create("Frame")({
			Name = "Header",
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 0),

			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 10),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			create("Frame")({
				Name = "IconHolder",
				BackgroundTransparency = 0.85,
				BorderSizePixel = 0,
				Size = UDim2.fromOffset(28, 28),

				__dynamicKeys = {
					BackgroundColor3 = theme.Controls.Selection[1],
				},

				create("UICorner")({
					CornerRadius = UDim.new(0, 7),
				}),

				create("ImageLabel")({
					ScaleType = Enum.ScaleType.Fit,
					Name = "Icon",
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromOffset(16, 16),

					__dynamicKeys = {
						ImageColor3 = theme.Controls.Selection[1],
					},
				}),
			}),

			create("Frame")({
				Name = "TitleStack",
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 1,
				Size = UDim2.new(1, -38, 0, 0),

				create("UIListLayout")({
					Padding = UDim.new(0, 1),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),

				create("TextLabel")({
					Name = "Title",
					BackgroundTransparency = 1,
					FontFace = Font.new(require("@modules/fonts").Family, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
					Size = UDim2.new(1, 0, 0, 17),
					TextSize = 14,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,

					__dynamicKeys = {
						TextColor3 = theme.Text.Primary[1],
						TextTransparency = theme.Text.Primary[2],
					},
				}),

				create("TextLabel")({
					Name = "Subtitle",
					BackgroundTransparency = 1,
					FontFace = Font.new(require("@modules/fonts").Family),
					LayoutOrder = 1,
					Size = UDim2.new(1, 0, 0, 14),
					TextSize = 12,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,

					__dynamicKeys = {
						TextColor3 = theme.Text.Secondary[1],
						TextTransparency = theme.Text.Secondary[2],
					},
				}),
			}),
		}),

		create("TextButton")({
			Name = "Invite",
			AutoButtonColor = false,
			AutomaticSize = Enum.AutomaticSize.X,
			BorderSizePixel = 0,
			FontFace = Font.new(require("@modules/fonts").Family, Enum.FontWeight.Medium, Enum.FontStyle.Normal),
			LayoutOrder = 1,
			Size = UDim2.fromOffset(0, 30),
			TextSize = 14,

			__dynamicKeys = {
				BackgroundColor3 = theme.Controls.Card.Hover[1],
				BackgroundTransparency = theme.Controls.Card.Hover[2],
				TextColor3 = theme.Text.Primary[1],
				TextTransparency = theme.Text.Primary[2],
			},

			create("UICorner")({
				CornerRadius = UDim.new(0, 7),
			}),

			create("UIPadding")({
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
			}),

			create("UIStroke")({
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,

				__dynamicKeys = {
					Color = theme.Controls.ViewBorder[1],
					Transparency = theme.Controls.ViewBorder[2],
				},
			}),
		}),
	}) :: Frame

	--// Initialize
	structures.Header = structures.Body:FindFirstChild("Header") :: Frame
	structures.IconHolder = structures.Header:FindFirstChild("IconHolder") :: Frame
	structures.Icon = structures.IconHolder:FindFirstChild("Icon") :: ImageLabel
	structures.TitleStack = structures.Header:FindFirstChild("TitleStack") :: Frame
	structures.Title = structures.TitleStack:FindFirstChild("Title") :: TextLabel
	structures.Subtitle = structures.TitleStack:FindFirstChild("Subtitle") :: TextLabel
	structures.Invite = structures.Body:FindFirstChild("Invite") :: TextButton

	local object
	object = binder.Wrap(properties, {
		Title = function(value: string)
			structures.Title.Text = value
		end,
		Subtitle = function(value: string)
			structures.Subtitle.Text = value
		end,
		Icon = function(value: string?)
			structures.IconHolder.Visible = value ~= nil and icons.Apply(structures.Icon, value, nil, 15)
			structures.TitleStack.Size = UDim2.new(1, value and -38 or 0, 0, 0)
		end,
		Invite = function(value: string)
			properties.Invite = value
			structures.Invite.Text = value
		end,
		SearchIndex = function(value: string)
			structures.Body:SetAttribute("SearchIndex", value)
		end,
	}, structures.Body)

	structures.Invite.MouseEnter:Connect(function()
		structures.Invite.BackgroundTransparency = math.max(0, theme.Controls.Card.Hover[2].Value - 0.06)
	end)
	structures.Invite.MouseLeave:Connect(function()
		structures.Invite.BackgroundTransparency = theme.Controls.Card.Hover[2].Value
	end)

	structures.Invite.MouseButton1Click:Connect(function()
		local copied = copyToClipboard(properties.Invite)

		flashToken += 1

		local token = flashToken

		structures.Invite.Text = copied and "Copied to clipboard!" or properties.Invite
		structures.Invite.TextColor3 = copied and theme.Controls.Status.Added[1].Value or theme.Text.Primary[1].Value

		if properties.Copied then
			task.spawn(properties.Copied, object, properties.Invite, copied)
		end

		task.delay(1.5, function()
			if token ~= flashToken then
				return
			end

			structures.Invite.Text = properties.Invite
			structures.Invite.TextColor3 = theme.Text.Primary[1].Value
		end)
	end)

	object.Type = "InviteCard"
	object.Theme = self.Theme
	object.Structures = structures

	binder.Apply(properties, object)

	return object
end
