--[[
	Lightweight popover menu with checkable items.

	Used by the Window's profile settings button, but generic enough to be
	reused by any component that needs a small floating menu.

	local menu = popover.new(self)
	local item = menu:AddItem({ Title = "Censor Name", Checked = false, Changed = function(value) end })
	menu:Toggle(anchorGuiObject)
]]

--// Imports
local creator = require("@modules/creator")
local services = require("@modules/services")
local utility = require("@modules/utility")
local symbols = require("@modules/symbols")
local icons = require("@modules/icons")

--// References
local create = creator.Create

local tweenService = services.TweenService
local userInputService = services.UserInputService
local workspace = services.Workspace

--// Constants
local EDGE_BUFFER = 6
local GAP = 6
local TWEEN_INFO = TweenInfo.new(0.18, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

--// Types
export type PopoverItemProperties = {
	Title: string,
	Icon: string?,
	IconFallback: string?,
	Checked: boolean?,
	Checkable: boolean?,
	Destructive: boolean?,
	Changed: ((value: boolean) -> ())?,
	Pushed: (() -> ())?,
}

--// Variables
local Popover = {}
Popover.__index = Popover

--// Private Methods
local function unwrap(object)
	if typeof(object) == "table" then
		local ok, instance = pcall(function()
			return object.__instance
		end)

		if ok and typeof(instance) == "Instance" then
			return instance
		end
	end

	return object
end

local function pointInside(guiObject: GuiObject?, x: number, y: number): boolean
	if not guiObject then
		return false
	end

	local position = guiObject.AbsolutePosition
	local size = guiObject.AbsoluteSize

	return x >= position.X and x <= position.X + size.X and y >= position.Y and y <= position.Y + size.Y
end

--// Public Methods
function Popover.new(context, config: { Name: string?, Width: number? }?)
	config = config or {}

	local theme = context.Theme
	local self = setmetatable({
		Context = context,
		Items = {},
		Open = false,
		Anchor = nil,
		Token = 0,
	}, Popover)

	self.Container = create("ScreenGui")({
		Name = config.Name or "Popover",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ScreenInsets = Enum.ScreenInsets.None,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 202,
		OnTopOfCoreBlur = true,
		Enabled = false,
	})

	self.Group = create("CanvasGroup")({
		Name = "Menu",
		AutomaticSize = Enum.AutomaticSize.XY,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		Size = UDim2.fromOffset(config.Width or 170, 0),
		Parent = self.Container.__instance,

		__dynamicKeys = {
			BackgroundColor3 = theme.Controls.MenuButton.MenuBackground[1],
			BackgroundTransparency = theme.Controls.MenuButton.MenuBackground[2],
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
			PaddingBottom = UDim.new(0, 5),
			PaddingLeft = UDim.new(0, 5),
			PaddingRight = UDim.new(0, 5),
			PaddingTop = UDim.new(0, 5),
		}),

		create("UIListLayout")({
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 1),
		}),
	})

	utility.ProtectUI(self.Container.__instance)

	userInputService.InputBegan:Connect(function(input)
		if not self.Open then
			return
		end

		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		local x, y = input.Position.X, input.Position.Y

		if pointInside(self.Group.__instance, x, y) or pointInside(unwrap(self.Anchor), x, y) then
			return
		end

		self:Close()
	end)

	return self
end

function Popover:AddItem(properties: PopoverItemProperties)
	local theme = self.Context.Theme
	local item = {
		Title = properties.Title,
		Checked = properties.Checked == true,
		Checkable = properties.Checkable ~= false and properties.Pushed == nil,
	}

	local function textColor()
		return properties.Destructive and theme.Accents.Red or theme.Text.Primary
	end

	local button = create("TextButton")({
		Name = "Item",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = #self.Items + 1,
		Size = UDim2.new(1, 0, 0, 24),
		Text = "",
		Parent = self.Group.__instance,

		__dynamicKeys = {
			BackgroundColor3 = theme.Controls.SelectionFocused[1],
		},

		create("UICorner")({
			CornerRadius = UDim.new(0, 5),
		}),

		create("UIPadding")({
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 10),
		}),

		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),

		create("ImageLabel")({
			ScaleType = Enum.ScaleType.Fit,
			Name = "Check",
			BackgroundTransparency = 1,
			Image = symbols.checkmark,
			Size = UDim2.fromOffset(12, 12),
			Visible = item.Checkable,
			ImageTransparency = item.Checked and 0 or 1,

			__dynamicKeys = {
				ImageColor3 = theme.Text.Primary[1],
			},
		}),

		create("ImageLabel")({
			ScaleType = Enum.ScaleType.Fit,
			Name = "Icon",
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			Size = UDim2.fromOffset(14, 14),
			Visible = properties.Icon ~= nil,
			Image = properties.Icon or "",

			__dynamicKeys = {
				ImageColor3 = textColor()[1],
				ImageTransparency = textColor()[2],
			},
		}),

		create("TextLabel")({
			Name = "Title",
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			FontFace = Font.new("rbxassetid://12187365364"),
			LayoutOrder = 2,
			Size = UDim2.fromOffset(0, 16),
			Text = properties.Title,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,

			__dynamicKeys = {
				TextColor3 = textColor()[1],
				TextTransparency = textColor()[2],
			},
		}),
	})

	local check = button:FindFirstChild("Check") :: ImageLabel
	local title = button:FindFirstChild("Title") :: TextLabel
	local icon = button:FindFirstChild("Icon") :: ImageLabel

	icons.Apply(check, "check", symbols.checkmark, 12)

	if properties.Icon then
		icon.Visible = icons.Apply(icon, properties.Icon, properties.IconFallback, 13)
	end

	item.Button = button
	item.Set = function(_, value: boolean, silent: boolean?)
		item.Checked = value == true
		check.ImageTransparency = item.Checked and 0 or 1

		if not silent and properties.Changed then
			task.spawn(properties.Changed, item.Checked)
		end
	end

	local function setHover(hovered: boolean)
		local color = textColor()

		button.BackgroundTransparency = hovered and theme.Controls.SelectionFocused[2].Value or 1
		title.TextColor3 = hovered and theme.Text.SelectionPrimary[1].Value or color[1].Value
		title.TextTransparency = hovered and theme.Text.SelectionPrimary[2].Value or color[2].Value
		icon.ImageColor3 = title.TextColor3
		icon.ImageTransparency = title.TextTransparency
		check.ImageColor3 = hovered and theme.Text.SelectionPrimary[1].Value or theme.Text.Primary[1].Value
	end

	button.MouseEnter:Connect(function()
		setHover(true)
	end)
	button.MouseLeave:Connect(function()
		setHover(false)
	end)

	button.MouseButton1Click:Connect(function()
		if item.Checkable then
			item:Set(not item.Checked)
		end

		if properties.Pushed then
			task.spawn(properties.Pushed)
		end

		setHover(false)
		self:Close()
	end)

	table.insert(self.Items, item)

	return item
end

function Popover:AddSeparator()
	local theme = self.Context.Theme

	create("Frame")({
		Name = "Separator",
		BackgroundTransparency = 1,
		LayoutOrder = #self.Items + 1,
		Size = UDim2.new(1, 0, 0, 9),
		Parent = self.Group.__instance,

		create("Frame")({
			AnchorPoint = Vector2.new(0.5, 0.5),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, -12, 0, 1),

			__dynamicKeys = {
				BackgroundColor3 = theme.Controls.ViewBorder[1],
				BackgroundTransparency = theme.Controls.ViewBorder[2],
			},
		}),
	})

	table.insert(self.Items, false)
end

function Popover:Clear()
	for _, child in ipairs(self.Group.__instance:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	table.clear(self.Items)
end

function Popover:Position()
	local anchor = unwrap(self.Anchor)

	if not anchor then
		return
	end

	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
	local menuSize = self.Group.AbsoluteSize

	local x = anchor.AbsolutePosition.X
	local y = anchor.AbsolutePosition.Y + anchor.AbsoluteSize.Y + GAP

	-- Flip above the anchor when there isn't enough room below (eg. profile at the bottom of the sidebar).
	if y + menuSize.Y > viewport.Y - EDGE_BUFFER then
		y = anchor.AbsolutePosition.Y - menuSize.Y - GAP
	end

	x = math.clamp(x, EDGE_BUFFER, math.max(EDGE_BUFFER, viewport.X - menuSize.X - EDGE_BUFFER))
	y = math.clamp(y, EDGE_BUFFER, math.max(EDGE_BUFFER, viewport.Y - menuSize.Y - EDGE_BUFFER))

	self.Group.Position = UDim2.fromOffset(x, y)
end

function Popover:Show(anchor)
	self.Anchor = anchor or self.Anchor
	self.Open = true
	self.Token += 1
	self.Container.Enabled = true

	self:Position()
	task.defer(function()
		self:Position()
	end)

	tweenService:Create(self.Group.__instance, TWEEN_INFO, { GroupTransparency = 0 }):Play()
end

function Popover:Close()
	if not self.Open then
		return
	end

	self.Open = false
	self.Token += 1

	local token = self.Token
	local tween = tweenService:Create(self.Group.__instance, TWEEN_INFO, { GroupTransparency = 1 })

	tween.Completed:Connect(function()
		if token == self.Token then
			self.Container.Enabled = false
		end
	end)
	tween:Play()
end

function Popover:Toggle(anchor)
	if self.Open then
		self:Close()
	else
		self:Show(anchor)
	end
end

function Popover:Destroy()
	self.Container:Destroy()
end

return Popover
