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
