--// Types
type ExpectedObject = ((...any) -> ...any) | Instance | ServiceProvider

--// Variables
local utility = {}

--// Initialize
utility.Clone = function(object: any)
	local clonedObject: any

	if type(object) == "function" then
		clonedObject = clonefunction and clonefunction(object)
	elseif typeof(object) == "Instance" then
		clonedObject = cloneref and cloneref(object)
	end

	return clonedObject or object
end

utility.ProtectUI = function(gui: Instance): ScreenGui | string
	local sHiddenUi, hiddenUi = pcall(function()
		return gethui()
	end)

	local sCoreGui, coreGui = pcall(function()
		local layer = utility.Clone(game:GetService("CoreGui"))

		if layer and layer.ClassName then
			return layer
		end

		return
	end)

	local success, returned = pcall(function()
		gui.Parent = sHiddenUi and hiddenUi
			or sCoreGui and coreGui
			or utility.Clone(game:GetService("Players")).LocalPlayer.PlayerGui
	end)

	return success and gui or returned
end

-- Combined UIScale applied to `instance` (product of every UIScale on it and its ancestors).
-- AbsoluteSize / AbsolutePosition are in screen pixels, Size / Position offsets are not: divide
-- measured sizes by this before writing them back as offsets (mobile draws the window at 0.8).
-- Returns 0 while a scale is tweening to 0 (window minimizing) — callers should skip then.
utility.GetScale = function(instance: Instance?): number
	local scale = 1
	local current = instance

	while current do
		local uiScale = current:FindFirstChildOfClass("UIScale")

		if uiScale then
			scale *= uiScale.Scale
		end

		current = current.Parent
	end

	return scale
end

-- Sizes a pill-shaped TextLabel to its text using the real font metrics (GetTextBoundsAsync waits
-- for the font to load). AutomaticSize measures before custom fonts finish loading, which left
-- pills like "Added" / "Changed" too tight or off-centre. Re-measures when the text changes.
utility.FitText = function(label: TextLabel, paddingX: number, height: number?)
	local ok, service = pcall(function()
		return game:GetService("TextService")
	end)

	if not ok or not service then
		return -- keeps AutomaticSize
	end

	local textService = utility.Clone(service)
	local token = 0

	local function measure()
		token += 1

		local current = token

		task.spawn(function()
			local ok, bounds = pcall(function()
				local params = Instance.new("GetTextBoundsParams")
				params.Text = label.ContentText ~= "" and label.ContentText or label.Text
				params.Font = label.FontFace
				params.Size = label.TextSize
				params.Width = 100000

				return textService:GetTextBoundsAsync(params)
			end)

			if current ~= token or not ok or typeof(bounds) ~= "Vector2" then
				return
			end

			local padding = label:FindFirstChildOfClass("UIPadding")

			if padding then
				padding:Destroy()
			end

			label.AutomaticSize = Enum.AutomaticSize.None
			label.TextXAlignment = Enum.TextXAlignment.Center
			label.TextYAlignment = Enum.TextYAlignment.Center
			label.Size = UDim2.fromOffset(math.ceil(bounds.X) + paddingX * 2, height or label.Size.Y.Offset)
		end)
	end

	label:GetPropertyChangedSignal("Text"):Connect(measure)
	measure()
end

-- Phone / tablet check (same idea as Obsidian): Android / iOS platform, or touch without a mouse.
utility.IsMobile = function(): boolean
	local userInputService = utility.Clone(game:GetService("UserInputService"))

	local ok, platform = pcall(function()
		return userInputService:GetPlatform()
	end)

	if ok and (platform == Enum.Platform.Android or platform == Enum.Platform.IOS) then
		return true
	end

	return userInputService.TouchEnabled == true and userInputService.MouseEnabled ~= true
end

-- Finds the ScreenGui an overlay (watermark, keybind list...) should live in, from any component context.
utility.OverlayRoot = function(context: any): Instance?
	local candidate = context and (context.__container or context.__instance) or nil

	if typeof(candidate) == "table" then
		local ok, instance = pcall(function()
			return candidate.__instance
		end)

		candidate = ok and instance or nil
	end

	if typeof(candidate) ~= "Instance" then
		return nil
	end

	if candidate:IsA("LayerCollector") then
		return candidate
	end

	return candidate:FindFirstAncestorWhichIsA("LayerCollector") or candidate
end

return utility
