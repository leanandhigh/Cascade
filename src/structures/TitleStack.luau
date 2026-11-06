return function(self)
	--// Imports
	local creator = require("@modules/creator")

	--// References
	local create = creator.Create

	--// Variables
	local structures = {}

	--// UI
	structures.Body = create("Frame")({
		Name = "TitleStack",
		-- Like Obsidian: one line each, cut with "…" when too long (rows keep their height and
		-- nothing below moves down). Wrap = true makes them wrap instead.
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 0),

		create("UIListLayout")({
			Name = "UIListLayout",
			Padding = UDim.new(0, 2),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),

		create("UIPadding")({
			Name = "UIPadding",
		}),

		create("TextLabel")({
			Name = "Subtitle",
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			FontFace = Font.new(require("@modules/fonts").Family),
			LayoutOrder = 1,
			RichText = true,
			Size = UDim2.new(1, 0, 0, 15),
			Text = "Subtitle",
			TextSize = 13,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextWrapped = false,
			TextXAlignment = Enum.TextXAlignment.Left,
			Visible = false,

			__dynamicKeys = {
				TextColor3 = self.Theme.Text.Secondary[1],
				TextTransparency = self.Theme.Text.Secondary[2],
			},
		}),

		create("TextLabel")({
			Name = "Title",
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			FontFace = Font.new(require("@modules/fonts").Family),
			RichText = true,
			Size = UDim2.new(1, 0, 0, 18),
			Text = "Title",
			TextColor3 = Color3.fromRGB(0, 0, 0),
			TextSize = 15,
			TextTransparency = 0.15,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextWrapped = false,
			TextXAlignment = Enum.TextXAlignment.Left,

			__dynamicKeys = {
				TextColor3 = self.Theme.Text.Primary[1],
				TextTransparency = self.Theme.Text.Primary[2],
			},
		}),
	}) :: Frame

	--// Initialize
	structures.Title = structures.Body:FindFirstChild("Title") :: TextLabel
	structures.Subtitle = structures.Body:FindFirstChild("Subtitle") :: TextLabel
	structures.Padding = structures.Body:FindFirstChild("UIPadding") :: UIPadding

	-- Wrap = true: long titles / subtitles take more lines instead of being cut
	structures.SetWrap = function(wrap: boolean)
		for _, label in ipairs({ structures.Title, structures.Subtitle }) do
			label.TextWrapped = wrap
			label.TextTruncate = wrap and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd
			label.AutomaticSize = wrap and Enum.AutomaticSize.Y or Enum.AutomaticSize.None
		end
	end

	return structures
end
