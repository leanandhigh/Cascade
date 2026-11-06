--[[
	Groupbox
	A collapsible, titled box that groups related controls.

	local box = tab:Groupbox({
		Title = "Groupbox",
		Subtitle = "boxes",
		Icon = cascade.Symbols.cube,
	})

	box:Row({ Title = "This is a toggle" }):Right():Toggle({ Value = true })

	Side by side, without creating Columns yourself:
	tab:Groupbox({ Title = "Left box", Side = "Left" })
	tab:Groupbox({ Title = "Right box", Side = "Right" })
]]

local types = require("@types")

-- Two-column holders created by `Side = "Left" | "Right"`, one per parent container
local sideColumns = setmetatable({}, { __mode = "k" })

local function sideIndex(side): number
	if side == 2 or (typeof(side) == "string" and string.lower(side) == "right") then
		return 2
	end

	return 1
end

return function(self, properties: types.GroupboxProperties): types.Groupbox
	--// Imports
	local creator = require("@modules/creator")
	local binder = require("@modules/binder")
	local services = require("@modules/services")
	local symbols = require("@modules/symbols")
	local icons = require("@modules/icons")

	--// References
	local create = creator.Create

	local tweenService = services.TweenService

	--// Variables
	local parent = self.__container or self.__instance or self
	local structures = {}
	local entries = {}
	local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

	--// UI
	properties = properties or {}
	properties.Title = properties.Title or "Groupbox"
	properties.Subtitle = properties.Subtitle or properties.Description
	properties.Description = nil
	properties.Expanded = properties.Expanded ~= false
	properties.Collapsible = properties.Collapsible ~= false

	if properties.Collapsed ~= nil then
		properties.Expanded = not properties.Collapsed
		properties.Collapsed = nil
	end

	if properties.Side ~= nil then
		local columns = sideColumns[parent]

		if not columns or not columns.Structures.Body.Parent then
			columns = require("@components/Columns")(self, { Count = 2 })
			sideColumns[parent] = columns
		end

		parent = columns.Structures.Columns[sideIndex(properties.Side)]
		properties.Side = nil
	end

	structures.Body = create("Frame")({
		Name = "Groupbox",
		AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 0),
		Parent = parent,

		__dynamicKeys = {
			BackgroundColor3 = self.Theme.Controls.View[1],
			BackgroundTransparency = self.Theme.Controls.View[2],
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

		create("UIListLayout")({
			Name = "UIListLayout",
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),

		create("TextButton")({
			Name = "Header",
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 52),
			Text = "",

			create("UIPadding")({
				PaddingLeft = UDim.new(0, 14),
				PaddingRight = UDim.new(0, 14),
			}),

			create("Frame")({
				Name = "IconHolder",
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 0.85,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.fromOffset(28, 28),
				Visible = false,

				__dynamicKeys = {
					BackgroundColor3 = self.Theme.Controls.Selection[1],
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
					Size = UDim2.fromOffset(18, 18),

					__dynamicKeys = {
						ImageColor3 = self.Theme.Controls.Selection[1],
					},
				}),
			}),

			create("Frame")({
				Name = "TitleStack",
				AnchorPoint = Vector2.new(0, 0.5),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.new(1, -24, 0, 0),

				create("UIListLayout")({
					Padding = UDim.new(0, 1),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),

				create("TextLabel")({
					Name = "Title",
					BackgroundTransparency = 1,
					FontFace = Font.new(require("@modules/fonts").Family, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
					RichText = true,
					Size = UDim2.new(1, 0, 0, 17),
					TextSize = 15,
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
					FontFace = Font.new(require("@modules/fonts").Family),
					LayoutOrder = 1,
					RichText = true,
					Size = UDim2.new(1, 0, 0, 14),
					TextSize = 12,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,
					Visible = false,

					__dynamicKeys = {
						TextColor3 = self.Theme.Text.Secondary[1],
						TextTransparency = self.Theme.Text.Secondary[2],
					},
				}),
			}),

			create("ImageLabel")({
				ScaleType = Enum.ScaleType.Fit,
				Name = "Chevron",
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundTransparency = 1,
				Image = symbols.chevronDown,
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.fromOffset(14, 14),

				__dynamicKeys = {
					ImageColor3 = self.Theme.Text.Secondary[1],
					ImageTransparency = self.Theme.Text.Secondary[2],
				},
			}),
		}),

		create("Frame")({
			Name = "Divider",
			BorderSizePixel = 0,
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 1),

			__dynamicKeys = {
				BackgroundColor3 = self.Theme.Controls.ViewBorder[1],
				BackgroundTransparency = self.Theme.Controls.ViewBorder[2],
			},
		}),

		create("Frame")({
			Name = "Clip",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			LayoutOrder = 2,
			Size = UDim2.fromScale(1, 0),

			create("Frame")({
				Name = "Content",
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1, 0),

				create("UIListLayout")({
					Name = "UIListLayout",
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),

				create("UIPadding")({
					Name = "Margins",
					PaddingBottom = UDim.new(0, 6),
					PaddingLeft = UDim.new(0, 14),
					PaddingRight = UDim.new(0, 14),
					PaddingTop = UDim.new(0, 4),
				}),
			}),
		}),
	}) :: Frame

	--// Initialize
	structures.Header = structures.Body:FindFirstChild("Header") :: TextButton
	structures.IconHolder = structures.Header:FindFirstChild("IconHolder") :: Frame
	structures.Icon = structures.IconHolder:FindFirstChild("Icon") :: ImageLabel
	structures.TitleStack = structures.Header:FindFirstChild("TitleStack") :: Frame
	structures.Title = structures.TitleStack:FindFirstChild("Title") :: TextLabel
	structures.Subtitle = structures.TitleStack:FindFirstChild("Subtitle") :: TextLabel
	structures.Chevron = structures.Header:FindFirstChild("Chevron") :: ImageLabel
	structures.Divider = structures.Body:FindFirstChild("Divider") :: Frame
	structures.Clip = structures.Body:FindFirstChild("Clip") :: Frame
	structures.Content = structures.Clip:FindFirstChild("Content") :: Frame

	icons.Apply(structures.Chevron, "chevron-down", symbols.chevronDown, 14)

	local function contentHeight(): number
		-- AbsoluteSize is in screen pixels; Clip.Size is an offset (mobile UIScale)
		local scale = require("@modules/utility").GetScale(structures.Content)

		return scale < 0.05 and structures.Clip.Size.Y.Offset or structures.Content.AbsoluteSize.Y / scale
	end

	local function resize(useTween: boolean)
		local target = UDim2.new(1, 0, 0, properties.Expanded and contentHeight() or 0)

		if useTween then
			tweenService:Create(structures.Clip, tweenInfo, { Size = target }):Play()
		else
			structures.Clip.Size = target
		end
	end

	local function layoutHeader()
		local hasIcon = structures.IconHolder.Visible
		local leading = hasIcon and 40 or 0
		local trailing = properties.Collapsible and 24 or 0

		structures.TitleStack.Position = UDim2.new(0, leading, 0.5, 0)
		structures.TitleStack.Size = UDim2.new(1, -(leading + trailing), 0, 0)
	end

	-- Keep the clip in sync while expanded (controls added later, text wrapping, etc.)
	structures.Content:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if properties.Expanded then
			resize(false)
		end
	end)

	-- Row dividers, same behaviour as Form
	local function updateDividers()
		for index, entry in ipairs(entries) do
			local nextEntry = entries[index + 1]

			entry.divider.Visible = entry.row.Visible and nextEntry ~= nil and nextEntry.row.Visible == true
		end
	end

	structures.Content.ChildAdded:Connect(function(child)
		if child:IsA("Frame") and child:FindFirstChild("LayoutIgnore") then
			local divider = child.LayoutIgnore:FindFirstChild("Divider")

			if divider then
				table.insert(entries, { row = child, divider = divider })

				child:GetPropertyChangedSignal("Visible"):Connect(updateDividers)
				updateDividers()
			end
		end
	end)

	structures.Content.ChildRemoved:Connect(function(child)
		for index, entry in ipairs(entries) do
			if entry.row == child then
				table.remove(entries, index)
				break
			end
		end

		updateDividers()
	end)

	local object
	object = binder.Wrap(properties, {
		Title = function(value: string)
			structures.Title.Text = value
		end,
		Subtitle = function(value: string?)
			structures.Subtitle.Visible = value ~= nil and value ~= ""
			structures.Subtitle.Text = value or ""
		end,
		Icon = function(value: string?)
			structures.IconHolder.Visible = value ~= nil and icons.Apply(structures.Icon, value, nil, 16)
			layoutHeader()
		end,
		Collapsible = function(value: boolean)
			properties.Collapsible = value
			structures.Chevron.Visible = value
			structures.Header.Active = value
			layoutHeader()
		end,
		Expanded = function(value: boolean, tween: boolean?)
			properties.Expanded = value

			local useTween = tween ~= false

			structures.Divider.Visible = value
			resize(useTween)

			tweenService
				:Create(structures.Chevron, useTween and tweenInfo or TweenInfo.new(0), {
					Rotation = value and 0 or -90,
				})
				:Play()

			if properties.ExpandedChanged then
				task.spawn(properties.ExpandedChanged, object, value)
			end
		end,
		SearchIndex = function(value: string)
			structures.Body:SetAttribute("SearchIndex", value)
		end,
	}, structures.Body)

	structures.Header.MouseButton1Click:Connect(function()
		if not properties.Collapsible then
			return
		end

		object.Expanded = not properties.Expanded
	end)

	object.Type = "Groupbox"
	object.Theme = self.Theme
	object.Structures = structures
	object.__container = structures.Content
	object.__window = self.__window

	binder.Apply(properties, object)
	layoutHeader()
	task.defer(resize, false)

	return object
end
