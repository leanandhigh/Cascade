--[[
	Card section (MTwin style): a panel with a bold title, a muted subtitle, a collapse chevron
	on the right, and a content area. Shared by PriorityList, UpdateLog and FarmStats.

	local card = require("@structures/CardSection")(self, {
		Name = "PriorityList",
		Title = "Join priority",
		Subtitle = "Top enabled route wins",
		Collapsible = true,
		Parent = parent,
	})
	card.Content  -- put your items here
]]

return function(self, config)
	--// Imports
	local creator = require("@modules/creator")
	local services = require("@modules/services")
	local icons = require("@modules/icons")
	local symbols = require("@modules/symbols")

	--// References
	local create = creator.Create
	local tweenService = services.TweenService

	--// Variables
	local theme = self.Theme
	local structures = {}

	config = config or {}

	local collapsible = config.Collapsible ~= false
	local collapsed = config.Collapsed == true

	structures.Body = create("Frame")({
		Name = config.Name or "CardSection",
		AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 0),
		Parent = config.Parent,

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
			PaddingBottom = UDim.new(0, 14),
			PaddingLeft = UDim.new(0, 14),
			PaddingRight = UDim.new(0, 14),
			PaddingTop = UDim.new(0, 12),
		}),

		create("UIListLayout")({
			Padding = UDim.new(0, 12),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),

		create("TextButton")({
			Name = "Header",
			AutoButtonColor = false,
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 0),
			Text = "",

			create("Frame")({
				Name = "Texts",
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -28, 0, 0),

				-- Same metrics as the Groupbox header (title 15 / 17px line, subtitle 12, 1px gap)
				create("UIListLayout")({
					Padding = UDim.new(0, 1),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),

				create("TextLabel")({
					Name = "Title",
					BackgroundTransparency = 1,
					FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
					Size = UDim2.new(1, 0, 0, 17),
					Text = config.Title or "",
					TextSize = 15,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Center,

					__dynamicKeys = {
						TextColor3 = theme.Text.Primary[1],
						TextTransparency = theme.Text.Primary[2],
					},
				}),

				create("TextLabel")({
					Name = "Subtitle",
					BackgroundTransparency = 1,
					FontFace = Font.new("rbxassetid://12187365364"),
					LayoutOrder = 1,
					Size = UDim2.new(1, 0, 0, 14),
					Text = config.Subtitle or "",
					TextSize = 12,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextWrapped = false,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					Visible = config.Subtitle ~= nil and config.Subtitle ~= "",

					__dynamicKeys = {
						TextColor3 = theme.Text.Secondary[1],
						TextTransparency = theme.Text.Secondary[2],
					},
				}),
			}),

			-- Right-side slot (eg. a count pill), left of the chevron
			create("Frame")({
				Name = "Trailing",
				AnchorPoint = Vector2.new(1, 0.5),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -24, 0.5, 0),
				Size = UDim2.fromOffset(0, 20),

				create("UIListLayout")({
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					Padding = UDim.new(0, 6),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),
			}),

			create("ImageLabel")({
				Name = "Chevron",
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -2, 0.5, 0),
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromOffset(14, 14),
				Visible = collapsible,

				__dynamicKeys = {
					ImageColor3 = theme.Text.Secondary[1],
					ImageTransparency = theme.Text.Secondary[2],
				},
			}),
		}),

		create("Frame")({
			Name = "Content",
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			LayoutOrder = 1,
			Size = UDim2.fromScale(1, 0),
		}),
	})

	structures.Header = structures.Body:FindFirstChild("Header") :: TextButton
	structures.Texts = structures.Header:FindFirstChild("Texts") :: Frame
	structures.Title = structures.Texts:FindFirstChild("Title") :: TextLabel
	structures.Subtitle = structures.Texts:FindFirstChild("Subtitle") :: TextLabel
	structures.Trailing = structures.Header:FindFirstChild("Trailing") :: Frame
	structures.Chevron = structures.Header:FindFirstChild("Chevron") :: ImageLabel
	structures.Content = structures.Body:FindFirstChild("Content") :: Frame

	icons.Apply(structures.Chevron, "chevron-down", symbols.chevronDown, 14)

	local listeners = {}

	structures.SetTitle = function(value: string?)
		structures.Title.Text = value or ""
	end

	structures.SetSubtitle = function(value: string?)
		structures.Subtitle.Text = value or ""
		structures.Subtitle.Visible = value ~= nil and value ~= ""
	end

	structures.IsCollapsed = function(): boolean
		return collapsed
	end

	structures.SetCollapsed = function(value: boolean, instant: boolean?)
		collapsed = value == true and collapsible
		structures.Content.Visible = not collapsed

		local rotation = collapsed and -90 or 0

		if instant then
			structures.Chevron.Rotation = rotation
		else
			tweenService
				:Create(
					structures.Chevron,
					TweenInfo.new(0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
					{ Rotation = rotation }
				)
				:Play()
		end

		for _, callback in ipairs(listeners) do
			task.spawn(callback, collapsed)
		end
	end

	structures.SetCollapsible = function(value: boolean)
		collapsible = value ~= false
		structures.Chevron.Visible = collapsible

		if not collapsible and collapsed then
			structures.SetCollapsed(false, true)
		end
	end

	structures.OnCollapsed = function(callback)
		table.insert(listeners, callback)
	end

	-- Lays the content out as a grid of equal cards: as many columns (up to MaxColumns) as fit
	-- with at least MinColumnWidth each, so phones get one column. Measured in offset units.
	structures.UseGrid = function(options)
		options = options or {}

		local gap = options.Gap or 8
		local cellHeight = options.CellHeight or 40
		local maxColumns = options.MaxColumns or 2
		local minWidth = options.MinColumnWidth or 190

		local grid = create("UIGridLayout")({
			CellPadding = UDim2.fromOffset(gap, gap),
			CellSize = UDim2.new(1 / maxColumns, -gap, 0, cellHeight),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = structures.Content,
		}).__instance :: UIGridLayout

		local columns = nil

		local function update()
			local scale = require("@modules/utility").GetScale(structures.Content)
			local width = structures.Content.AbsoluteSize.X

			if scale < 0.05 or width <= 0 then
				return
			end

			width /= scale

			local count = math.clamp(math.floor((width + gap) / (minWidth + gap)), 1, maxColumns)

			if count == columns then
				return
			end

			columns = count
			grid.CellSize = UDim2.new(1 / count, -math.ceil(gap * (count - 1) / count), 0, cellHeight)
		end

		structures.Content:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
		task.defer(update)
		update()

		structures.Grid = grid
		structures.GridColumns = function()
			return columns or maxColumns
		end

		return grid
	end

	structures.Header.MouseButton1Click:Connect(function()
		if collapsible then
			structures.SetCollapsed(not collapsed)
		end
	end)

	structures.SetCollapsed(collapsed, true)

	return structures
end
