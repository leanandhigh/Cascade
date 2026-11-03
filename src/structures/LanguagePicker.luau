--[[
	Segmented language picker that lives next to the titlebar search field.

	[ EN | TH ]
]]

return function(self)
	--// Imports
	local creator = require("@modules/creator")

	--// References
	local create = creator.Create

	--// Variables
	local structures = {
		Segments = {},
	}
	local selected = nil
	local onSelected = nil

	--// UI
	structures.Body = create("Frame")({
		Name = "LanguagePicker",
		AutomaticSize = Enum.AutomaticSize.X,
		BorderSizePixel = 0,
		LayoutOrder = 1,
		Size = UDim2.fromOffset(0, 28),
		Visible = false,

		-- Same fill as the search field next to it, so the pill is visible as one control
		__dynamicKeys = {
			BackgroundColor3 = self.Theme.Controls.Card.Hover[1],
			BackgroundTransparency = self.Theme.Controls.Card.Hover[2],
		},

		create("UICorner")({
			CornerRadius = UDim.new(0, 7),
		}),

		create("UIStroke")({
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,

			__dynamicKeys = {
				Color = self.Theme.Controls.ViewBorder[1],
				Transparency = self.Theme.Controls.ViewBorder[2],
			},
		}),

		create("UIPadding")({
			PaddingBottom = UDim.new(0, 3),
			PaddingLeft = UDim.new(0, 3),
			PaddingRight = UDim.new(0, 3),
			PaddingTop = UDim.new(0, 3),
		}),

		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 2),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
	})

	--// Functions
	local function paint()
		for language, segment in pairs(structures.Segments) do
			local isSelected = language == selected

			segment.BackgroundColor3 = self.Theme.Controls.Selection[1].Value
			segment.BackgroundTransparency = isSelected and self.Theme.Controls.Selection[2].Value or 1
			segment.TextColor3 = isSelected and self.Theme.Text.SelectionPrimary[1].Value
				or self.Theme.Text.Secondary[1].Value
			segment.TextTransparency = isSelected and self.Theme.Text.SelectionPrimary[2].Value
				or self.Theme.Text.Secondary[2].Value
		end
	end

	-- Repaint when the theme / accent changes
	for _, state in
		{
			self.Theme.Controls.Selection[1],
			self.Theme.Controls.Selection[2],
			self.Theme.Text.Secondary[1],
			self.Theme.Text.SelectionPrimary[1],
		}
	do
		state:Connect(function()
			task.defer(paint)
		end)
	end

	structures.SetLanguages = function(languages: { string })
		for _, segment in pairs(structures.Segments) do
			segment:Destroy()
		end

		table.clear(structures.Segments)

		local segmentWidth = 32

		for _, language in ipairs(languages) do
			segmentWidth = math.max(segmentWidth, utf8.len(language) * 9 + 14)
		end

		for index, language in ipairs(languages) do
			local segment = create("TextButton")({
				Name = language,
				AutoButtonColor = false,
				BorderSizePixel = 0,
				FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
				LayoutOrder = index,
				-- Equal widths so the pill looks balanced whatever the codes are ("EN" vs "TH")
				Size = UDim2.fromOffset(segmentWidth, 22),
				Text = language,
				TextSize = 12,
				Parent = structures.Body.__instance,

				-- 7 (outer) - 3 (padding) = 4: corners stay concentric with the pill
				create("UICorner")({
					CornerRadius = UDim.new(0, 4),
				}),
			})

			segment.MouseButton1Click:Connect(function()
				if onSelected then
					onSelected(language)
				end
			end)

			structures.Segments[language] = segment
		end

		structures.Body.Visible = #languages > 0
		paint()
	end

	structures.Select = function(language: string?)
		selected = language
		paint()
	end

	structures.OnSelected = function(callback: (string) -> ())
		onSelected = callback
	end

	return structures
end
