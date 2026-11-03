--[[
	Builds an accent (same shape as the presets in accents.luau) from any colour, so the accent
	can come from a ColorPicker:

		app.Accent = cascade.CustomAccent(Color3.fromRGB(255, 120, 40))
]]

local function shade(color: Color3, valueScale: number, saturationScale: number?): Color3
	local h, s, v = color:ToHSV()

	return Color3.fromHSV(h, math.clamp(s * (saturationScale or 1), 0, 1), math.clamp(v * valueScale, 0, 1))
end

local function gradient(top: Color3, bottom: Color3): ColorSequence
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, top),
		ColorSequenceKeypoint.new(1, bottom),
	})
end

return function(color: Color3)
	local function variant()
		return {
			SwitchAccent = color,
			Selection = shade(color, 0.85, 1.05),
			SelectionFocused = shade(color, 0.93),
			Toggle = { SwitchOn = color },
			Button = { FillPrimary = gradient(shade(color, 1.08, 0.85), shade(color, 0.78, 1.1)) },
		}
	end

	return {
		-- unique per colour, so picking a new colour always counts as a change
		_id = "Custom#" .. color:ToHex(),
		Dark = variant(),
		Light = variant(),
	}
end
