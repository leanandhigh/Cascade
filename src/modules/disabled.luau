--[[
	Disabled look for any element (like Obsidian's Disabled = true): a cover in the groupbox
	colour, half see-through, laid over the element. It dims the element and swallows clicks,
	taps and drags, so nothing underneath can be changed.

	Every component gets this through the component wrapper:

		row:Right():Toggle({ Flag = "Farm", Disabled = true })
		element:SetDisabled(true)
		box:Row({ Title = "Speed", DependsOn = "AutoFarm" })   -- disabled while AutoFarm is off
		box:Row({ Title = "Speed", ShowIf = "AutoFarm" })      -- hidden while AutoFarm is off
]]

local Disabled = {}

local COVER_TRANSPARENCY = 0.4

local function coverOf(target: GuiObject): GuiObject?
	local holder = target:FindFirstChild("CascadeDisabled")

	return holder and holder:FindFirstChild("Cover") :: GuiObject?
end

function Disabled.Apply(target: GuiObject, theme, disabled: boolean)
	if typeof(target) ~= "Instance" or not target:IsA("GuiObject") then
		return
	end

	disabled = disabled == true
	target:SetAttribute("Disabled", disabled)

	local cover = coverOf(target)

	if not cover then
		if not disabled then
			return
		end

		-- In a Folder so list / grid layouts on the element don't move it
		local holder = Instance.new("Folder")
		holder.Name = "CascadeDisabled"

		local button = Instance.new("TextButton")
		button.Name = "Cover"
		button.Active = true
		button.AutoButtonColor = false
		button.BorderSizePixel = 0
		button.Selectable = false
		button.Size = UDim2.fromScale(1, 1)
		button.Text = ""
		button.ZIndex = target.ZIndex + 20

		local corner = target:FindFirstChildOfClass("UICorner")

		if corner then
			local round = Instance.new("UICorner")
			round.CornerRadius = corner.CornerRadius
			round.Parent = button
		end

		local function paint()
			local view = theme and theme.Controls and theme.Controls.View

			button.BackgroundColor3 = view and view[1].Value or Color3.fromRGB(31, 31, 33)
			button.BackgroundTransparency = COVER_TRANSPARENCY
		end

		paint()

		if theme and theme.Controls and theme.Controls.View then
			theme.Controls.View[1]:Connect(function()
				task.defer(paint)
			end)
		end

		button.Parent = holder
		holder.Parent = target
		cover = button
	end

	cover.Visible = disabled
end

function Disabled.IsDisabled(target: GuiObject): boolean
	return typeof(target) == "Instance" and target:GetAttribute("Disabled") == true
end

-- Reads a "depends on" spec: "Flag" (on while truthy) or { Flag = "Mode", Value = 2 }
function Disabled.Condition(spec, value): boolean
	if typeof(spec) == "table" and spec.Value ~= nil then
		return value == spec.Value
	end

	return value == true or (value ~= nil and value ~= false and value ~= 0)
end

function Disabled.FlagOf(spec): string?
	if typeof(spec) == "table" then
		return spec.Flag and tostring(spec.Flag) or nil
	end

	return spec ~= nil and tostring(spec) or nil
end

return Disabled
